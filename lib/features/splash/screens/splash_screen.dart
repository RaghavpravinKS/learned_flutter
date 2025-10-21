import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/debug/helpers/user_type_fix_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = 'Loading...';

  @override
  void initState() {
    super.initState();
    // Check authentication state and navigate accordingly
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Update status
    setState(() {
      _statusText = 'Checking authentication...';
    });

    // Wait for 2 seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is already authenticated
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;

    // Debug print to see authentication state
    print('🔍 Splash: Checking authentication...');
    print('🔍 Splash: User exists: ${user != null}');
    print('🔍 Splash: Session exists: ${session != null}');
    print('🔍 Splash: User ID: ${user?.id}');
    print('🔍 Splash: Session expires at: ${session?.expiresAt}');

    if (user != null && session != null) {
      // In debug mode, print current user info and try to fix user type
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        await UserTypeFixHelper.printCurrentUserInfo();
        await UserTypeFixHelper.fixCurrentUserType();
      }

      // User is authenticated, determine user type
      String userType = await _determineUserType(user);

      print('🔍 Splash: User authenticated as $userType, navigating to dashboard');
      setState(() {
        _statusText = 'Welcome back!';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        if (userType == 'teacher') {
          context.go('/teacher');
        } else {
          context.go('/student');
        }
      }
    } else {
      // User not authenticated, go to welcome screen
      print('🔍 Splash: User not authenticated, navigating to welcome');
      setState(() {
        _statusText = 'Welcome to LearnED';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.go('/welcome');
    }
  }

  Future<String> _determineUserType(User user) async {
    // First, check user metadata
    final metadataUserType = user.userMetadata?['user_type'];
    if (metadataUserType != null) {
      print('🔍 Splash: Found user_type in metadata: $metadataUserType');
      return metadataUserType;
    }

    print('🔍 Splash: No user_type in metadata, checking database...');

    // Fallback: Check database tables to determine user type
    try {
      // Check if user exists in teachers table
      final teacherResponse = await Supabase.instance.client
          .from('teachers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (teacherResponse != null) {
        print('🔍 Splash: Found user in teachers table');
        return 'teacher';
      }

      // Check if user exists in students table
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentResponse != null) {
        print('🔍 Splash: Found user in students table');
        return 'student';
      }

      print('🔍 Splash: User not found in any specific table, defaulting to student');
      return 'student';
    } catch (e) {
      print('🔍 Splash: Error checking database for user type: $e');
      return 'student'; // Default to student on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon would go here
            const Icon(Icons.school_outlined, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            // App name
            Text(
              'LearnED',
              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text('Empowering Education', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 32),
            // Status text
            Text(_statusText, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60)),
            const SizedBox(height: 16),
            // Loading indicator
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ],
        ),
      ),
    );
  }
}
