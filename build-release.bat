@echo off
echo Building LearnED Flutter Release APK...
echo.
echo Included features:
echo - Environment variables (SUPABASE_URL, SUPABASE_ANON_KEY)
echo - Internet permissions for API calls
echo - Optimized release build
echo.

REM Clean the project first (optional)
REM fvm flutter clean

REM Build the release APK with environment variables
fvm flutter build apk --release ^
  --dart-define=SUPABASE_URL=https://ugphaeiqbfejnzpiqdty.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVncGhhZWlxYmZlam56cGlxZHR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMTMwNDcsImV4cCI6MjA2OTc4OTA0N30.-OcW0or7v6krUQJUG0Jb8VoPbpbGjbdbjsMKn6KplM8

echo.
echo Build completed! APK location:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo APK is ready for distribution with:
echo - Supabase API configuration
echo - Internet access permissions
echo - Release optimizations
echo.
pause