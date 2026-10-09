# Viva Defense Notes & Technical Reference Guide

**Project:** GearGo Mobile App  
**Module:** Commercial Shop & Transaction Management  
**Student Component:** Individual Feature Module (Milestone 03, IT3060 - Human Computer Interaction)  
**Branch:** `feature/shop-transactions`  
**Functional Requirements:**
- **FR-03:** In-app booking with simulated payment, priced per item & duration.
- **FR-07:** Optional delivery / pickup service for equipment rentals.

---

## 1. Module Overview & Scope

This module empowers sports equipment shop owners to list, manage, and track rental equipment inventory, while enabling renters to browse commercial equipment, book rentals with flexible duration, choose delivery or pickup fulfillment, and track order lifecycles with simulated transactions.

### Core Collections in Firestore
1. **`shop_products`**: Equipment listings published by shop owners (`ownerId`, `name`, `category`, `pricePerDay`, `deposit`, `quantity`, `isAvailable`, `imageUrl`, timestamps).
2. **`rental_transactions`**: Rental agreements and transactions between renters and shops (`bookingRef`, `renterId`, `shopId`, `productId`, `startDate`, `endDate`, `days`, `fulfillment`, `deliveryAddress`, fees, `paymentStatus`, `status`, timestamps).
3. **`users/{userId}/addresses`**: Renter delivery address book subcollection for saved delivery locations (`label`, `fullAddress`, `deliveryNotes`, timestamps).

---

## 2. File-by-File Architecture Breakdown

### A. Data Models (`lib/models/`)
- **`shop_product.dart`**:
  - Encapsulates inventory items.
  - Implements `toMap()` for Firestore creation/updates and `ShopProduct.fromDoc()` for reactive deserialization.
  - Handles fallback values for optional images and numerical sanitization (`num.toDouble()`).
- **`rental_transaction.dart`**:
  - Models the end-to-end rental contract.
  - Contains nested `PriceBreakdown` class with formulas:
    - `rentalFee = pricePerDay * days`
    - `serviceFee = rentalFee * 0.08` (8% platform fee)
    - `deliveryFee = isDelivery ? 15.00 : 0.00`
    - `dueNow = rentalFee + serviceFee + deliveryFee` (charged immediately)
    - `total = dueNow + deposit` (with deposit as refundable hold)
  - Implements `RentalTransaction.fromDoc()` with status parsing and timestamp deserialization.
- **`user_address.dart`**:
  - Models saved delivery destinations with `label`, `fullAddress`, and `deliveryNotes`.

### B. Business Logic Services (`lib/services/`)
- **`shop_product_service.dart`**:
  - Handles equipment catalog CRUD operations.
  - `addProduct`: Creates a new document with owner ID and server timestamps.
  - `streamMyProducts`: Queries items where `ownerId == currentUserId`.
  - `streamAvailableProducts`: Queries items where `isAvailable == true`.
  - `updateProduct`: Updates editable catalog fields.
  - `setAvailability`: Toggles the active availability boolean.
  - `deleteProduct`: Removes equipment from the inventory.
  - Supports dependency injection (`firestore`, `auth`, `userId`) for unit testing with fake Firestore.
- **`transaction_service.dart`**:
  - Orchestrates bookings, payments, and inventory synchronization.
  - `createBooking`:
    - Checks overlap to prevent duplicate bookings.
    - Uses **`runTransaction`** to atomically read current inventory stock, verify `quantity > 0`, decrement `quantity` by 1, and write the transaction document.
  - `cancelBooking`:
    - Uses **`runTransaction`** with read-before-write ordering to mark the booking `cancelled`, refund payment, and atomically increment product stock `quantity` back by 1.
  - `completeBooking`: Updates transaction status to `completed` and marks deposit as `refunded`.
  - `updateDelivery`: Updates shipping destination and time window for pending deliveries.
  - `deleteBooking`: Removes transaction record.
- **`address_service.dart`**:
  - Persists and streams addresses from `users/{uid}/addresses`.
  - Sorts addresses in-memory by timestamp to eliminate any requirement for Firestore composite indexes.

### C. Presentation & Screens (`lib/screens/shop/`)
- **`shop_transactions_home.dart`**:
  - Central module hub featuring a 3-tab navigation layout:
    - Tab 1: **Renter Bookings** (active and past rentals)
    - Tab 2: **My Equipment Shop** (inventory management for shop owners)
    - Tab 3: **Shop Orders** (incoming customer orders for the shop)
- **`my_shop_screen.dart`**:
  - Shop owner catalog dashboard.
  - Displays real-time inventory count, stock status badges, availability switches, edit buttons, and delete dialogs.
  - Uses `StreamBuilder` for reactive live updates.
- **`product_form_screen.dart`**:
  - Dual-mode form: Create new item or Edit existing item.
  - Form validation with `ProductValidators` (non-empty name, positive monetary amounts, integer stock count).
  - Chip selectors for Category and Condition.
- **`booking_screen.dart`**:
  - The booking and simulated checkout flow.
  - Date range picker enforcing `endDate >= startDate`.
  - Interactive fulfillment selector (Store Pickup vs Delivery).
  - Live price breakdown card updating dynamically upon date or delivery changes.
  - Delivery address selector with ability to add and persist new addresses.
  - Double-tap prevention on the payment submission button.
- **`booking_confirmation_screen.dart`**:
  - Displays the generated booking reference (`GG-XXXX-XX`), rental period, fulfillment method, and payment summary with immediate navigation options.
- **`renter_bookings_screen.dart`**:
  - List of rentals placed by the logged-in user, filtered into "Active" and "Past" tabs.
- **`shop_orders_screen.dart`**:
  - List of equipment orders placed at the user's shop, with instant fulfillment status filters.
- **`transaction_detail_screen.dart`**:
  - Comprehensive order detail view: status banner, item summary, dates, delivery details, price breakdown, payment method, order timeline, and actions (Cancel, Mark Completed, Edit Delivery).

### D. Reusable Widgets & Theme (`lib/screens/shop/widgets/`)
- **`shop_theme.dart`**:
  - Provides `ShopColors`, `ShopSpacing`, and `ShopThemed` wrapper ensuring visual consistency in both light and dark modes without conflicting with teammates' global theme.
- **`date_range_field.dart`**:
  - Custom interactive calendar selector widget with start/end date selection and validation.
- **`product_validators.dart`**:
  - Pure validator functions for form input validation and easy unit testing.

---

## 3. Key Design Decisions & Technical Rationale

### 1. Why Plain `StatefulWidget` and `StreamBuilder`?
- **Decision:** No third-party state management libraries (Provider, Riverpod, Bloc, GetX) were introduced.
- **Viva Rationale:**
  - Adheres strictly to project constraints and architectural consistency.
  - `StreamBuilder` directly harnesses Firestore's real-time WebSocket connection, meaning local state is always automatically synchronized with the database without boilerplate.
  - Every line of code is transparent and easily explainable in an academic defense.

### 2. Why Firestore `runTransaction` for Bookings?
- **Decision:** Both booking creation and order cancellation use Firestore atomic transactions (`_db.runTransaction(...)`).
- **Viva Rationale:**
  - **Concurrency & Race Condition Prevention:** If two users attempt to book the last piece of equipment at the same time, naive `get()` followed by `set()` could lead to negative stock. `runTransaction` locks and validates the stock atomically; if another client modifies the document concurrently, Firestore automatically retries.
  - **Read-before-write ordering:** In Firestore transactions, all reads (`transaction.get()`) must occur before any writes (`transaction.update()` or `transaction.set()`). Our implementation guarantees this ordering.

### 3. Why Avoid Firestore Composite Indexes?
- **Decision:** Firestore queries filter on single fields (`ownerId`, `isAvailable`, `productId`, `renterId`, `shopId`), while date overlap checking and sorting are performed in Dart memory.
- **Viva Rationale:**
  - Queries with multiple `where` clauses on different fields or combinations of `where` and `orderBy` require composite indexes created via the Firebase Console.
  - In a project evaluation / viva demonstration, evaluating graders or examiners running fresh instances will not encounter missing-index query crashes (`FAILED_PRECONDITION: The query requires an index`).

### 4. Integration of Delivery into the Booking Flow (HCI Rationale)
- **Decision:** Delivery is integrated directly into `BookingScreen` as a fulfillment toggle rather than a detached separate page.
- **Viva Rationale (HCI Heuristics):**
  - **Minimizing Cognitive Load (Nielsen Heuristic #6 - Recognition rather than recall):** Renters immediately see how choosing delivery impacts the total cost and delivery timeframe in a unified price breakdown.
  - **Visibility of System Status (Nielsen Heuristic #1):** Toggling between Pickup and Delivery instantly updates the "Due now" calculation with immediate feedback.

---

## 4. Anticipated Viva Defense Questions & Answers

### Q1: How does your booking system prevent double-booking or overselling?
**Answer:**  
"We implement a two-tier defense:  
First, before initiating payment, `TransactionService` queries existing active bookings for the product and checks for calendar date overlaps in memory.  
Second and most importantly, we execute an atomic Firestore transaction via `_db.runTransaction()`. Inside the transaction, we read the product document to verify that `quantity > 0`. If stock is available, we decrement `quantity` by 1 and write the transaction record simultaneously. If two renters press book simultaneously for the last item, one will succeed and the second will receive an out-of-stock notification."

### Q2: What happens to the stock when a booking is cancelled?
**Answer:**  
"When a booking is cancelled through `cancelBooking()`, we use another atomic transaction. It reads the booking and product documents, sets the booking status to `cancelled`, changes the payment status to `refunded`, and increments the product's `quantity` by 1. It also re-enables `isAvailable = true` if the product was previously marked unavailable."

### Q3: Explain how the price breakdown formula works and why deposit is separated.
**Answer:**  
"The formula is implemented in `PriceBreakdown.calculate()`:
- `rentalFee = pricePerDay * days`
- `serviceFee = rentalFee * 0.08` (platform fee)
- `deliveryFee = isDelivery ? 15.00 : 0.00`
- `dueNow = rentalFee + serviceFee + deliveryFee`
- `total = dueNow + deposit`  
We separate `dueNow` from `deposit` because in commercial equipment rentals, the security deposit is an authorization hold, not an upfront payment. When the equipment is returned safely in good condition, the shop owner completes the transaction, and the deposit hold is released (`paymentStatus = 'refunded'`)."

### Q4: How is delivery handled and where are user addresses saved?
**Answer:**  
"When a user selects 'Delivery', the UI reveals the delivery address picker and delivery time window options (Morning, Afternoon, Evening). If the renter enters a new address and checks 'Save address for future rentals', `AddressService` saves it into a user-scoped subcollection `users/{uid}/addresses`. In subsequent bookings, saved addresses appear in a dropdown for 1-tap selection."

### Q5: How did you test your code without connecting to real Firebase during automated testing?
**Answer:**  
"We used `fake_cloud_firestore` in our `dev_dependencies`. By decoupling `FirebaseFirestore.instance` through dependency injection in `ShopProductService`, `TransactionService`, and `AddressService`, our unit and widget tests run completely offline. The tests verify full CRUD operations, atomic transactions, form validation, and stock decrement/restoration with 100% reliability and fast execution."

### Q6: How do you handle unauthenticated users or users attempting to rent their own equipment?
**Answer:**  
"All module screens check `FirebaseAuth.instance.currentUser`. If no user is signed in, a helpful warning card is rendered explaining that authentication is required. In addition, `TransactionService.createBooking` explicitly verifies that `product.ownerId != renterId`, throwing an informative error if a shop owner tries to rent their own listing."

### Q7: What HCI usability principles did you apply to your screens?
**Answer:**  
"We applied Nielsen's Usability Heuristics:
1. **Visibility of system status:** Live price breakdown recalculates instantly as dates or fulfillment methods change; loading indicators and double-tap prevention prevent duplicate charges.
2. **Error prevention:** Date pickers restrict past dates and disallow end dates before start dates; form fields validate monetary amounts and quantities before allowing submission.
3. **Consistency and standards:** Followed Material Design 3 guidelines with cohesive chips, cards, dialog confirmations for destructive actions (like deleting equipment), and responsive dark/light theme support.
4. **User control and freedom:** Clear cancellation options with confirmation dialogs, and edit capabilities for inventory and delivery slots."

---

## 5. Security Rules Reference (`firestore.rules`)

Our module enforces the following Firestore security policies:
1. **`shop_products`**:
   - `read`: Public / authenticated read for browsing.
   - `create`: Authenticated users only; `request.auth.uid == request.resource.data.ownerId`.
   - `update`, `delete`: Owner only (`request.auth.uid == resource.data.ownerId`), OR allowed during a transaction booking to decrement/increment quantity.
2. **`rental_transactions`**:
   - `read`: Participant only (`request.auth.uid == resource.data.renterId || request.auth.uid == resource.data.shopId`).
   - `create`: Renter only (`request.auth.uid == request.resource.data.renterId`).
   - `update`: Renter or Shop Owner participant.
   - `delete`: Participant or Admin.
3. **`users/{userId}/addresses`**:
   - `read`, `write`: The authenticated owner of the profile (`request.auth.uid == userId`).
