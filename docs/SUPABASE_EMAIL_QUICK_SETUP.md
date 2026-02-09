# Supabase Email Configuration - Quick Setup

## Step 1: Access Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project: **learned**
3. Navigate to **Authentication** in the left sidebar

## Step 2: Configure Email Templates

### Navigate to Email Templates
1. Click **Authentication** → **Email Templates**

### Configure "Confirm Signup" Template
1. Select **"Confirm signup"** from the dropdown
2. Update the template:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .button { display: inline-block; background: #667eea; color: white; padding: 14px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Welcome to LearnED! 🎓</h1>
    </div>
    <div class="content">
        <h2>Confirm Your Email Address</h2>
        <p>Thank you for signing up! We're excited to have you join our learning community.</p>
        <p>Please click the button below to verify your email address and activate your account:</p>
        <center>
            <a href="{{ .ConfirmationURL }}" class="button">Verify Email Address</a>
        </center>
        <p>Or copy and paste this link into your browser:</p>
        <p style="background: #fff; padding: 10px; border: 1px solid #ddd; word-break: break-all;">{{ .ConfirmationURL }}</p>
        <p><strong>Note:</strong> This link will expire in 24 hours.</p>
    </div>
    <div class="footer">
        <p>If you didn't create this account, you can safely ignore this email.</p>
        <p>© 2026 LearnED. All rights reserved.</p>
    </div>
</body>
</html>
```

### Configure "Reset Password" Template
1. Select **"Reset password"** from the dropdown
2. Update the template:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .button { display: inline-block; background: #f5576c; color: white; padding: 14px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Reset Your Password 🔐</h1>
    </div>
    <div class="content">
        <h2>Password Reset Request</h2>
        <p>We received a request to reset the password for your LearnED account.</p>
        <p>Click the button below to reset your password:</p>
        <center>
            <a href="{{ .ConfirmationURL }}" class="button">Reset Password</a>
        </center>
        <p>Or copy and paste this link into your browser:</p>
        <p style="background: #fff; padding: 10px; border: 1px solid #ddd; word-break: break-all;">{{ .ConfirmationURL }}</p>
        <div class="warning">
            <strong>⚠️ Important:</strong> This link will expire in 1 hour for security reasons.
        </div>
        <p><strong>Didn't request this?</strong> You can safely ignore this email. Your password won't be changed.</p>
    </div>
    <div class="footer">
        <p>For security, never share this link with anyone.</p>
        <p>© 2026 LearnED. All rights reserved.</p>
    </div>
</body>
</html>
```

## Step 3: Configure URL Configuration

### Navigate to URL Configuration
1. Click **Authentication** → **URL Configuration**

### Update Settings:
```
Site URL: https://ugphaeiqbfejnzpiqdty.supabase.co

Redirect URLs (Add these):
- learnedapp://reset-password
- https://ugphaeiqbfejnzpiqdty.supabase.co/auth/v1/verify
- learnedapp://auth-callback
```

## Step 4: Configure Auth Settings

### Navigate to Auth Settings
1. Click **Authentication** → **Settings**

### Email Auth Settings:
- ✅ **Enable email provider**
- ✅ **Confirm email** (REQUIRED for new signups)
- ✅ **Secure email change** (require re-authentication)
- ⚙️ **Double confirm email changes** (optional, recommended)

### Email Template Settings:
- **Confirmation Email Subject:** "Confirm your LearnED account"
- **Password Recovery Subject:** "Reset your LearnED password"

## Step 5: SMTP Configuration (Production Only)

### For Development:
- Use default Supabase SMTP
- Limit: 4 emails per hour
- Sufficient for testing

### For Production:
1. Click **Authentication** → **Settings** → **SMTP Settings**
2. Choose provider (SendGrid, Mailgun, AWS SES, etc.)
3. Configure credentials:
   - **Host:** smtp.sendgrid.net (or your provider)
   - **Port:** 587
   - **Username:** apikey (SendGrid) or your username
   - **Password:** Your API key
   - **Sender Email:** noreply@yourapp.com
   - **Sender Name:** LearnED

### Recommended Production Providers:

**SendGrid (Easiest):**
- 100 emails/day free
- Good deliverability
- Easy setup

**Mailgun:**
- 5,000 emails/month free
- Excellent for transactional emails

**AWS SES:**
- Very cheap ($0.10 per 1,000 emails)
- Requires domain verification

## Step 6: Security Settings

### Rate Limiting:
1. Navigate to **Authentication** → **Rate Limits**
2. Recommended settings:
   - **Email signups:** 4 per hour per IP
   - **Email verifications:** 2 per hour per email
   - **Password resets:** 2 per hour per email

### Token Expiry:
- **Email verification:** 24 hours (default)
- **Password reset:** 1 hour (default)
- **Refresh token:** 30 days (default)

## Step 7: Test Configuration

### Test Email Verification:
```bash
# From Flutter app
flutter run
# Register a new account
# Check your email
```

### Test Password Reset:
```bash
# From Flutter app
flutter run
# Click "Forgot Password"
# Enter email
# Check your email
```

### Test Deep Links (Android):
```bash
# Test reset password deep link
adb shell am start -W -a android.intent.action.VIEW -d "learnedapp://reset-password"
```

## Step 8: Monitor Email Delivery

### Check Email Logs:
1. Go to **Authentication** → **Logs**
2. Filter by event type:
   - `signup_confirmation`
   - `password_recovery`

### Check for Issues:
- ✅ Email sent successfully
- ❌ Email bounced (invalid address)
- ❌ Rate limited
- ❌ SMTP error

## Troubleshooting

### Emails Not Arriving:
1. Check spam folder
2. Verify email provider configuration
3. Check Supabase logs for errors
4. Verify redirect URLs
5. Test with different email provider

### Deep Links Not Working:
1. Verify AndroidManifest.xml configuration
2. Check redirect URL in Supabase
3. Rebuild and reinstall app
4. Test with ADB command

### "Invalid URL" Error:
1. Verify Site URL is correct
2. Check redirect URLs are added
3. Ensure URLs match exactly (including scheme)

## Quick Command Reference

```bash
# Run app
flutter run

# Test deep link
adb shell am start -W -a android.intent.action.VIEW -d "learnedapp://reset-password"

# Check logs
flutter logs

# Rebuild app
flutter clean
flutter pub get
flutter run

# Check Android intent filters
adb shell dumpsys package | grep -A 3 "learnedapp"
```

## Next Steps

1. ✅ Configure email templates
2. ✅ Set redirect URLs
3. ✅ Enable email confirmation
4. ✅ Test signup flow
5. ✅ Test password reset flow
6. ✅ Test deep links
7. ⚙️ Configure production SMTP (when ready)
8. ⚙️ Customize branding
9. ⚙️ Set up monitoring

## Production Deployment Checklist

- [ ] Configure production SMTP provider
- [ ] Test all flows in production
- [ ] Set up email monitoring
- [ ] Configure custom domain for emails
- [ ] Enable email analytics
- [ ] Set up alerts for delivery failures
- [ ] Document support procedures
- [ ] Train support team on email issues

---

**Need Help?**
- Supabase Docs: https://supabase.com/docs/guides/auth
- Support: https://supabase.com/support
