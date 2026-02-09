# LearnED Email Templates

Professional email templates for Supabase Auth, styled to match the LearnED app design.

## 🎨 Design Features

- **Brand Colors**: Primary red (#E53935) with gradient effects
- **Typography**: Inter font family (matching the app)
- **Responsive**: Mobile-friendly design
- **Professional**: Clean, modern layout with proper spacing

## 📧 Available Templates

1. **confirmation.html** - Email verification for new signups
2. **invite.html** - User invitation emails
3. **magic_link.html** - Passwordless login emails
4. **recovery.html** - Password reset emails
5. **email_change.html** - Email address change confirmation
6. **reauthentication.html** - Re-authentication verification codes

## 🖼️ Logo Setup

The templates use a logo hosted on Supabase Storage. To set up your logo:

1. Upload your white logo (PNG with transparent background) to Supabase Storage:
   - Navigate to Storage in Supabase Dashboard
   - Create a bucket named `app-assets` (make it public)
   - Upload your logo as `learned-logo-white.png`

2. The logo URL in templates is:
   ```
   https://ugphaeiqbfejnzpiqdty.supabase.co/storage/v1/object/public/app-assets/learned-logo-white.png
   ```

If you want to use a different logo path, replace all occurrences of the above URL in the templates.

## 📋 How to Use

### Option 1: Copy to Supabase Dashboard

1. Go to [Supabase Dashboard → Authentication → Email Templates](https://supabase.com/dashboard/project/ugphaeiqbfejnzpiqdty/auth/templates)
2. For each template type:
   - Click "Edit"
   - Copy the HTML content from the corresponding file
   - Paste into the template editor
   - Save changes

### Option 2: Use Supabase CLI (Local Development)

Add to your `supabase/config.toml`:

```toml
[auth.email.template.confirmation]
subject = "Confirm Your Email - LearnED"
content_path = "./supabase/email_templates/confirmation.html"

[auth.email.template.invite]
subject = "You've Been Invited - LearnED"
content_path = "./supabase/email_templates/invite.html"

[auth.email.template.magic_link]
subject = "Your Magic Link - LearnED"
content_path = "./supabase/email_templates/magic_link.html"

[auth.email.template.recovery]
subject = "Reset Your Password - LearnED"
content_path = "./supabase/email_templates/recovery.html"

[auth.email.template.email_change]
subject = "Confirm Email Change - LearnED"
content_path = "./supabase/email_templates/email_change.html"

[auth.email.template.reauthentication]
subject = "Confirm Your Action - LearnED"
content_path = "./supabase/email_templates/reauthentication.html"
```

## 🎯 Template Variables

All templates support these Supabase variables:

- `{{ .ConfirmationURL }}` - Confirmation/action URL
- `{{ .Token }}` - 6-digit OTP code
- `{{ .TokenHash }}` - Hashed token for custom URLs
- `{{ .SiteURL }}` - Your app's site URL
- `{{ .Email }}` - User's email address
- `{{ .NewEmail }}` - New email (for email_change template)

## 🎨 Customization

### Colors
Primary: `#E53935` (Red)
Secondary: `#10B981` (Green)
Background: `#F9FAFB` (Light Gray)

To change colors, search and replace the hex values in the templates.

### Fonts
Currently using Inter font. To change:
1. Update the Google Fonts link in `<head>`
2. Update `font-family` in the `body` style

### Logo
Replace the logo URL in all templates with your own hosted logo URL.

## 📱 Testing

Test your email templates using:

```bash
supabase functions serve
```

Then trigger auth actions (signup, password reset, etc.) to see the emails in your local Mailpit instance.

## 🔒 Security Notes

- Never include sensitive data in email templates
- Links expire after specified time (shown in each email)
- Users are warned about phishing attempts
- Security notices included in all templates

## 📞 Support

For issues or customization help, contact the LearnED development team.
