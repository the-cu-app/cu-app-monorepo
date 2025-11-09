# Deep Linking Setup Guide - Next.js → Flutter App

## Overview
This guide shows how to set up deep links from your Next.js website/product to the CU Core Banking Flutter app, allowing Credit Unions to link directly to specific account details and transactions.

---

## ✅ What's Currently Working

### Account Details Flow
1. **Home Screen** → Tap Plaid account card
2. **Account Details Screen** → See transactions
3. **Transaction Details** → Tap any transaction
4. **Export Data** → Section 1033 compliant export (FDX JSON, CSV, QFX, OFX)

### Available Routes
- `/home` - Main dashboard with accounts
- `/account-details` - Account detail view (requires account data)
- `/privacy/data-export` - Data export screen (Section 1033)
- `/privacy/connected-apps` - Connected apps management
- `/privacy/access-history` - Data access log

---

## Deep Linking Setup

### 1. iOS Setup (Universal Links)

#### A. Add Associated Domains to Xcode
**File:** `ios/Runner/Runner.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.associated-domains</key>
  <array>
    <string>applinks:yourcreditunion.com</string>
    <string>applinks:www.yourcreditunion.com</string>
  </array>
</dict>
</plist>
```

#### B. Add URL Scheme to Info.plist
**File:** `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.yourcreditunion.banking</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>cubanking</string>
    </array>
  </dict>
</array>
```

---

### 2. Android Setup (App Links)

#### A. Add Intent Filters
**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<activity
    android:name=".MainActivity"
    ...>
    <!-- Deep Link Intent Filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <!-- HTTPS links -->
        <data
            android:scheme="https"
            android:host="yourcreditunion.com"
            android:pathPrefix="/app" />

        <!-- Custom scheme -->
        <data
            android:scheme="cubanking"
            android:host="app" />
    </intent-filter>
</activity>
```

---

### 3. Flutter Deep Link Handler

#### A. Add package
**File:** `pubspec.yaml`

```yaml
dependencies:
  uni_links: ^0.5.1
  app_links: ^6.3.2
```

#### B. Create Deep Link Service
**File:** `lib/services/deep_link_service.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  Stream<Uri>? _linkStream;

  /// Initialize deep link listener
  void init(BuildContext context) {
    _linkStream = _appLinks.uriLinkStream;

    // Handle deep links
    _linkStream!.listen((Uri uri) {
      _handleDeepLink(context, uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });

    // Check for initial link (cold start)
    _checkInitialLink(context);
  }

  Future<void> _checkInitialLink(BuildContext context) async {
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null) {
        _handleDeepLink(context, uri);
      }
    } catch (e) {
      debugPrint('Initial link error: $e');
    }
  }

  void _handleDeepLink(BuildContext context, Uri uri) {
    debugPrint('Deep link received: $uri');

    // Parse the URI and navigate
    final path = uri.path;
    final params = uri.queryParameters;

    if (path.startsWith('/account/')) {
      final accountId = path.replaceAll('/account/', '');
      _navigateToAccount(context, accountId, params);
    } else if (path == '/export') {
      Navigator.of(context).pushNamed('/privacy/data-export');
    } else if (path == '/home') {
      Navigator.of(context).pushNamed('/home');
    }
  }

  void _navigateToAccount(BuildContext context, String accountId, Map<String, String> params) {
    // You'll need to fetch the account data by ID
    // For now, navigate to home and let user select
    Navigator.of(context).pushNamed('/home');
  }
}
```

#### C. Initialize in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... existing initialization

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  // ...
}

class _MyAppState extends State<MyApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize deep linking after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.init(context);
    });
  }

  // ... rest of widget
}
```

---

### 4. Next.js Website Integration

#### A. Create Deep Link Component
**File:** `components/BankingAppLink.tsx`

```tsx
import Link from 'next/link';
import { useState, useEffect } from 'react';

interface BankingAppLinkProps {
  accountId?: string;
  path?: string;
  children: React.ReactNode;
  className?: string;
}

export function BankingAppLink({
  accountId,
  path = '/home',
  children,
  className
}: BankingAppLinkProps) {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() {
    setIsMobile(/iPhone|iPad|iPod|Android/i.test(navigator.userAgent));
  }, []);

  const getDeepLink = () => {
    // Universal link (iOS) / App link (Android)
    const httpsLink = `https://yourcreditunion.com/app${path}`;

    // Custom scheme fallback
    const customLink = accountId
      ? `cubanking://app/account/${accountId}`
      : `cubanking://app${path}`;

    return {
      https: httpsLink,
      custom: customLink
    };
  };

  const handleClick = (e: React.MouseEvent) => {
    if (!isMobile) return; // Let normal link work on desktop

    e.preventDefault();
    const links = getDeepLink();

    // Try app link first
    window.location.href = links.custom;

    // Fallback to store after 1 second
    setTimeout(() => {
      const isIOS = /iPhone|iPad|iPod/i.test(navigator.userAgent);
      const storeUrl = isIOS
        ? 'https://apps.apple.com/app/your-credit-union-banking/id123456789'
        : 'https://play.google.com/store/apps/details?id=com.yourcreditunion.banking';

      window.location.href = storeUrl;
    }, 1000);
  };

  return (
    <a
      href={getDeepLink().https}
      onClick={handleClick}
      className={className}
    >
      {children}
    </a>
  );
}
```

#### B. Usage in Next.js Pages

```tsx
import { BankingAppLink } from '@/components/BankingAppLink';

export default function HomePage() {
  return (
    <div>
      <h1>Welcome to Your Credit Union</h1>

      {/* Link to app home */}
      <BankingAppLink path="/home">
        <button className="btn-primary">
          Open Banking App
        </button>
      </BankingAppLink>

      {/* Link to specific account */}
      <BankingAppLink
        accountId="account_123"
        path="/account/account_123"
      >
        <button className="btn-secondary">
          View Savings Account
        </button>
      </BankingAppLink>

      {/* Link to export data */}
      <BankingAppLink path="/export">
        <button className="btn-outline">
          Export Your Data
        </button>
      </BankingAppLink>
    </div>
  );
}
```

---

### 5. Apple App Site Association (AASA)

**File:** `https://yourcreditunion.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.yourcreditunion.banking",
        "paths": [
          "/app/*",
          "/account/*",
          "/export"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "TEAM_ID.com.yourcreditunion.banking"
    ]
  }
}
```

**Important:**
- Replace `TEAM_ID` with your Apple Developer Team ID
- Serve this file with `Content-Type: application/json`
- No `.json` extension

---

### 6. Android App Links (assetlinks.json)

**File:** `https://yourcreditunion.com/.well-known/assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.yourcreditunion.banking",
      "sha256_cert_fingerprints": [
        "YOUR_SHA256_FINGERPRINT_HERE"
      ]
    }
  }
]
```

**Get SHA256 fingerprint:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## Deep Link URL Patterns

### Supported Patterns

#### 1. HTTPS Links (Universal/App Links)
```
https://yourcreditunion.com/app/home
https://yourcreditunion.com/app/account/account_123
https://yourcreditunion.com/app/export
https://yourcreditunion.com/app/privacy/connected-apps
```

#### 2. Custom Scheme (Fallback)
```
cubanking://app/home
cubanking://app/account/account_123
cubanking://app/export
```

#### 3. With Query Parameters
```
https://yourcreditunion.com/app/account/123?tab=transactions
cubanking://app/home?notification=new_deposit
```

---

## Testing Deep Links

### iOS Testing

```bash
# Simulator
xcrun simctl openurl booted "cubanking://app/home"
xcrun simctl openurl booted "https://yourcreditunion.com/app/home"

# Device (via Terminal on Mac)
xcrun devicectl device open url --device YOUR_DEVICE_ID "cubanking://app/home"
```

### Android Testing

```bash
# Emulator/Device
adb shell am start -W -a android.intent.action.VIEW -d "cubanking://app/home"
adb shell am start -W -a android.intent.action.VIEW -d "https://yourcreditunion.com/app/home"
```

---

## Next.js Deployment Checklist

### Production Setup

1. ✅ Upload `apple-app-site-association` to `.well-known/`
2. ✅ Upload `assetlinks.json` to `.well-known/`
3. ✅ Ensure both files served with correct Content-Type
4. ✅ Test universal links on real devices
5. ✅ Add analytics to track deep link clicks
6. ✅ Implement fallback to app stores
7. ✅ Add "Open in App" banner for web users

### Vercel Configuration

**File:** `vercel.json`

```json
{
  "headers": [
    {
      "source": "/.well-known/apple-app-site-association",
      "headers": [
        {
          "key": "Content-Type",
          "value": "application/json"
        }
      ]
    },
    {
      "source": "/.well-known/assetlinks.json",
      "headers": [
        {
          "key": "Content-Type",
          "value": "application/json"
        }
      ]
    }
  ]
}
```

---

## Smart Banner (Optional)

Add to Next.js layout for "Open in App" prompts:

```tsx
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <html>
      <head>
        {/* iOS Smart App Banner */}
        <meta
          name="apple-itunes-app"
          content="app-id=YOUR_APP_ID, app-argument=https://yourcreditunion.com/app"
        />

        {/* Android equivalent */}
        <meta
          name="google-play-app"
          content="app-id=com.yourcreditunion.banking"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

---

## Summary

### For Credit Unions
1. Update domains in iOS/Android config with their actual domain
2. Upload `.well-known` files to their website
3. Distribute app through App Store/Play Store
4. Add deep links to their website

### URL Format
```
https://{credit-union-domain}/app/{route}
cubanking://app/{route}
```

### Example Integration
```tsx
<a href="https://mycreditunion.com/app/account/12345">
  View Account in App
</a>
```

---

*Last Updated: 2025-11-07*
*Flutter App Version: 1.0.0*
