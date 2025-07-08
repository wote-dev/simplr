#!/bin/bash

# Check if SimplrWidget target exists in Xcode project
echo "🔍 Checking if SimplrWidget target exists in Xcode project..."
echo "================================================"

if grep -q "SimplrWidget" Simplr.xcodeproj/project.pbxproj; then
    echo "✅ SimplrWidget target found in project!"
    echo ""
    echo "📋 SimplrWidget references in project:"
    grep -n "SimplrWidget" Simplr.xcodeproj/project.pbxproj | head -10
    echo ""
    echo "🎉 Your widget should now appear in the widget gallery!"
    echo "📱 Test: Long-press home screen → Add Widget → Search 'Simplr'"
else
    echo "❌ SimplrWidget target NOT found in project"
    echo ""
    echo "🚨 You need to add the SimplrWidget target in Xcode:"
    echo "1. Open Simplr.xcodeproj in Xcode"
    echo "2. File → New → Target → Widget Extension"
    echo "3. Product Name: SimplrWidget"
    echo "4. Bundle ID: blackcubesolutions.Simplr.SimplrWidget"
    echo "5. Follow steps in URGENT_WIDGET_FIX.md"
fi

echo ""
echo "📖 For detailed instructions, see: URGENT_WIDGET_FIX.md"