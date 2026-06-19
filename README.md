# Hire Direct — Work Direct
### A two-sided service marketplace built with Flutter + Firebase + Stripe

---

## 📱 What This App Does

**Hire Direct** connects Clients (homeowners, businesses) with Workers (skilled tradespeople, freelancers) for local service jobs.

**Key features:**
- Two account types: Client and Worker
- Job posting with multi-photo upload
- Escrow payment protection via Stripe
- $20 commitment fee / no-show protection
- Real-time bilingual chat (English ↔ Spanish)
- Add-on work requests and approval flow
- Status tracking: Posted → Booked → In Progress → Awaiting Confirmation → Completed → Payment Released
- Worker profiles with portfolio, availability calendar, and reviews
- Search & filter jobs by category, budget, location
- Google Play Store deployment ready

---

## 🚀 Quick Setup (Do These In Order)

### Step 1 — Prerequisites
```bash
# Install Flutter (https://flutter.dev/docs/get-started/install)
flutter --version  # Should be 3.x+

# Install Node.js (for Firebase Functions)
node --version  # Should be 18+
```

### Step 2 — Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → Name it `hire-direct`
3. Enable Google Analytics (optional)
4. In the left sidebar, enable these services:
   - **Authentication** → Sign-in method → Enable **Email/Password**
   - **Firestore Database** → Create database → Start in **production mode**
   - **Storage** → Get started
   - **Cloud Messaging** (for push notifications)

### Step 3 — Connect Flutter to Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# In the project root:
cd hire_direct
flutterfire configure --project=hire-direct

# This generates lib/firebase_options.dart with your real credentials
```

### Step 4 — Deploy Firestore Security Rules
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# In the project root:
firebase deploy --only firestore:rules
```

### Step 5 — Set Up Stripe
1. Go to [dashboard.stripe.com](https://dashboard.stripe.com) → Create account
2. Get your **Publishable Key** and **Secret Key** from the Dashboard
3. Update `lib/core/constants/app_constants.dart`:
   ```dart
   static const String stripePublishableKey = 'pk_live_YOUR_KEY_HERE';
   ```

### Step 6 — Deploy Firebase Cloud Functions (Stripe Backend)
```bash
cd functions
npm install

# Set Stripe secret key as Firebase config
firebase functions:config:set stripe.secret_key="sk_live_YOUR_SECRET_KEY"

# Deploy functions
firebase deploy --only functions

# Copy the function URL (shown after deploy) and update:
# lib/data/services/payment_service.dart → _cloudFunctionUrl
```

### Step 7 — Google Translate API Key
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable the **Cloud Translation API**
3. Create an API key
4. Update `lib/core/constants/app_constants.dart`:
   ```dart
   static const String googleTranslateApiKey = 'YOUR_KEY_HERE';
   ```

### Step 8 — Google Maps API Key (for location features)
1. In Google Cloud Console → Enable **Maps SDK for Android**
2. Create an API key
3. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_MAPS_API_KEY"/>
   ```

### Step 9 — Run the App
```bash
cd hire_direct
flutter pub get
flutter run
```

---

## 🏪 Google Play Store Deployment

### 1. Create a Keystore
```bash
keytool -genkey -v -keystore ~/hire-direct-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias hire-direct
```

### 2. Configure Signing in android/key.properties
```
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=hire-direct
storeFile=/path/to/hire-direct-release.jks
```

### 3. Build Release APK / AAB
```bash
# App Bundle (recommended for Play Store)
flutter build appbundle --release

# APK (for direct distribution)
flutter build apk --release --split-per-abi
```

### 4. Upload to Play Console
1. Go to [play.google.com/console](https://play.google.com/console)
2. Create app → Upload AAB from `build/app/outputs/bundle/release/`
3. Fill in store listing, screenshots, content rating
4. Submit for review

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/    # App constants, colors, categories
│   ├── theme/        # Material theme, colors
│   └── utils/        # Router (go_router)
├── data/
│   ├── models/       # UserModel, JobModel, BookingModel, etc.
│   └── services/     # AuthService, JobService, ChatService,
│                     # PaymentService, ReviewService
├── providers/        # Riverpod providers (app state)
├── presentation/
│   └── screens/
│       ├── auth/     # Splash, Onboarding, SignUp, Login
│       ├── client/   # Dashboard, PostJob, ReviewJob, ActiveJobs
│       ├── worker/   # Dashboard, BrowseJobs, Earnings
│       └── shared/   # JobDetails, Booking, Payment, ActiveJob,
│                     # Chat, WorkerProfile, Search, Reviews,
│                     # Profile, AddOn, Gallery
└── main.dart
```

---

## 💳 Payment Flow

```
Worker books job
       ↓
Worker pays $20 commitment fee (Stripe)
       ↓
Client notified (Firebase FCM)
       ↓
Client posts job with Escrow selected
       ↓
Client pays job amount → held in Stripe
       ↓
Job progresses through status stages
       ↓
Worker marks complete
       ↓
Client confirms + releases payment
       ↓
Stripe transfers to worker's account
```

---

## 🌎 Bilingual Chat Flow

```
Worker (Spanish) types: "Puedo llegar a las 3pm."
        ↓
Saved to Firestore with originalText + originalLanguage: "es"
        ↓
Client (English) opens chat
        ↓
App calls Google Translate API: "Puedo llegar a las 3pm." → "I can arrive at 3pm."
        ↓
Client sees translated text + "View Original" link
        ↓
Tap "View Original" → shows "Puedo llegar a las 3pm."
```

---

## ⚙️ Configuration Checklist

| Item | File | Status |
|------|------|--------|
| Firebase (run flutterfire configure) | `lib/firebase_options.dart` | ⚠️ Required |
| Stripe Publishable Key | `lib/core/constants/app_constants.dart` | ⚠️ Required |
| Stripe Secret Key (Cloud Function) | Firebase config | ⚠️ Required |
| Cloud Function URL | `lib/data/services/payment_service.dart` | ⚠️ Required |
| Google Translate API Key | `lib/core/constants/app_constants.dart` | ⚠️ Required |
| Google Maps API Key | `android/app/src/main/AndroidManifest.xml` | Optional |
| App bundle ID | `android/app/build.gradle` | `com.hiredirect.app` |

---

## 📞 Support

For setup help, contact your development team or refer to:
- Flutter docs: https://flutter.dev/docs
- Firebase docs: https://firebase.google.com/docs
- Stripe docs: https://stripe.com/docs
- go_router: https://pub.dev/packages/go_router
- flutter_riverpod: https://riverpod.dev
