# Email Authentication & Password Reset Setup Guide

## Overview
This guide covers the complete implementation of email verification and password reset functionality in the LearnED Flutter app using Supabase.

## Features Implemented

### 1. Sign Up with Email Verification
- Users receive a verification email after registration
- Email contains a clickable link to verify their account
- Users can resend verification email if needed
- Account activation happens automatically upon clicking the verification link

### 2. Forgot Password Flow
- Users can request a password reset from the login screen
- Password reset email is sent with a secure reset link
- Reset link opens the app directly to the password reset screen
- New password is set and user is prompted to login

### 3. Password Reset
- Secure token-based password reset
- Password validation (minimum 8 characters)
- Confirmation password matching
- Auto sign-out after password change for security

## Code Changes Summary

### 1. Auth Service (`auth_service.dart`)
**Added Methods:**
- `resendEmailVerification(String email)` - Resends verification email
- `updatePassword(String newPassword)` - Updates user password after reset

**Updated Methods:**
- `signUp()` - Now includes `emailRedirectTo` parameter for email verification
- `resetPassword()` - Now includes `redirectTo` parameter for deep linking

### 2. Email Verification Screen (`email_verification_screen.dart`)
- Implemented real Supabase email resend functionality
- Added proper error handling
- Shows user-friendly messages for success/failure
- Includes cooldown state after resending

### 3. Forgot Password Screen (`forgot_password_screen.dart`)
- Implemented Supabase password reset email sending
- Added rate limiting error handling
- Improved user feedback with detailed messages
- Auto-navigation after successful submission

### 4. Reset Password Screen (`reset_password_screen.dart`)
- Implemented actual password update via Supabase
- Added session expiry detection
- Auto sign-out after password change
- Enhanced error messages for better UX

### 5. Login Screen (`login_screen.dart`)
- Updated "Forgot Password" link to navigate to dedicated screen
- Removed inline password reset functionality

### 6. Deep Link Configuration (`AndroidManifest.xml`)
- Added intent filter for `learnedapp://reset-password` scheme
- Configured for password reset deep linking

### 7. Main App (`main.dart`)
- Added auth state change listener
- Automatic navigation to reset password screen when recovery link is clicked
- Handles `AuthChangeEvent.passwordRecovery` event

## Supabase Configuration Required

### 1. Email Templates Configuration

Go to your Supabase Dashboard → Authentication → Email Templates

#### Confirm Signup Template
```html
<h2>Confirm your signup</h2>

<p>Follow this link to confirm your email address:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm your email</a></p>
```

**Variables:**
- `{{ .ConfirmationURL }}` - Auto-generated confirmation link
- `{{ .Token }}` - Verification token
- `{{ .Email }}` - User's email address

#### Reset Password Template
```html
<h2>Reset Password</h2>

<p>Follow this link to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>

<p>If you didn't request this, you can safely ignore this email.</p>
```

**Variables:**
- `{{ .ConfirmationURL }}` - Auto-generated password reset link
- `{{ .Token }}` - Reset token
- `{{ .Email }}` - User's email address

### 2. Email Provider Settings

**SMTP Configuration** (Recommended for production):
- Go to Authentication → Settings → SMTP Settings
- Configure your SMTP provider (SendGrid, Mailgun, AWS SES, etc.)
- Test email sending

**Development:**
- Supabase provides built-in email for development
- Limited to 4 emails per hour
- Sufficient for testing

### 3. URL Configuration

**Site URL:**
- Set to your app's deep link scheme: `learnedapp://`

**Redirect URLs:**
- Add: `learnedapp://reset-password`
- Add: `https://ugphaeiqbfejnzpiqdty.supabase.co/auth/v1/verify`

**Email Redirect URLs:**
- Confirm signup: `https://ugphaeiqbfejnzpiqdty.supabase.co/auth/v1/verify`
- Reset password: `learnedapp://reset-password`

### 4. Email Auth Settings

Enable the following in Authentication → Settings:
- ✅ Enable email signup
- ✅ Enable email confirmations
- ✅ Confirm email (required for signup)
- ✅ Secure email change (requires re-authentication)

## Testing Instructions

### Testing Email Verification

1. **Register a new account:**
   - Open the app
   - Tap "Sign Up"
   - Fill in the registration form
   - Submit

2. **Check email:**
   - Open your email inbox
   - Look for "Confirm your signup" email from Supabase
   - Click the verification link

3. **Verify in app:**
   - User should be able to login after verification
   - Unverified users cannot login

4. **Test resend:**
   - On verification screen, tap "Resend Verification Email"
   - Check inbox for new email

### Testing Password Reset

1. **Request password reset:**
   - Open the app
   - Tap "Login"
   - Tap "Forgot Password?"
   - Enter your email
   - Submit

2. **Check email:**
   - Open your email inbox
   - Look for "Reset Password" email from Supabase
   - Click the reset link

3. **Reset password:**
   - App should open to reset password screen
   - Enter new password
   - Confirm password
   - Submit

4. **Verify reset:**
   - Should be signed out automatically
   - Login with new password
   - Old password should not work

### Testing Deep Links (Android)

**Via ADB:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "learnedapp://reset-password"
```

**Via Terminal:**
```bash
flutter run
# In another terminal:
adb shell am start -W -a android.intent.action.VIEW -d "learnedapp://reset-password"
```

## User Flow Diagrams

### Sign Up Flow
```
User fills form → Submit → Supabase creates account
                           ↓
              Send verification email
                           ↓
          Show verification screen
                           ↓
      User clicks link in email
                           ↓
         Email verified in Supabase
                           ↓
           User can now login
```

### Password Reset Flow
```
User taps "Forgot Password" → Enter email → Submit
                                             ↓
                            Supabase sends reset email
                                             ↓
                          User clicks link in email
                                             ↓
                      App opens to reset screen
                                             ↓
                     User enters new password
                                             ↓
                     Password updated in Supabase
                                             ↓
                        User signed out
                                             ↓
                     User logs in with new password
```

## Common Issues & Solutions

### Issue: Emails not being sent

**Solution:**
- Check Supabase email quota (4/hour for dev)
- Verify SMTP configuration if using custom provider
- Check spam folder
- Verify email templates are configured

### Issue: Deep links not working

**Solution:**
- Verify AndroidManifest.xml has correct intent filter
- Test with ADB command
- Check redirect URL in Supabase dashboard
- Rebuild and reinstall the app

### Issue: "Session expired" error on password reset

**Solution:**
- Reset links expire after 1 hour
- Request a new password reset email
- Use the link immediately after receiving

### Issue: Email verification link not working

**Solution:**
- Check Site URL in Supabase settings
- Verify redirect URLs are configured
- Ensure app is installed on the device
- Check that email confirmation is enabled

## Security Considerations

1. **Rate Limiting:**
   - Supabase automatically rate limits email sending
   - Password reset requests are limited to prevent abuse

2. **Token Expiry:**
   - Email verification tokens expire after 24 hours
   - Password reset tokens expire after 1 hour

3. **Auto Sign-Out:**
   - Users are signed out after password change
   - Forces re-authentication with new password

4. **Email Validation:**
   - Emails must be verified before account is fully active
   - Prevents fake account creation

## Production Checklist

- [ ] Configure custom SMTP provider (SendGrid, Mailgun, etc.)
- [ ] Customize email templates with branding
- [ ] Set production redirect URLs
- [ ] Test all email flows in staging
- [ ] Configure rate limiting rules
- [ ] Set up email monitoring/logging
- [ ] Test deep links on multiple devices
- [ ] Add analytics for auth events
- [ ] Configure custom domain for emails
- [ ] Set up email deliverability monitoring

## Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Email Templates Guide](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Deep Linking in Flutter](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [Go Router Documentation](https://pub.dev/packages/go_router)

## Support

For issues or questions:
1. Check Supabase logs in dashboard
2. Review Flutter console output
3. Test with ADB commands
4. Check email provider logs

## Version History

- **v1.0** - Initial implementation
  - Email verification on signup
  - Password reset flow
  - Deep link handling
  - Email templates configuration
