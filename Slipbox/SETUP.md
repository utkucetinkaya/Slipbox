# 🔥 Firebase Connection Guide (FisKutusuAI)

**Current Status:** The app code is fully configured for Firebase (`AppDelegate.swift` handles initialization). You just need to connect the project in the Firebase Console and add the configuration file.

---

## 🚀 Step 1: Create Firebase Project

1.  Go to [Firebase Console](https://console.firebase.google.com/).
2.  Click **Create a project**.
3.  Name it: `FisKutusuAI` (or `SlipBox`).
4.  Disable Google Analytics (optional, enables faster setup).
5.  Click **Create Project**.

---

## 📱 Step 2: Register iOS App

1.  Click the **iOS icon ()** to add an app.
2.  **Bundle ID**: You must find the exact Bundle ID from Xcode.
    *   *How to find:* Open Xcode -> Click project root (blue icon) -> Click "Signing & Capabilities" tab -> Look at **Bundle Identifier**.
    *   *Likely:* `com.melis.Slipbox` (check your specific ID). Paste that exactly.
3.  **App Nickname**: `FisKutusuAI`
4.  Click **Register app**.

---

## 📥 Step 3: Add Config File (Crucial Step)

1.  Download **`GoogleService-Info.plist`** from the Firebase setup screen.
2.  **Move the file**: Drag and drop this file into your project folder:
    *   **Path**: `Slipbox/FisKutusuAI/FisKutusuAI/Resources/`
    *   *(If the `Resources` folder is empty, just drag it there)*.
3.  **Add to Xcode**:
    *   Open Xcode.
    *   Right-click on the `FisKutusuAI` folder in the project navigator (left side).
    *   Select **"Add Files to 'FisKutusuAI'..."**.
    *   Select the `GoogleService-Info.plist` you just moved.
    *   **IMPORTANT**: Ensure **"Copy items if needed"** is CHECKED and your app target is SELECTED.

---

## 🔐 Step 4: Enable Authentication

Your app uses Email and Apple Sign-In. You must enable these in Firebase:

1.  Go to **Build** -> **Authentication** in Firebase Console.
2.  Click **Get Started**.
3.  **Sign-in method** tab:
    *   Enable **Email/Password**.
    *   Enable **Apple**. (Leave "Service ID" blank/default for now if testing on Simulator, or configure with Apple Developer account for real device).
    *   *(Optional)* Enable **Anonymous** if you want guest access.

---

## 🗄️ Step 5: Setup Database (Firestore)

1.  Go to **Build** -> **Firestore Database**.
2.  Click **Create database**.
3.  Select **Start in test mode** (easier for development now; switch to production rules later).
    *   *Note: Test mode allows open access for 30 days.*
4.  Select a location close to you (e.g., `eur3` or `us-central1`).

---

## 🛡️ Step 6: Setup App Check (Optional but Recommended)

Your app code enables App Check (`AppCheckDebugProviderFactory`). To avoid errors in the console:

1.  Go to **Build** -> **App Check**.
2.  Click **Get Started**.
3.  Register your iOS app by clicking on it.
4.  Allows you to use the "Debug Token" printed in the Xcode console for local testing.

---

## ✅ Step 7: Run & Verify

1.  In Xcode, press **Cmd+R** to run.
2.  Watch the Debug Console (bottom right).
3.  You should see logs like:
    *   `[Firebase/Core] Device Model: ...`
    *   `FirebaseApp.configure() successful` (implied by no crash).
4.  Try creating an account in the app!
