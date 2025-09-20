@echo off
echo Building LearnED Flutter Debug APK...
echo.

REM Build the debug APK with environment variables
fvm flutter build apk --debug ^
  --dart-define=SUPABASE_URL=https://ugphaeiqbfejnzpiqdty.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVncGhhZWlxYmZlam56cGlxZHR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMTMwNDcsImV4cCI6MjA2OTc4OTA0N30.-OcW0or7v6krUQJUG0Jb8VoPbpbGjbdbjsMKn6KplM8

echo.
echo Debug build completed! APK location:
echo build\app\outputs\flutter-apk\app-debug.apk
echo.
pause