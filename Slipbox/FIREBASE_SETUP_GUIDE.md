# SlipBox - Firebase Kurulum Rehberi (Sıfırdan)

Bu rehber SlipBox uygulamasını sıfırdan Firebase'e bağlamak için gereken tüm adımları içerir.

---

## Ön Hazırlık

### Gereksinimler
- [ ] Google hesabı
- [ ] Node.js (v18+) ve npm yüklü
- [ ] Firebase CLI yüklü: `npm install -g firebase-tools`
- [ ] Xcode (15+) yüklü
- [ ] Apple Developer hesabı (Apple Sign-In için)

---

## Adım 1: Firebase Projesi Oluştur

### 1.1 Firebase Console'a Git
1. https://console.firebase.google.com/ adresine git
2. Google hesabınla giriş yap
3. **"Add project"** butonuna tıkla

### 1.2 Proje Ayarları
```
Project name: slipbox-dev (geliştirme için)
Project ID: slipbox-dev-xxxxx (otomatik oluşturulur)
```

**Önemli:** Production için ayrı bir proje oluşturmanı öneririm:
- Dev: `slipbox-dev`
- Prod: `slipbox-prod`

### 1.3 Google Analytics
- **Enable Google Analytics:** Evet seç
- **Analytics account:** Yeni hesap oluştur veya mevcut hesap seç
- **Create project** tıkla (30-60 saniye sürer)

---

## Adım 2: iOS Uygulaması Ekle

### 2.1 iOS App Kaydı
1. Firebase Console'da projeye tıkla
2. **"Add app"** → **iOS** seç
3. **Apple bundle ID:** `com.yourcompany.slipbox` 
   - ⚠️ Bu Bundle ID'yi Xcode'da da aynı şekilde kullanacaksın
4. **App nickname (optional):** "SlipBox iOS"
5. **App Store ID:** Boş bırak (henüz yok)
6. **Register app** tıkla

### 2.2 GoogleService-Info.plist İndir
1. **Download GoogleService-Info.plist** dosyasını indir
2. Bu dosyayı şuraya kaydet:
   ```
   c:\Users\Melis\Desktop\iosappidea\FisKutusuAI\FisKutusuAI\GoogleService-Info.plist
   ```
3. **Xcode'da:**
   - Xcode'u aç (eğer henüz proje oluşturmadıysan, şimdi oluştur)
   - `GoogleService-Info.plist` dosyasını Xcode projesine sürükle
   - ✅ **"Copy items if needed"** seçeneğini işaretle
   - ✅ **"Add to targets: FisKutusuAI"** seçeneğini işaretle

### 2.3 Xcode Bundle ID Ayarla
1. Xcode'da projeyi aç
2. Project Navigator → **FisKutusuAI** (mavi ikon)
3. **TARGETS** → **FisKutusuAI** seç
4. **General** tab → **Bundle Identifier:**
   ```
   com.yourcompany.slipbox
   ```
5. ⚠️ Bu `GoogleService-Info.plist` içindeki `BUNDLE_ID` ile aynı olmalı!

---

## Adım 3: Firebase Authentication Kurulumu

### 3.1 Authentication Etkinleştir
1. Firebase Console → **Build** → **Authentication**
2. **Get started** tıkla
3. **Sign-in method** tab'ına geç

### 3.2 Email/Password Provider
1. **Email/Password** satırına tıkla
2. **Enable** toggle'ı aç
3. **Save** tıkla

### 3.3 Apple Sign-In Provider
1. **Apple** satırına tıkla
2. **Enable** toggle'ı aç
3. ⚠️ **Apple Developer Console'dan gerekli bilgiler:**
   - Services ID oluşturman gerekecek (Apple Developer → Certificates, Identifiers & Profiles)
   - Detaylı adımlar: https://firebase.google.com/docs/auth/ios/apple
4. Şimdilik **Save** ile geç (daha sonra yapılandıracağız)

---

## Adım 4: Firestore Database Kurulumu

### 4.1 Firestore Oluştur
1. Firebase Console → **Build** → **Firestore Database**
2. **Create database** tıkla
3. **Production mode** seç (güvenlik kuralları ile başla)
4. **Location:** `eur3 (europe-west)` seç (Türkiye'ye en yakın)
5. **Enable** tıkla

### 4.2 Güvenlik Kurallarını Dağıt
Artık güvenlik kurallarını Firebase Console'dan değil, yerel `firestore.rules` dosyasından yöneteceksin.

**Şimdilik varsayılan kuralları bırak**, Adım 7'de yerel dosyalardan dağıtacağız.

---

## Adım 5: Cloud Storage Kurulumu

### 5.1 Storage Oluştur
1. Firebase Console → **Build** → **Storage**
2. **Get started** tıkla
3. **Production mode** seç
4. **Location:** `eur3 (europe-west)` (Firestore ile aynı)
5. **Done** tıkla

### 5.2 Bucket Adını Not Al
```
gs://slipbox-dev-xxxxx.appspot.com
```
Bu bucket adını `storage.rules` dosyasında kullanacaksın.

---

## Adım 6: Firebase CLI ile Giriş

### 6.1 Terminal Aç
PowerShell'i yönetici olarak aç:
```powershell
cd c:\Users\Melis\Desktop\iosappidea\firebase-backend
```

### 6.2 Firebase'e Giriş Yap
```bash
firebase login
```
- Tarayıcı açılır, Google hesabınla giriş yap
- İzin ver
- Terminal'e "Success!" mesajı gelir

### 6.3 Projeyi Bağla
```bash
firebase use --add
```
- Liste gelince **"slipbox-dev"** seç (yukarı/aşağı ok tuşları ile)
- Alias sor: **"dev"** yaz
- Enter

**Doğrulama:**
```bash
firebase projects:list
```
Projen listede gözükmeli.

---

## Adım 7: Cloud Functions Dağıtımı

### 7.1 Cloud Functions Enable Et
1. Firebase Console → **Build** → **Functions**
2. **Get started** tıkla
3. Fiyatlandırma planını yükselt:
   - **Upgrade** tıkla → **Blaze (Pay as you go)** seç
   - Kredi kartı ekle (küçük projeler için $0-5/ay)

### 7.2 Functions Build Et
```bash
cd c:\Users\Melis\Desktop\iosappidea\firebase-backend\functions
npm run build
```

**Çıktı:** `lib/` klasörü oluşmalı, 0 hata olmalı.

### 7.3 Functions Dağıt
```bash
firebase deploy --only functions
```

**İlk dağıtım 5-10 dakika sürebilir.**

Başarılı olursa:
```
✔  functions: Finished running predeploy script.
✔  functions[initializeUser(us-central1)]: Successful create operation.
✔  functions[deleteUserData(us-central1)]: Successful create operation.
✔  functions[processReceipt(us-central1)]: Successful create operation.
✔  functions[generateExport(us-central1)]: Successful create operation.
✔  functions[createShareLink(us-central1)]: Successful create operation.
✔  functions[viewSharedExport(us-central1)]: Successful create operation.
✔  functions[validatePurchase(us-central1)]: Successful create operation.
✔  functions[appleServerNotification(us-central1)]: Successful create operation.
✔  functions[createReceiptUploadSession(us-central1)]: Successful create operation.
```

---

## Adım 8: Firestore & Storage Rules Dağıtımı

### 8.1 Rules Dosyalarını Kontrol Et
```bash
cd c:\Users\Melis\Desktop\iosappidea\firebase-backend
```

Şu dosyalar mevcut olmalı:
- `firestore.rules`
- `storage.rules`

### 8.2 Rules Dağıt
```bash
firebase deploy --only firestore:rules,storage:rules
```

Başarılı olursa:
```
✔  firestore: rules file firestore.rules compiled successfully
✔  storage: rules file storage.rules compiled successfully
```

### 8.3 Firebase Console'dan Doğrula
1. **Firestore Database → Rules**
2. Son deploy zamanını kontrol et (şimdi olmalı)

---

## Adım 9: Firebase Hosting (Opsiyonel ama Önerilen)

Share link özelliği için hosting gerekli.

### 9.1 Hosting Dağıt
```bash
firebase deploy --only hosting
```

### 9.2 Domain URL'i Not Al
```
https://slipbox-dev-xxxxx.web.app
```

Bu URL `shareLinks.ts` içinde kullanılıyor:
```typescript
const baseUrl = functions.config().app?.url || "https://slipbox.web.app";
```

⚠️ **Önemli:** Production'da bu URL'i environment variable olarak set etmelisin:
```bash
firebase functions:config:set app.url="https://slipbox.web.app"
firebase deploy --only functions
```

---

## Adım 10: App Check Kurulumu (Güvenlik)

### 10.1 App Check Etkinleştir
1. Firebase Console → **Build** → **App Check**
2. **Get started** tıkla
3. **Register app** → **iOS** seç

### 10.2 DeviceCheck Provider (Production)
1. **Apple DeviceCheck** seç
2. Apple Developer hesabınla bağlan
3. **Register** tıkla

**⚠️ Şimdilik geçebilirsin**, geliştirme için Debug Token kullanacağız.

### 10.3 Debug Token (Development)
iOS'ta App Check debug token kullanmak için `AppDelegate.swift` içinde:

```swift
#if DEBUG
let providerFactory = AppCheckDebugProviderFactory()
#else
let providerFactory = DeviceCheckProviderFactory()
#endif
AppCheck.appCheck().setAppCheckProviderFactory(providerFactory)
```

**Test ederken Xcode console'da şöyle bir log göreceksin:**
```
Firebase App Check Debug Token: XXXXX-XXXX-XXXX-XXXX
```

Bu token'ı Firebase Console → App Check → Apps → Debug Tokens'a ekle.

---

## Adım 11: Xcode'da Firebase SDK Ekle

### 11.1 Yeni Xcode Projesi Oluştur (Eğer yoksa)
1. Xcode aç → **Create New Project**
2. **iOS** → **App** seç
3. **Product Name:** SlipBox
4. **Bundle Identifier:** `com.yourcompany.slipbox`
5. **Interface:** SwiftUI
6. **Language:** Swift
7. **Kaydet:** `c:\Users\Melis\Desktop\iosappidea\FisKutusuAI`

### 11.2 Swift Package Manager ile Firebase SDK
1. Xcode → **File** → **Add Package Dependencies**
2. URL gir:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. **Dependency Rule:** Up to Next Major Version (`11.0.0`)
4. **Add Package** tıkla
5. **Paketleri seç:**
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseStorage
   - ✅ FirebaseFunctions
   - ✅ FirebaseAnalytics
   - ✅ FirebaseCrashlytics
   - ✅ FirebaseAppCheck
6. **Add Package** tıkla (birkaç dakika sürer)

### 11.3 Swift Dosyalarını Projeye Ekle
Şu klasörlerdeki tüm `.swift` dosyalarını Xcode'a sürükle:
```
c:\Users\Melis\Desktop\iosappidea\FisKutusuAI\FisKutusuAI\
├── App/
├── Models/
├── Views/
├── Services/
├── Repositories/
├── Utilities/
```

**Xcode'da:**
- ✅ **"Copy items if needed"** seçeneğini işaretle
- ✅ **"Create groups"** seç
- ✅ **"Add to targets: FisKutusuAI"** seç

---

## Adım 12: İlk Test (Simulator)

### 12.1 Build & Run
1. Xcode'da **Product** → **Run** (veya Cmd+R)
2. Simulator seç (iPhone 15 Pro)
3. Wait for build...

### 12.2 Beklenen Davranış
1. **WelcomeView** açılır (kimlik doğrulama ekranı)
2. **"Sign in with Email"** tıkla
3. Email/şifre gir (yeni hesap oluştur)
4. ✅ **initializeUser** Cloud Function çağrılır
5. ✅ Firestore'da `users/{uid}` dokümanı oluşur
6. ✅ `entitlements/{uid}` dokümanı oluşur (Free tier, 0 receipt)
7. **MainTabView** açılır

### 12.3 Firestore Console'da Kontrol
1. Firebase Console → **Firestore Database**
2. **users** koleksiyonu → UID ile doküman var mı?
3. **entitlements** koleksiyonu → UID ile doküman var mı?

---

## Adım 13: Fiş Yükleme Testi

### 13.1 Camera Access İzni (Info.plist)
Xcode'da `Info.plist` dosyasına ekle:
```xml
<key>NSCameraUsageDescription</key>
<string>SlipBox fişlerinizi taramak için kameraya erişmek istiyor</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>SlipBox galeriden fiş seçmenize izin vermek istiyor</string>
```

### 13.2 Simulator'da Test
1. **Inbox** tab → "+" butonu tıkla
2. Galeri açılır (simulator'da)
3. Bir fiş fotoğrafı seç
4. **Kullan** tıkla

**Beklenen:**
1. ✅ `createReceiptUploadSession` Cloud Function çağrılır → limit check
2. ✅ OCR çalışır, metin çıkarır
3. ✅ Firestore'a receipt stub oluşur (status: processing)
4. ✅ Storage'a görsel upload olur (`receipts/{uid}/{receiptId}.jpg`)
5. ✅ `processReceipt` Cloud Function tetiklenir
6. ✅ Receipt güncellenir (status: needsReview veya approved)
7. ✅ Real-time listener UI'yi günceller

### 13.3 Firebase Console'da Kontrol
1. **Firestore → users/{uid}/receipts** → Yeni receipt var mı?
2. **Storage → receipts/{uid}/** → Görsel upload oldu mu?
3. **Functions logs** → `processReceipt` çalıştı mı?

---

## Adım 14: App Store Connect Kurulumu (İleride)

### 14.1 App Store Connect'te App Oluştur
1. https://appstoreconnect.apple.com/
2. **My Apps** → "+" → **New App**
3. **Platform:** iOS
4. **Name:** SlipBox
5. **Primary Language:** Turkish
6. **Bundle ID:** `com.yourcompany.slipbox` (dropdown'dan seç)
7. **SKU:** `slipbox-ios-001`

### 14.2 In-App Purchase (StoreKit)
1. **Features** → **In-App Purchases**
2. **Create** → **Auto-Renewable Subscription**
3. **Reference Name:** SlipBox Pro Monthly
4. **Product ID:** `slipbox_pro_monthly`
5. **Subscription Group:** Pro Subscription
6. **Price:** 49.99 TRY / month

Aynı şekilde yearly için:
- **Product ID:** `slipbox_pro_yearly`
- **Price:** 499.99 TRY / year

---

## Adım 15: Environment Variables (Production vs Dev)

### 15.1 Firebase Config
Development ve Production için farklı projeler kullan:

**Development:**
```bash
firebase use dev
firebase deploy
```

**Production:**
```bash
firebase use prod
firebase deploy
```

### 15.2 iOS Build Configurations
Xcode'da **Schemes** ile Dev/Prod ayır:
- **SlipBox (Dev)** → `GoogleService-Info-Dev.plist`
- **SlipBox (Prod)** → `GoogleService-Info-Prod.plist`

---

## Sorun Giderme

### Problem: "Firebase SDK not found"
**Çözüm:** Xcode → **File** → **Packages** → **Resolve Package Versions**

### Problem: "GoogleService-Info.plist not found"
**Çözüm:** 
1. Dosyanın Xcode projesinde olduğundan emin ol
2. Target membership kontrol et (sağ panel)

### Problem: "App Check token missing"
**Çözüm:**
1. Debug token kullan (geliştirme için)
2. Xcode console'dan token'ı kopyala
3. Firebase Console → App Check → Debug Tokens'a ekle

### Problem: "Cloud Function permission denied"
**Çözüm:**
1. Authentication aktif mi?
2. Firestore rules doğru mu?
3. App Check token geçerli mi?

### Problem: npm install hataları (Windows)
**Çözüm:** `INSTALL_FIX.md` dosyasına bak:
```bash
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## Checklist - Kurulum Tamamlandı mı?

- [ ] Firebase projesi oluşturuldu
- [ ] iOS app Firebase'e eklendi
- [ ] `GoogleService-Info.plist` Xcode'da
- [ ] Authentication (Email + Apple) aktif
- [ ] Firestore database oluşturuldu
- [ ] Cloud Storage oluşturuldu
- [ ] Firebase CLI giriş yaptı
- [ ] Cloud Functions dağıtıldı (9 function)
- [ ] Firestore rules dağıtıldı
- [ ] Storage rules dağıtıldı
- [ ] Hosting dağıtıldı (share links için)
- [ ] App Check kuruldu (debug token)
- [ ] Firebase SDK Xcode'a eklendi
- [ ] Test kullanıcı oluşturuldu
- [ ] İlk fiş upload testi başarılı

---

## Sonraki Adımlar

1. **StoreKit Configuration File Oluştur** (sandbox test için)
2. **TestFlight'a Upload** (beta test)
3. **Production Firebase Projesi Kur** (ayrı)
4. **Custom Domain Ekle** (slipbox.app)
5. **App Store Submit** 

---

**Hazırsın!** 🚀

Sorular için:
- Firebase Docs: https://firebase.google.com/docs/ios/setup
- GitHub Issues: Proje repo'sunda issue aç
