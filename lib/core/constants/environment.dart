class Environment {
  // Development defaults - these will be overridden by --dart-define values
  static const String _defaultSupabaseUrl = 'https://ugphaeiqbfejnzpiqdty.supabase.co';
  static const String _defaultSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVncGhhZWlxYmZlam56cGlxZHR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMTMwNDcsImV4cCI6MjA2OTc4OTA0N30.-OcW0or7v6krUQJUG0Jb8VoPbpbGjbdbjsMKn6KplM8';
  
  // Get the URL from environment or use default
  static String get supabaseUrl {
    final url = const String.fromEnvironment('SUPABASE_URL');
    print('Supabase URL: ${url.isEmpty ? 'Using default' : 'From env'}');
    return url.isEmpty ? _defaultSupabaseUrl : url;
  }
  
  // Get the anon key from environment or use default
  static String get supabaseAnonKey {
    final key = const String.fromEnvironment('SUPABASE_ANON_KEY');
    print('Supabase Key: ${key.isEmpty ? 'Using default' : 'Key present'}');
    return key.isEmpty ? _defaultSupabaseAnonKey : key;
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
