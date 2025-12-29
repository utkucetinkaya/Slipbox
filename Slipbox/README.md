# SlipBox - iOS Expense Tracker

A SwiftUI iOS application for receipt scanning, expense tracking, and automated categorization with AI.

## Project Structure

```
FisKutusuAI/
├── FisKutusuAI/
│   ├── App/
│   │   ├── FisKutusuAIApp.swift          # Main app entry point
│   │   └── AppDelegate.swift             # App lifecycle & Firebase setup
│   ├── Views/
│   │   ├── Auth/                         # Authentication screens
│   │   ├── Onboarding/                   # Onboarding flow
│   │   ├── Capture/                      # Receipt capture
│   │   ├── Inbox/                        # Receipt management
│   │   ├── Reports/                      # Export & sharing
│   │   ├── Paywall/                      # Subscription screens
│   │   └── Settings/                     # Settings & profile
│   ├── Models/                           # Data models
│   ├── Services/                         # Business logic & Firebase
│   ├── Utilities/                        # Helpers & extensions
│   └── Resources/
│       ├── GoogleService-Info.plist
│       └── Assets.xcassets
└── FisKutusuAI.xcodeproj

firebase-backend/
├── functions/
│   ├── src/
│   │   ├── index.ts                      # Function exports
│   │   ├── receiptProcessor.ts           # OCR & categorization
│   │   ├── categoryAI.ts                 # LLM integration
│   │   ├── exportGenerator.ts            # PDF/CSV generation
│   │   ├── shareLinks.ts                 # Share link system
│   │   ├── subscriptions.ts              # StoreKit validation
│   │   ├── userManagement.ts             # User lifecycle
│   │   └── middleware/
│   │       ├── appCheck.ts               # App Check validation
│   │       └── rateLimiter.ts            # Rate limiting
│   ├── package.json
│   └── tsconfig.json
├── firestore.rules
├── storage.rules
└── firebase.json
```

## Requirements

### iOS Development
- Xcode 15.0+
- iOS 17.0+ target
- Swift 5.9+
- Firebase iOS SDK 10.0+

### Firebase Backend
- Node.js 18+
- Firebase CLI
- Firebase project with Blaze plan (for Functions)

## Setup Instructions

### 1. Firebase Console Setup
1. Create a new Firebase project at https://console.firebase.google.com
2. Enable Authentication (Apple, Email/Password)
3. Create Firestore database (production mode → will use custom rules)
4. Create Storage bucket
5. Enable App Check with DeviceCheck provider
6. Upgrade to Blaze plan (required for Cloud Functions)

### 2. iOS App Setup
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `FisKutusuAI/Resources/`
3. Open `FisKutusuAI.xcodeproj` in Xcode
4. Update Bundle Identifier to your unique ID
5. Add Signing capabilities (Apple Developer account required)

### 3. Firebase Backend Setup
```bash
cd firebase-backend
npm install
firebase login
firebase use --add  # Select your Firebase project
firebase deploy --only firestore:rules,storage:rules,functions
```

### 4. App Store Connect Setup (for production)
1. Create app in App Store Connect
2. Create In-App Purchase subscriptions:
   - `slipbox_pro_monthly`
   - `slipbox_pro_yearly`
3. Configure StoreKit Configuration file for local testing

## Environment Variables

### Firebase Functions (.env file)
```bash
OPENAI_API_KEY=your_openai_key  # Or use Google Gemini
APPLE_SHARED_SECRET=your_app_store_connect_shared_secret
```

## Security Features

- ✅ Server-only entitlements (client cannot modify subscription status)
- ✅ StoreKit transaction validation via Cloud Functions
- ✅ Firestore rules with whitelist-based user updates
- ✅ Signed URLs for file downloads (15-min expiry)
- ✅ App Check enforcement on all Cloud Functions
- ✅ Rate limiting on expensive operations
- ✅ Transaction ID mapping for server notifications

## Development Workflow

1. **Local iOS Development**: Run app in Simulator with mock data
2. **Firebase Emulators** (recommended): `firebase emulators:start`
3. **Deploy Functions**: `firebase deploy --only functions`
4. **Test on Device**: Build to physical device for camera testing

## License

Proprietary - All rights reserved
