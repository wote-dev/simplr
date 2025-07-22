# RevenueCat Integration Guide

## Overview
This document outlines the RevenueCat SDK integration in the Simplr iOS app for managing premium subscriptions and in-app purchases.

## Integration Status
✅ **COMPLETED**: RevenueCat SDK has been successfully integrated into the Simplr app.

## What's Implemented

### 1. SDK Configuration
- **Location**: `SimplrApp.swift`
- **API Key**: `appl_RGXidiAkFqiTrNXFrpRQrYgZvTY`
- **Debug Logging**: Enabled for development

### 2. Premium Manager Integration
- **Location**: `PremiumManager.swift`
- **Features**:
  - RevenueCat SDK import and configuration
  - PurchasesDelegate implementation
  - Real purchase flow using RevenueCat's purchase methods
  - Subscription status checking via CustomerInfo
  - Restore purchases functionality
  - Automatic subscription status updates

### 3. Paywall Integration
- **Location**: `PaywallView.swift`
- **Features**:
  - Dynamic pricing from RevenueCat offerings
  - Real-time offering loading
  - Fallback pricing for offline scenarios
  - Loading states for better UX

### 4. Product Configuration
The app is configured to work with these RevenueCat product identifiers:
- `simplr.premium.monthly.sub` - Monthly Premium Subscription
- `simplr.premium.annual.sub` - Annual Premium Subscription

### Entitlements:
- `premium` - Access to all premium features

### Pricing Structure:
- **Monthly Premium**: $1.99 USD/month - All premium features
- **Annual Premium**: $14.99 USD/year - All premium features (Best Value)

## Required Setup in RevenueCat Dashboard

### 1. Products Configuration
Create these products in your RevenueCat dashboard:

#### Subscription Products:
- **Product ID**: `simplr.premium.monthly.sub`
- **Type**: Auto-renewable subscription
- **Duration**: 1 month
- **Price**: $1.99/month

- **Product ID**: `simplr.premium.annual.sub`
- **Type**: Auto-renewable subscription
- **Duration**: 1 year
- **Price**: $14.99/year

### 2. Entitlements Setup
Create this entitlement:
- `premium` - Access to all premium features

### 3. Offerings Configuration
Create a default offering that includes:
- The monthly subscription as the monthly package
- The annual subscription as the annual package

## App Store Connect Setup

### 1. In-App Purchase Products
Create these products in App Store Connect:
- `simplr.premium.monthly.sub` - Auto-renewable subscription
- `simplr.premium.annual.sub` - Auto-renewable subscription

### 2. Subscription Groups
Create a subscription group and add both the monthly and annual subscriptions to it.

## Testing

### 1. Sandbox Testing
- Use sandbox Apple ID for testing
- RevenueCat automatically handles sandbox vs production
- Test both individual purchases and subscriptions

### 2. Debug Features
- Debug logging is enabled in development
- Check Xcode console for RevenueCat logs
- Monitor purchase flows and subscription status changes

## Key Features

### 1. Automatic Subscription Management
- Real-time subscription status updates
- Automatic handling of subscription renewals
- Cross-platform subscription sharing

### 2. Purchase Restoration
- Users can restore previous purchases
- Automatic sync across devices
- Handles both individual and subscription purchases

### 3. Offline Support
- Fallback pricing when offerings can't be loaded
- Graceful handling of network issues
- Local premium status caching

### 4. Security
- Server-side receipt validation through RevenueCat
- Protection against purchase manipulation
- Secure entitlement checking

## Code Architecture

### PremiumManager
- Singleton pattern for app-wide premium status
- Implements PurchasesDelegate for real-time updates
- Manages local premium status and UserDefaults sync
- Handles all purchase and restore operations

### PaywallView
- Dynamic UI based on RevenueCat offerings
- Real-time pricing updates
- Loading states and error handling
- Beautiful, conversion-optimized design

## Next Steps

1. **Configure RevenueCat Dashboard**: Set up products, entitlements, and offerings
2. **App Store Connect**: Create corresponding in-app purchase products
3. **Testing**: Test purchase flows in sandbox environment
4. **Production**: Switch to production API key when ready for release

## Support

For RevenueCat-specific issues:
- [RevenueCat Documentation](https://docs.revenuecat.com/)
- [RevenueCat Support](https://support.revenuecat.com/)

For app-specific integration questions, refer to the code comments in:
- `PremiumManager.swift`
- `PaywallView.swift`
- `SimplrApp.swift`