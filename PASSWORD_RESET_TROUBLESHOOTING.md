# Password Reset Email Troubleshooting Guide

## Why You're Not Receiving Password Reset Emails

If you're not receiving password reset emails, follow these steps:

### ✅ Step 1: Verify Email Address
1. **Double-check the email** you entered
2. **Make sure you have an account** with that email address
3. **Try the exact email** you used to sign up

### ✅ Step 2: Check Email Folders
1. **Inbox** - Wait 2-5 minutes for the email to arrive
2. **Spam/Junk folder** - Check thoroughly
3. **Promotions folder** (Gmail) - Check if using Gmail
4. **All Mail** - Search for "Firebase" or "password reset"

### ✅ Step 3: Check Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **content-nation-e0549**
3. Go to **Authentication** → **Users**
4. Find your email address
5. Check if the user exists and is verified

### ✅ Step 4: Check Firebase Email Template

1. In Firebase Console, go to **Authentication** → **Templates**
2. Click on **"Password reset"** template
3. Make sure it's **enabled**
4. Check the **sender email**: Should be `noreply@content-nation-e0549.firebaseapp.com`
5. Verify the **email content** looks correct

### ✅ Step 5: Check Firebase Project Limits

**Free Tier Limits:**
- **100 emails per day** for password reset
- If exceeded, wait 24 hours or upgrade to Blaze plan

**To Check:**
1. Firebase Console → **Usage and billing**
2. Check if you've hit the daily limit

### ✅ Step 6: Test with Different Email

Try with:
- **Gmail** account (most reliable)
- **Outlook/Hotmail** account
- Different email provider

This helps identify if it's provider-specific.

### ✅ Step 7: Check App Logs

When you request a password reset, check the console logs:

**Look for:**
- `✅ Password reset email sent successfully to: [email]`
- `❌ Password reset error: [error code]`

**Common Error Codes:**
- `user-not-found` - No account with this email
- `invalid-email` - Email format is wrong
- `too-many-requests` - Too many attempts, wait 5-10 minutes
- `network-request-failed` - Internet connection issue

### ✅ Step 8: Verify User Account Exists

**In the app:**
1. Try to **sign in** with that email
2. If sign-in fails, the account might not exist
3. **Sign up** first if you don't have an account

### ✅ Step 9: Firebase Email Delivery Issues

**Common Issues:**
1. **Email provider blocking** - Some providers block Firebase emails
2. **Domain reputation** - Firebase's sender domain might be flagged
3. **Email delays** - Can take 5-10 minutes sometimes

**Solutions:**
- Use a Gmail account (most reliable)
- Wait 10-15 minutes and check again
- Check spam filters on your email provider

### ✅ Step 10: Custom Email Domain (If Configured)

If you've configured a custom email domain:
1. Verify the domain in Firebase Console
2. Check DNS records are correct
3. Verify SPF/DKIM records

### 🔧 Quick Fixes

**Fix 1: Resend Email**
- Wait 5 minutes
- Click "Resend Email" on the password reset screen
- Try again

**Fix 2: Use Different Email**
- If you have multiple emails, try another one
- Make sure you signed up with that email

**Fix 3: Check Firebase Console**
- Go to Authentication → Users
- Verify your email is listed
- Check if email is verified

**Fix 4: Wait and Retry**
- Sometimes emails are delayed
- Wait 10-15 minutes
- Check all folders again

### 📧 Email Provider Specific Tips

**Gmail:**
- Check "Promotions" tab
- Check "Spam" folder
- Search for "Firebase" or "password reset"

**Outlook/Hotmail:**
- Check "Junk Email" folder
- Check "Other" folder
- Wait longer (can take 10+ minutes)

**Yahoo:**
- Check "Spam" folder
- Check "Bulk" folder
- May take longer to arrive

### 🚨 Still Not Working?

If emails still don't arrive after trying all steps:

1. **Check Firebase Console Logs:**
   - Go to Firebase Console → Authentication
   - Check for any error messages
   - Look at user activity

2. **Verify Firebase Configuration:**
   - Check `firebase_options.dart` is correct
   - Verify project ID: `content-nation-e0549`
   - Check API keys are valid

3. **Test with Firebase CLI:**
   ```bash
   firebase auth:export users.json
   ```
   This exports all users to verify your email exists

4. **Contact Firebase Support:**
   - If everything else fails
   - Check Firebase status page
   - Contact Firebase support

### 💡 Alternative Solution

If password reset emails don't work, you can:
1. **Create a new account** with the same email (if possible)
2. **Contact app support** to manually reset password
3. **Use a different email** to sign up

### 📝 Code Improvements Made

The password reset code has been improved with:
- ✅ Better error messages
- ✅ User existence checking
- ✅ Detailed logging
- ✅ Simplified email sending (removed complex settings)
- ✅ Better error handling

### 🔍 Debugging Commands

**Check if email exists in Firebase:**
```dart
final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
print('Sign-in methods: $methods');
```

**Send password reset:**
```dart
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
```

**Check Firebase logs:**
- Look for `✅ Password reset email sent successfully`
- Check for any error codes

---

**Last Updated:** After implementing improved password reset functionality
**Project:** content-nation-e0549
**Firebase Project ID:** content-nation-e0549

