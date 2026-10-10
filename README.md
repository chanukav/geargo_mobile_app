# Geargo

Geargo is a Flutter application connected to the `geargo-e0035` Firebase
project on Android. Firebase Authentication uses email and password.

## Android setup

The Android app is registered in Firebase as `com.example.geargo`, matching
`applicationId` in `android/app/build.gradle.kts`. Its Firebase configuration
is `android/app/google-services.json`; the Google Services Gradle plugin is
already configured. Keep the application ID in sync with the registered
Android app if you change it.

In the Firebase Console, open **Authentication > Sign-in method** and enable
**Email/Password**. The app initializes Firebase before starting and routes
users between sign-in/account creation and the signed-in screen based on the
Firebase Authentication state.

## Other platforms

The checked-in Firebase configuration covers Android, Web, and Windows platforms:
- Configured via `lib/firebase_options.dart` using `DefaultFirebaseOptions.currentPlatform`.
- Includes Supabase storage integration for equipment image assets.

## Run & Verification

```sh
# Fetch dependencies
flutter pub get

# Run on Android Emulator or Chrome
flutter run

# Run static analysis
flutter analyze

# Run complete test suite (unit and widget tests)
flutter test

# Build production release APK
flutter build apk --release
```

---

## Commercial Shop & Transaction Management Module

**Milestone:** IT3060 - Human Computer Interaction, Milestone 03  
**Developer Component:** Commercial Shop & Transaction Management

### Functional Requirements
- **FR-03: In-app booking with simulated payment, priced per item & duration.**
  - Commercial shop inventory management (Full CRUD for shop equipment).
  - Flexible rental booking with live pricing based on rental days and daily rate.
  - Multi-tier fee calculation: Base rental fee + 8% platform fee + refundable deposit hold.
  - Concurrency control: Atomic stock decrement and increment using Firestore `runTransaction`.
  - Double-booking prevention and self-rental protection.
  - Simulated payment processing with booking reference generation (`GG-XXXX-XX`).
  - Real-time order lifecycle tracking (Confirmed -> Completed / Cancelled).
- **FR-07: Optional delivery / pickup service for equipment rentals.**
  - Integrated fulfillment choice: Store Pickup ($0) vs Doorstep Delivery ($15.00).
  - Delivery time slot selection (Morning, Afternoon, Evening).
  - Delivery address management with persistence to `users/{userId}/addresses`.

### Firestore Data Model
- **`shop_products`**: Equipment listings published by shop owners (`name`, `category`, `pricePerDay`, `deposit`, `quantity`, `isAvailable`, `imageUrl`, timestamps).
- **`rental_transactions`**: Rental agreements and transactions between renters and shops (`bookingRef`, `renterId`, `shopId`, `productId`, `startDate`, `endDate`, `days`, `fulfillment`, `deliveryAddress`, fee breakdown, statuses, timestamps).
- **`users/{userId}/addresses`**: Renter delivery address book subcollection.

### Documentation & Deliverables
- [docs/DEVIATIONS.md](file:///d:/Private/SLIIT/3rd%20year/2/IT3060%20-%20Human%20Computer%20Interaction/flutter%20apps/geargo_mobile_app/docs/DEVIATIONS.md): Architectural decisions and justified prototype deviations.
- [docs/TEST_CASES.md](file:///d:/Private/SLIIT/3rd%20year/2/IT3060%20-%20Human%20Computer%20Interaction/flutter%20apps/geargo_mobile_app/docs/TEST_CASES.md): Full traceability matrix covering automated unit/widget tests and emulator validation.
- [docs/VIVA_NOTES.md](file:///d:/Private/SLIIT/3rd%20year/2/IT3060%20-%20Human%20Computer%20Interaction/flutter%20apps/geargo_mobile_app/docs/VIVA_NOTES.md): Comprehensive viva defense guide, architecture breakdown, and examiner Q&A.
- [firestore.rules](file:///d:/Private/SLIIT/3rd%20year/2/IT3060%20-%20Human%20Computer%20Interaction/flutter%20apps/geargo_mobile_app/firestore.rules): Granular security rules enforcing role-based permissions and atomic transactions.

---

## Member 4 — handover, condition checks, chat and operations

The existing authentication/home module is preserved. Sign in and open
**Equipment Handovers & Messages** to access your rental handovers. Member 4
uses Firestore, Firebase Storage and three callable Functions; cloud services
must be configured before using these features against the live Firebase project.
Local emulator setup provides runnable, persistent synthetic workflows.

### Local backend, database and synthetic data

```sh
functions/node_modules/.bin/firebase emulators:start --project geargo-e0035 --only auth,firestore,functions,storage
```

On Windows use `functions\node_modules\.bin\firebase.cmd`. Ports are Auth 9099,
Firestore 8085, Functions 5001 and Storage 9199. Keep this terminal running.
In a second PowerShell terminal, seed **only local emulators**:

```powershell
$env:GCLOUD_PROJECT = 'geargo-e0035'
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8085'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
npm.cmd --prefix functions run seed
```

Synthetic accounts: `renter@geargo.test`, `owner@geargo.test`, `admin@geargo.test`,
`outsider@geargo.test`; password `GearGo-demo-2026`.