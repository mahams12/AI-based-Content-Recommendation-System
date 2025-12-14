# How to Find Google Play System Image

## Problem
You're seeing "Google APIs" images but need "Google Play" images (with Play Store).

## Solution: Filter for Google Play Images

### Step 1: Use the Services Filter
1. In the "Services" dropdown (currently "Show All")
2. Click on it and look for "Google Play" option
3. Select "Google Play" - this will filter to show only images with Play Store

### Step 2: If "Google Play" Option Doesn't Exist
The Services dropdown might not show "Google Play" as a filter option. In that case:

1. **Change API Level**: Try API 34 or API 33
   - These older API levels usually have Google Play images available
   - Click the "API" dropdown and select "API 34" or "API 33"

2. **Look for Different Image Names**:
   - After changing API level, look for images named:
     - "Google Play ARM 64 v8a System Image" (has Play Store icon)
     - NOT "Google APIs ARM 64 v8a System Image"

### Step 3: Download Google Play Image
If you still don't see Google Play images:

1. **Go to SDK Manager**:
   - In Android Studio: Tools → SDK Manager
   - Click "SDK Platforms" tab
   - Check the "Show Package Details" checkbox at bottom right

2. **Find Google Play Images**:
   - Expand an API level (e.g., API 34)
   - Look for "Google Play" system images
   - Check the box to download
   - Click "Apply" to download

3. **Go Back to AVD Manager**:
   - After download, go back to creating the emulator
   - The Google Play images should now appear

### Step 4: Alternative - Use API 33 or API 34
These API levels almost always have Google Play images:

1. Change API dropdown to "API 34" or "API 33"
2. In Services dropdown, try selecting different options
3. Look for images with "Google Play" in the name
4. They should have a Play Store icon (shopping bag icon)

## Visual Guide

**What you're seeing now:**
- ❌ "Google APIs ARM 64 v8a System Image" (no Play Store)

**What you need:**
- ✅ "Google Play ARM 64 v8a System Image" (has Play Store icon)

## Quick Fix: Use API 34

1. Change API dropdown from "API 36" to "API 34"
2. This should show Google Play images
3. Select one with "Google Play" in the name
4. Verify right panel shows "Services: Google Play"
5. Click Finish

## If Still No Google Play Images

You might need to:
1. Update Android Studio
2. Update Android SDK
3. Or test on a real device (which always has Play Services)

Real devices are the most reliable for testing Google Sign-In!

