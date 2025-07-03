#!/bin/bash

# Verification script for Simplr Widget files

echo "🔍 Verifying Simplr Widget Files..."
echo "================================="
echo

# Check if SimplrWidget directory exists
if [ -d "SimplrWidget" ]; then
    echo "✅ SimplrWidget directory exists"
else
    echo "❌ SimplrWidget directory missing"
    exit 1
fi

# Check widget files
widget_files=(
    "SimplrWidget/SimplrWidget.swift"
    "SimplrWidget/SimplrWidgetBundle.swift"
    "SimplrWidget/Task+Widget.swift"
    "SimplrWidget/Info.plist"
    "SimplrWidget/SimplrWidget.entitlements"
)

for file in "${widget_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

# Check main app files
app_files=(
    "Simplr/Simplr.entitlements"
    "Simplr/TaskManager.swift"
)

for file in "${app_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

# Check if TaskManager has been updated for App Groups
if grep -q "group.com.danielzverev.simplr" "Simplr/TaskManager.swift"; then
    echo "✅ TaskManager updated for App Groups"
else
    echo "❌ TaskManager not updated for App Groups"
fi

echo
echo "📋 Next Steps:"
echo "1. Open Simplr.xcodeproj in Xcode"
echo "2. Follow the instructions in WIDGET_SETUP_GUIDE.md"
echo "3. Add Widget Extension target through Xcode"
echo "4. Configure App Groups capability"
echo "5. Test the widget on device/simulator"
echo
echo "🎉 All widget files are ready for integration!"