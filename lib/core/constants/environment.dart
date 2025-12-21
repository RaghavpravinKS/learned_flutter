class Environment {
  // Compile-time environment variables - MUST be provided via --dart-define
  static const String _envSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Get the URL from environment (required)
  static String get supabaseUrl {
    if (_envSupabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL must be provided via --dart-define=SUPABASE_URL=your_url');
    }
    return _envSupabaseUrl;
  }

  // Get the anon key from environment (required)
  static String get supabaseAnonKey {
    if (_envSupabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY must be provided via --dart-define=SUPABASE_ANON_KEY=your_key');
    }
    return _envSupabaseAnonKey;
  }

  // Add other environment-specific configurations here
  static const String appName = 'LearnED';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseApiUrl = 'YOUR_API_BASE_URL';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
}
