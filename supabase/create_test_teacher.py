#!/usr/bin/env python3
"""
Simple Teacher Account Creator for LearnED Platform
Creates a test teacher account for UI testing
"""

import os
from supabase import create_client, Client
from datetime import datetime

# Configuration - UPDATE THESE WITH YOUR SUPABASE CREDENTIALS
SUPABASE_URL = "https://ugphaeiqbfejnzpiqdty.supabase.co"  # Replace with your Supabase URL
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVncGhhZWlxYmZlam56cGlxZHR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMTMwNDcsImV4cCI6MjA2OTc4OTA0N30.-OcW0or7v6krUQJUG0Jb8VoPbpbGjbdbjsMKn6KplM8"  # Replace with your anon key

def create_test_teacher():
    """Create a test teacher account and send magic link"""
    try:
        # Initialize Supabase client
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        print("🚀 Creating test teacher account with magic link...")
        print("=" * 50)
        
        # Teacher details
        email = "test.teacher@learned.com"
        
        # First check if teacher already exists
        existing_user = supabase.table('users').select('*').eq('email', email).execute()
        
        if existing_user.data:
            print("⚠️  Teacher already exists in public.users!")
            print(f"📧 Email: {email}")
            print(f" User ID: {existing_user.data[0]['id']}")
            
            # Check if teacher record exists
            teacher_record = supabase.table('teachers').select('*').eq('user_id', existing_user.data[0]['id']).execute()
            if teacher_record.data:
                print(f"🆔 Teacher ID: {teacher_record.data[0]['teacher_id']}")
            
            print("\n� Sending magic link for existing teacher...")
            
        else:
            # Create teacher in public tables first
            try:
                result = supabase.rpc('create_test_teacher_simple', {
                    'p_email': email,
                    'p_password': 'TempPass123!'  # Won't be used with magic link
                }).execute()
                print("✅ Teacher profile created in database")
            except Exception as rpc_error:
                print(f"⚠️  RPC call had parsing issues, checking if teacher was created...")
            
            # Verify creation
            created_user = supabase.table('users').select('*').eq('email', email).execute()
            if created_user.data:
                print("✅ Teacher account created successfully!")
                teacher_data = supabase.table('teachers').select('*').eq('user_id', created_user.data[0]['id']).execute()
                if teacher_data.data:
                    print(f"🆔 Teacher ID: {teacher_data.data[0]['teacher_id']}")
            else:
                print("❌ Failed to create teacher profile")
                return
        
        # Send magic link
        print("\n� Sending magic link...")
        try:
            auth_response = supabase.auth.sign_in_with_otp({
                'email': email,
                'options': {
                    'email_redirect_to': 'http://localhost:3000/auth/callback'  # Adjust for your app
                }
            })
            
            print("✅ Magic link sent successfully!")
            print("=" * 50)
            print("🎯 NEXT STEPS:")
            print(f"1. Check email inbox: {email}")
            print("2. Click the magic link in the email")
            print("3. This will create the auth user automatically")
            print("4. You'll be redirected to your app and logged in")
            print("=" * 50)
            print("\n💡 Benefits of Magic Links:")
            print("✅ No manual auth user creation needed")
            print("✅ More secure (no password to manage)")
            print("✅ Professional user experience")
            print("✅ Automatic email verification")
            
        except Exception as auth_error:
            print(f"❌ Failed to send magic link: {str(auth_error)}")
            print("\n🔧 Alternative: Manual Auth User Creation")
            print("1. Go to Supabase Dashboard → Authentication → Users")
            print("2. Click 'Add user' button")
            print(f"3. Email: {email}")
            print("4. Password: TestPass123!")
            print("5. Check 'Email Confirm' ✅")
            print("6. Click 'Create user'")
                
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        print("\n🔧 Troubleshooting:")
        print("1. Check your SUPABASE_URL and SUPABASE_KEY")
        print("2. Ensure email settings are configured in Supabase")
        print("3. Check if magic links are enabled in Authentication settings")

def cleanup_test_teacher():
    """Remove the test teacher account"""
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        print("🧹 Cleaning up test teacher...")
        
        # Delete from public.users table (cascades to teachers table)
        result = supabase.table('users').delete().eq('email', 'test.teacher@learned.com').execute()
        
        print("✅ Test teacher removed from database")
        print("⚠️  Note: You may need to manually delete the auth user from Supabase Dashboard")
        
    except Exception as e:
        print(f"❌ Cleanup error: {str(e)}")

def main():
    print("📋 LearnED Teacher Test Creator")
    print("=" * 40)
    
    # Check if credentials are set
    if SUPABASE_URL == "YOUR_SUPABASE_URL" or SUPABASE_KEY == "YOUR_SUPABASE_ANON_KEY":
        print("⚠️  Please update SUPABASE_URL and SUPABASE_KEY at the top of this file!")
        print("\nFind these in your Supabase Dashboard:")
        print("• Project Settings → API → Project URL")
        print("• Project Settings → API → Project API keys → anon/public")
        return
    
    print("Choose an option:")
    print("1. Create test teacher")
    print("2. Cleanup test teacher")
    print("3. Exit")
    
    choice = input("\nEnter choice (1-3): ").strip()
    
    if choice == "1":
        create_test_teacher()
    elif choice == "2":
        cleanup_test_teacher()
    elif choice == "3":
        print("👋 Goodbye!")
    else:
        print("❌ Invalid choice")

if __name__ == "__main__":
    main()