# 🛡️ Firebase App Check Setup Guide

You are currently on the **App Check** page. Here is exactly what you need to do to secure your Storage and Firestore.

---

## 🚀 Step 1: Register Your App (The "Apps" Tab)

You don't register "Storage" or "Firestore" individually first. You register your **iOS App** as a trusted entity.

1.  Look at the top of the App Check page. There are two tabs: **APIs** (where you are now) and **Apps**.
2.  Click on the **Apps** tab.
3.  You should see your iOS app (`com.melis.Slipbox` or similar) listed there.
4.  Click on your app to expand its details.
5.  You will see providers like **DeviceCheck**, **App Attest**, and **Debug Token**.

### A. For Development (Simulator)
1.  In the "Debug Token" section, click the **three dots** menu -> **Manage debug tokens**.
2.  Click **Add debug token**.
3.  **Name**: `Simulator` (or similar).
4.  **Value**: You need to get this from Xcode console.
    *   *run your app in Xcode* -> Watch the console logs at the bottom.
    *   Look for a log starting with: `[Firebase/AppCheck][I-FAA001001] Firebase App Check Debug Token:`
    *   Copy that UUID token.
5.  Paste it into the Firebase Console "Value" field and Save.
    *   *Result:* Now your simulator is "trusted" to access Storage/Firestore.

### B. For Production (App Store / TestFlight)
1.  In the **DeviceCheck** section, click **Register**.
2.  Follow the instructions (usually requires your Team ID from Apple Developer account, found at [developer.apple.com](https://developer.apple.com/account)).
    *   *Result:* Real iPhones downloaded from App Store will be trusted.

---

## 🔒 Step 2: Enable Enforcement (The "APIs" Tab)

Now that your app is registered, you tell Firebase to **block** anyone who isn't your app.

1.  Go back to the **APIs** tab (where your screenshot was).
2.  You will see **Storage** and **Cloud Firestore**.
3.  **Initially:** They are in "Unenforced" or "Monitoring" mode. This means it accepts everyone but logs if they are valid.
4.  **To Protect:**
    *   Click on **Cloud Firestore**.
    *   Click **Enforce**.
    *   Click on **Storage**.
    *   Click **Enforce**.

**⚠️ IMPORTANT WARNING:** Do NOT click "Enforce" until you have successfully registered your app (Step 1) and confirmed it works. If you enforce too early, your own app might get blocked if the setup isn't perfect.
*Recommendation:* Leave them in "Monitoring" mode for a day while you develop. If you see "100% Verified Requests" in the chart, THEN click Enforce.

---

## Summary Checklist
- [ ] Go to **Apps** tab.
- [ ] Add **Debug Token** from Xcode (for Simulator).
- [ ] Enable **DeviceCheck** (for Real Devices).
- [ ] Go to **APIs** tab.
- [ ] Monitor traffic.
- [ ] **Enforce** only when ready.
