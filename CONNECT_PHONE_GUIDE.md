# Connect Your Android Phone - Step by Step Guide

## Quick Setup (5 minutes)

### Step 1: Enable Developer Options on Your Phone

1. **Open Settings** on your Android phone
2. **Go to**: "About phone" or "About device"
3. **Find**: "Build number" (usually at the bottom)
4. **Tap "Build number" 7 times** rapidly
   - You'll see a message: "You are now a developer!"
5. **Go back** to main Settings

### Step 2: Enable USB Debugging

1. **In Settings**, find **"Developer options"** (usually under System or Advanced)
2. **Turn ON** "Developer options" toggle (at the top)
3. **Scroll down** and find **"USB debugging"**
4. **Turn ON** "USB debugging"
5. **Optional but recommended**: Turn ON "Install via USB" (if available)

### Step 3: Connect Your Phone

1. **Connect your phone** to your Mac using a USB cable
2. **On your phone**, you'll see a popup: **"Allow USB debugging?"**
3. **Check the box**: "Always allow from this computer"
4. **Tap "Allow"** or "OK"

### Step 4: Verify Connection

Run this command in terminal:
```bash
flutter devices
```

You should see your phone listed!

## Troubleshooting

### Phone Not Showing Up?

#### Check 1: USB Cable
- Use a **data cable** (not just charging cable)
- Try a different USB port on your Mac
- Try a different cable

#### Check 2: USB Mode on Phone
- When you connect, pull down notification panel
- Tap "USB" or "Charging this device"
- Select **"File Transfer"** or **"MTP"** mode
- NOT "Charging only"

#### Check 3: Trust Computer
- Disconnect and reconnect USB
- Look for popup on phone: "Allow USB debugging?"
- Make sure to check "Always allow"
- Tap "Allow"

#### Check 4: ADB Connection
Run in terminal:
```bash
adb devices
```

If you see:
- `unauthorized` - Tap "Allow" on your phone when popup appears
- `offline` - Disconnect and reconnect USB cable
- `device` - ✅ Good! Your phone is connected

#### Check 5: Restart ADB
If still not working:
```bash
adb kill-server
adb start-server
adb devices
```

### Still Not Working?

1. **Uninstall USB drivers** (if any) and reconnect
2. **Restart your Mac**
3. **Restart your phone**
4. **Try different USB port**
5. **Check if phone charges** when connected (confirms cable works)

## Run App on Phone

Once your phone is connected:

```bash
flutter run
```

Or specify your device:
```bash
flutter run -d <device-id>
```

## For iOS (iPhone)

If you have an iPhone:
1. Connect iPhone to Mac
2. Trust the computer on iPhone
3. In Xcode: Window → Devices and Simulators
4. Select your iPhone
5. Enable "Connect via network" (optional)
6. Run: `flutter run -d <iphone-id>`

## Quick Commands

```bash
# Check connected devices
flutter devices

# Check ADB connection
adb devices

# Restart ADB
adb kill-server && adb start-server

# Run on connected device
flutter run
```

## Common Issues

### "No devices found"
- Enable USB debugging
- Allow USB debugging popup on phone
- Check USB cable

### "Device unauthorized"
- Tap "Allow" on phone popup
- Check "Always allow" checkbox

### "ADB not found"
- Install Android SDK Platform Tools
- Or use Android Studio (includes ADB)

## Success!

Once connected, you'll see:
```
Found 1 connected device:
  SM-G991B (mobile) • R58M123456 • android-arm64 • Android 13
```

Then run: `flutter run` and your app will install on your phone! 🚀

