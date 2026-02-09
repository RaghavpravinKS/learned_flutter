# Quick Start: Testing Email Auth & Password Reset

## 🚀 Quick Test (5 Minutes)

### Prerequisites
- Flutter app installed on device/emulator
- Access to email account for testing

### Step 1: Test Sign Up with Email Verification

**In App:**
1. Open the app
2. Tap "Sign Up"
3. Fill in details:
   - First Name: Test
   - Last Name: User
   - Email: your-email@example.com
   - Password: TestPass123
   - Confirm Password: TestPass123
   - Select Grade (if student)
   - Accept terms
4. Tap "Register"

**Expected Result:**
- ✅ Should see "Registration successful! Please verify your email."
- ✅ Navigates to Email Verification Screen
- ✅ Shows your email address

**In Email:**
1. Check inbox for "Confirm your LearnED account" email
2. Click the verification link

**Expected Result:**
- ✅ Email gets verified in Supabase
- ✅ Can now login with the account

**Test Resend:**
1. Before clicking email link, tap "Resend Verification Email"
2. Check inbox for new email

**Expected Result:**
- ✅ New verification email received
- ✅ Button shows "Email Resent!"

### Step 2: Test Login with Verified Account

**In App:**
1. Go back to login screen
2. Enter email and password
3. Tap "Login"

**Expected Result:**
- ✅ Successfully logs in
- ✅ Navigates to dashboard

### Step 3: Test Forgot Password Flow

**In App:**
1. From login screen, tap "Forgot Password?"
2. Enter your email
3. Tap "Send Reset Link"

**Expected Result:**
- ✅ Shows "Password reset link sent! Please check your email."
- ✅ Navigates back to login

**In Email:**
1. Check inbox for "Reset your LearnED password" email
2. Click the reset password link

**Expected Result:**
- ✅ App opens automatically
- ✅ Shows Reset Password Screen

**In App (Reset Password Screen):**
1. Enter new password: NewPass123
2. Confirm new password: NewPass123
3. Tap "Reset Password"

**Expected Result:**
- ✅ Shows "Password updated successfully!"
- ✅ User is signed out automatically
- ✅ Navigates to login screen

**Test New Password:**
1. Try logging in with old password

**Expected Result:**
- ❌ Login fails with old password

2. Login with new password

**Expected Result:**
- ✅ Successfully logs in with new password

## 🔧 If Something Doesn't Work

### Email Not Received?
**Check:**
1. Spam/Junk folder
2. Wait 2-3 minutes
3. Check Supabase dashboard → Authentication → Logs

**Fix:**
- Go to Supabase Dashboard
- Authentication → Settings
- Verify SMTP is configured
- For testing, default Supabase SMTP should work (4 emails/hour limit)

### Deep Link Not Opening App?
**Test with ADB:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "learnedapp://reset-password"
```

**If doesn't work:**
```bash
# Rebuild app
flutter clean
flutter pub get
flutter run
```

### Email Link Not Working?
**Check Expiry:**
- Verification links: 24 hours
- Reset links: 1 hour

**Request New Link:**
- Verification: Tap "Resend Verification Email"
- Reset: Go through forgot password flow again

## 📋 Quick Verification Checklist

### Code Side (Already Done ✅)
- [x] Auth service methods implemented
- [x] Email verification screen functional
- [x] Forgot password screen functional
- [x] Reset password screen functional
- [x] Deep link configured in AndroidManifest
- [x] Auth state listener in main.dart

### Supabase Side (TO DO ⚙️)
- [ ] Email templates configured
- [ ] Redirect URLs added
- [ ] Email confirmation enabled
- [ ] Site URL configured

## 🔍 Troubleshooting Commands

```bash
# View app logs
flutter logs

# Test deep link
adb shell am start -W -a android.intent.action.VIEW -d "learnedapp://reset-password"

# Check Android intent filters
adb shell dumpsys package com.example.learned_flutter | grep -A 5 learnedapp

# Rebuild app
flutter clean && flutter pub get && flutter run

# Check if app is installed
adb shell pm list packages | grep learned
```

## 📱 Testing Matrix

### Test Case 1: New User Registration
| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | Register new account | Success message shown | ⚙️ |
| 2 | Check email | Verification email received | ⚙️ |
| 3 | Click verification link | Email verified | ⚙️ |
| 4 | Login with account | Successfully logged in | ⚙️ |

### Test Case 2: Resend Verification
| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | On verification screen | Tap "Resend" | ⚙️ |
| 2 | Check email | New verification email | ⚙️ |
| 3 | Button state | Shows "Email Resent!" | ⚙️ |

### Test Case 3: Password Reset
| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | Tap "Forgot Password" | Navigation to forgot password screen | ⚙️ |
| 2 | Enter email & submit | Success message | ⚙️ |
| 3 | Check email | Reset email received | ⚙️ |
| 4 | Click reset link | App opens to reset screen | ⚙️ |
| 5 | Enter new password | Password updated | ⚙️ |
| 6 | Auto sign out | Signed out to login | ⚙️ |
| 7 | Login with new password | Successfully logged in | ⚙️ |

## 🎯 Success Criteria

**All flows working if:**
- ✅ Can register new account
- ✅ Verification email received within 1 minute
- ✅ Email link verifies account
- ✅ Can login after verification
- ✅ Can resend verification email
- ✅ Forgot password sends reset email
- ✅ Reset link opens app to reset screen
- ✅ Can set new password
- ✅ Auto signed out after password change
- ✅ Can login with new password
- ✅ Cannot login with old password

## 🚨 Known Limitations

### Development Mode:
- Supabase default SMTP: 4 emails per hour
- Email delivery may take 1-2 minutes
- Links expire (verification: 24h, reset: 1h)

### Solution for Testing:
- Use different email addresses
- Wait between tests
- Or configure production SMTP (SendGrid, etc.)

## 📞 Need Help?

### Check These First:
1. **Supabase Logs**: Dashboard → Authentication → Logs
2. **Flutter Logs**: Run `flutter logs` in terminal
3. **Email Provider**: Check spam folder
4. **Deep Links**: Test with ADB command

### Common Fixes:
```bash
# Clear app data and reinstall
adb uninstall com.example.learned_flutter
flutter run

# Check auth state
# In Supabase Dashboard → Authentication → Users
# Verify user email_confirmed_at is set

# Test SMTP
# In Supabase Dashboard → Authentication → Settings
# Send test email
```

## ✅ Done Testing? Next Steps:

1. **Configure Production SMTP**
   - See: `docs/SUPABASE_EMAIL_QUICK_SETUP.md`
   - Recommended: SendGrid (100 emails/day free)

2. **Customize Email Templates**
   - Add your branding
   - Update colors and logo
   - See templates in setup guide

3. **Set Up Monitoring**
   - Monitor email delivery rates
   - Set up alerts for failures
   - Track auth events

4. **Deploy to Production**
   - Test in staging first
   - Update environment variables
   - Monitor after deployment

---

**Quick Reference:**
- 📖 Full Guide: `docs/EMAIL_AUTH_SETUP_GUIDE.md`
- ⚡ Supabase Setup: `docs/SUPABASE_EMAIL_QUICK_SETUP.md`
- 📋 Summary: `docs/EMAIL_AUTH_IMPLEMENTATION_SUMMARY.md`
