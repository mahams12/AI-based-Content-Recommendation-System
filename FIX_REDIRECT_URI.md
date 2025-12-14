# Fix redirect_uri_mismatch Error

## Quick Fix (5 minutes)

The `redirect_uri_mismatch` error occurs because your localhost URL isn't in Google Cloud Console's authorized redirect URIs.

### Step-by-Step Fix:

1. **Open Google Cloud Console**
   - Go to: https://console.cloud.google.com/
   - Make sure you're logged in with the correct Google account

2. **Select Your Project**
   - Project: `content-nation-e0549`
   - If you don't see it, check the project dropdown at the top

3. **Navigate to Credentials**
   - Click on **"APIs & Services"** in the left menu
   - Click on **"Credentials"**

4. **Find Your OAuth 2.0 Client**
   - Look for: `597878741733-94oh71atkf557uqhrveuaocgcaanacmc`
   - Click the **pencil icon** (Edit) next to it

5. **Add Authorized Redirect URIs**
   - Scroll down to **"Authorized redirect URIs"**
   - Click **"+ ADD URI"**
   - Add these URIs (one at a time):
     ```
     http://localhost:8080/
     http://127.0.0.1:8080/
     ```
   - **Note:** Replace `8080` with your actual Flutter web port
   - To find your port, check the terminal when running `flutter run -d chrome`
   - It usually shows: `http://127.0.0.1:PORT` or `http://localhost:PORT`

6. **Save**
   - Click **"SAVE"** at the bottom
   - Wait 1-2 minutes for changes to propagate

7. **Clear Browser Cache**
   - Clear your browser cache or use incognito mode
   - Try signing in again

## Common Ports

If you're not sure what port you're using, check your terminal output. Common ports:
- `8080` (default)
- `5000`
- `3000`
- Or any port shown in your terminal

## For Production

If you deploy to a domain, also add:
```
https://yourdomain.com/
https://www.yourdomain.com/
```

## Important Notes

- ⚠️ **This is a MOBILE app** - web support is optional
- ✅ **Mobile (Android & iOS) works 100%** without any configuration
- 🌐 Web sign-in is secondary and requires this configuration
- 💡 **Best experience is on mobile app!**

## Still Having Issues?

1. Make sure you're editing the **Web client** (not Android/iOS)
2. Check that the port number matches exactly
3. Wait 2-3 minutes after saving
4. Try incognito/private browsing mode
5. Check browser console for exact error details

## Mobile App Status

✅ **Android**: Works perfectly - no configuration needed
✅ **iOS**: Works perfectly - no configuration needed
⚠️ **Web**: Requires redirect URI configuration (optional)

