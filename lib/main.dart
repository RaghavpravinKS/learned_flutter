import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/environment.dart';
import 'features/auth/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

// Provider for Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) {
    return event.session?.user;
  });
});

void main() async {
  // Debug print environment variables
  print('Supabase URL from env: ${Environment.supabaseUrl}');
  print(
    'Supabase Anon Key from env: ${Environment.supabaseAnonKey.isNotEmpty ? '***${Environment.supabaseAnonKey.substring(Environment.supabaseAnonKey.length - 4)}' : 'NOT SET'}',
  );

  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );

    print('Supabase initialized successfully');

    runApp(const ProviderScope(child: LearnEDApp()));
  } catch (e) {
    print('Error initializing Supabase: $e');
    rethrow;
  }
}

class LearnEDApp extends ConsumerWidget {
  const LearnEDApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to trigger rebuilds on auth changes
    ref.watch(authStateProvider);

    return MaterialApp.router(
      title: Environment.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      // Error handling
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside of text fields
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
              currentFocus.focusedChild?.unfocus();
            }
          },
          child: child!,
        );
      },
    );
  }
}
