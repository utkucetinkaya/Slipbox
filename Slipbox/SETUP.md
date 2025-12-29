# SlipBox - Setup Guide

## Prerequisites

- **macOS** with Xcode 15.0+
- **Apple Developer Account** (for app signing and StoreKit testing)
- **Firebase Account** (free tier works for development)
- **Node.js 18+** (for Cloud Functions)

---

## Step 1: Firebase Console Setup

### 1.1 Create Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Name: `FisKutusuAI` (or your preferred name)
4. Disable Google Analytics (optional for MVP)

### 1.2 Enable Authentication
1. Go to **Authentication** → **Sign-in method**
2. Enable **Apple** (requires Apple Developer account setup)
   - Team ID: From Apple Developer account
   - Key ID & Private Key: Create in Apple Developer → Certificates, IDs & Profiles → Keys
3. Enable **Email/Password**

### 1.3 Create Firestore Database
1. Go to **Firestore Database** → **Create database**
2. Choose **Start in production mode** (we'll deploy custom rules)
3. Select region (e.g., `europe-west1` for Europe)

### 1.4 Create Storage Bucket
1. Go to **Storage** → **Get started**
2. Use **default bucket**

### 1.5 Upgrade to Blaze Plan
1. Go to **Upgrade** (required for Cloud Functions)
2. Add billing information
3. Set budget alerts

### 1.6 Enable App Check
1. Go to **App Check** → **Get started**
2. Register iOS app (Bundle ID: `com.yourcompany.slipbox`)
3. Enable **DeviceCheck** provider

---

## Step 2: iOS App Setup

### 2.1 Download Firebase Config
1. In Firebase Console, go to **Project Settings**
2. Add iOS app if not already added
3. Download `GoogleService-Info.plist`
4. Place in `FisKutusuAI/FisKutusuAI/Resources/`

### 2.2 Create Xcode Project
Since we don't have Xcode project files yet (code only), you need to:

1. Open Xcode → **Create a new Xcode project**
2. Choose **iOS** → **App**
3. Product Name: `FisKutusuAI`
4. Organization Identifier: `com.yourcompany`
5. Interface: **SwiftUI**
6. Language: **Swift**
7. Save to `Desktop/iosappidea/FisKutusuAI/`

### 2.3 Add Source Files
1. In Xcode, drag and drop folders:
   - `App/`
   - `Views/`
   - `Models/`
   - `Services/`
   - `Utilities/`
   - `Resources/` (with `GoogleService-Info.plist`)

2. Add to target when prompted

### 2.4 Add Firebase Dependencies
1. In Xcode: **File** → **Add Package Dependencies**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Version: **10.0.0** or later
4. Select packages:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics
   - FirebaseCrashlytics
   - FirebaseAppCheck

### 2.5 Configure Info.plist
Add camera permissions:
```xml
<key>NSCameraUsageDescription</key>
<string>Fiş fotoğrafı çekmek için kamera erişimi gereklidir</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Fiş resimlerini seçmek için foto kütüphanesi erişimi gereklidir</string>
```

### 2.6 Enable Signing
1. Select project in navigator → **Signing & Capabilities**
2. Check **Automatically manage signing**
3. Select your **Team**

---

## Step 3: Firebase Backend Deployment

### 3.1 Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 3.2 Initialize Project
```bash
cd Desktop/iosappidea/firebase-backend
firebase use --add
# Select your Firebase project
```

### 3.3 Install Dependencies
```bash
cd functions
npm install
```

### 3.4 Configure Environment Variables
Create `functions/.env`:
```bash
OPENAI_API_KEY=your_openai_key  # Or use Google Gemini
```

For production, set via Firebase CLI:
```bash
firebase functions:config:set openai.key="your_openai_key"
```

### 3.5 Deploy
```bash
cd ..  # Back to firebase-backend directory

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Hosting
firebase deploy --only hosting
```

---

## Step 4: StoreKit Configuration

### 4.1 Create In-App Purchases
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create app in **My Apps** if not exists
3. Go to **Features** → **In-App Purchases**
4. Create **Auto-Renewable Subscription**:
   - Subscription Group: `Pro Subscription`
   - Products:
     - `slipbox_pro_monthly` (1 Month, 49.99 TRY)
     - `slipbox_pro_yearly` (1 Year, 499.99 TRY - 17% discount)

### 4.2 Create StoreKit Configuration File
1. In Xcode: **File** → **New** → **File**
2. Choose **StoreKit Configuration File**
3. Add subscriptions matching App Store Connect
4. Use for local testing

### 4.3 Configure Server Notifications
1. In App Store Connect → **App Information** → **App Store Server Notifications**
2. Set webhook URL: `https://YOUR_PROJECT.cloudfunctions.net/appleServerNotification`
3. Version: **V2**

---

## Step 5: Testing

### 5.1 Local Development
1. Run app in Simulator
2. Test authentication flow
3. Use mock data for receipts

### 5.2 Device Testing
1. Connect iOS device (iOS 17+)
2. Enable **Developer Mode** on device
3. Run from Xcode
4. Test camera capture

### 5.3 Subscription Testing
1. Create sandbox Apple ID
2. In app, test purchase flow
3. Verify entitlements update in Firestore

### 5.4 Backend Testing
```bash
# Use Firebase Emulators for local development
firebase emulators:start
```

---

## Step 6: Production Deployment

### 6.1 App Store Submission
1. Create **App Store Icons** (1024x1024)
2. Take **Screenshots** (6.5" required)
3. Fill **App Privacy** details
4. Submit for review

### 6.2 Configure Custom Domain (Optional)
1. In Firebase Hosting → **Custom domain**
2. Add your domain
3. Update share link URL in `shareLinks.ts`

---

## Troubleshooting

### "GoogleService-Info.plist not found"
- Make sure file is in `Resources/` and added to target

### "App Check tokens failing"
- In development, use Debug provider
- In production, ensure DeviceCheck is properly configured

### "Cloud Functions timeout"
- Increase timeout in `firebase.json`:
  ```json
  "functions": [{
    "timeoutSeconds": 540,
    "memory": "1GB"
  }]
  ```

### "Receipt processing not triggering"
- Check Storage trigger is deployed
- Verify file path: `receipts/{uid}/{receiptId}.jpg`

---

## Next Steps

After setup:
1. Implement UI for inbox, capture, and reports
2. Integrate real OCR (Vision framework)
3. Add OpenAI/Gemini for category suggestion
4. Implement PDF generation (pdfkit)
5. Add analytics events
6. Test end-to-end flows

---

## Support

For issues:
- Check Firebase Console logs
- Check Xcode console
- Review Firestore rules debugger
