#!/bin/bash
echo "🔍 Checking for connected devices..."
echo ""
echo "Flutter devices:"
flutter devices
echo ""
echo "ADB devices:"
adb devices
echo ""
echo "If you see your phone listed above, you're good to go! 🚀"
echo "If not, make sure:"
echo "  1. USB debugging is enabled on your phone"
echo "  2. You tapped 'Allow' on the USB debugging popup"
echo "  3. USB mode is set to 'File Transfer' or 'MTP'"

