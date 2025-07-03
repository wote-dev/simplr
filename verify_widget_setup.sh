#!/bin/bash

# Widget Setup Verification Script for Simplr

echo "🔧 Verifying Widget Setup After Fix..."
echo "====================================="
echo

# Check if SimplrWidget directory and files exist
echo "📁 Checking Widget Files:"
widget_files=(
    "SimplrWidget/SimplrWidget.swift"
    "SimplrWidget/SimplrWidgetBundle.swift"
    "SimplrWidget/Task+Widget.swift"
    "SimplrWidget/Info.plist"
    "SimplrWidget/SimplrWidget.entitlements"
)

all_files_exist=true
for file in "${widget_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MISSING"
        all_files_exist=false
    fi
done

echo
echo "🔍 Checking App Group Configuration:"

# Check TaskManager for App Groups
if grep -q "group.com.danielzverev.simplr" "Simplr/TaskManager.swift"; then
    echo "✅ TaskManager configured for App Groups"
else
    echo "❌ TaskManager missing App Groups configuration"
fi

# Check CategoryManager for App Groups
if grep -q "group.com.danielzverev.simplr" "Simplr/CategoryManager.swift"; then
    echo "✅ CategoryManager configured for App Groups"
else
    echo "❌ CategoryManager missing App Groups configuration"
fi

# Check Widget for App Groups
if grep -q "group.com.danielzverev.simplr" "SimplrWidget/SimplrWidget.swift"; then
    echo "✅ Widget configured for App Groups"
else
    echo "❌ Widget missing App Groups configuration"
fi

# Check entitlements files
echo
echo "🛡️ Checking Entitlements:"

if [ -f "Simplr/Simplr.entitlements" ]; then
    if grep -q "group.com.danielzverev.simplr" "Simplr/Simplr.entitlements"; then
        echo "✅ Main app entitlements configured"
    else
        echo "❌ Main app entitlements missing App Groups"
    fi
else
    echo "❌ Main app entitlements file missing"
fi

if [ -f "SimplrWidget/SimplrWidget.entitlements" ]; then
    if grep -q "group.com.danielzverev.simplr" "SimplrWidget/SimplrWidget.entitlements"; then
        echo "✅ Widget entitlements configured"
    else
        echo "❌ Widget entitlements missing App Groups"
    fi
else
    echo "❌ Widget entitlements file missing"
fi

echo
echo "🎯 Next Steps in Xcode:"
echo "1. Verify SimplrWidget target appears in target list"
echo "2. Build both Simplr and SimplrWidget targets"
echo "3. Check App Groups capability is enabled for both targets"
echo "4. Install on device and test widget functionality"

echo
echo "🧪 Testing Instructions:"
echo "1. Build and install app on your physical device"
echo "2. Add some tasks with due dates in the main app"
echo "3. Long-press home screen → Add Widget → Search 'Simplr'"
echo "4. Add Simplr widget in small, medium, or large size"
echo "5. Verify widget shows your tasks"

echo
if [ "$all_files_exist" = true ]; then
    echo "✅ All widget files are present and configured correctly!"
    echo "🚀 Follow WIDGET_FIX_INSTRUCTIONS.md to add the widget target in Xcode"
else
    echo "❌ Some widget files are missing. Please check the file structure."
fi 