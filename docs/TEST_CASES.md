# Test Cases & Requirement Traceability Matrix

**Project:** GearGo Mobile App  
**Module:** Commercial Shop & Transaction Management  
**Branch:** `feature/shop-transactions`  
**Target Milestone:** IT3060 - Human Computer Interaction, Milestone 03  
**Functional Requirements:**
- **FR-03:** In-app booking with simulated payment, priced per item & duration.
- **FR-07:** Optional delivery / pickup service for equipment rentals.

---

## 1. Automated Test Suite Traceability

All automated tests run via `flutter test` and validate core logic without requiring live Firebase infrastructure (using `fake_cloud_firestore`).

| Test ID | Requirement | Type | Test File | Test Case Description | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **AUT-01** | FR-03, FR-07 | Unit | `test/price_breakdown_test.dart` | Pickup 1-day rental pricing (base fee + 8% service fee, zero delivery fee) | dueNow = $54.00, deposit = $25.00, total = $79.00 | Matches formula exactly | **PASS** |
| **AUT-02** | FR-03, FR-07 | Unit | `test/price_breakdown_test.dart` | Delivery 1-day rental pricing (base fee + 8% service fee + $15 delivery fee) | dueNow = $69.00, deposit = $25.00, total = $94.00 | Delivery fee added to dueNow | **PASS** |
| **AUT-03** | FR-03, FR-07 | Unit | `test/price_breakdown_test.dart` | Pickup 4-day rental pricing (multi-day rate calculation) | dueNow = $172.80, deposit = $80.00, total = $252.80 | Multiplied by 4 days | **PASS** |
| **AUT-04** | FR-03, FR-07 | Unit | `test/price_breakdown_test.dart` | Delivery 4-day rental pricing with refundable deposit breakdown | dueNow = $187.80, deposit = $80.00, total = $267.80 | Breakdown matches dueNow + hold | **PASS** |
| **AUT-05** | FR-03 | Unit | `test/price_breakdown_test.dart` | Rental date difference logic (calendar day difference >= 1 day fallback) | Returns 4 days for 4-day range, 1 day for same day | Correct day count returned | **PASS** |
| **AUT-06** | FR-03 | Unit | `test/price_breakdown_test.dart` | `ShopProduct` serialization (`toMap` / `fromDoc`) | Converts model to and from Firestore map retaining all fields | All fields preserved | **PASS** |
| **AUT-07** | FR-03, FR-07 | Unit | `test/price_breakdown_test.dart` | `RentalTransaction` serialization & `dueNow` derivation | Deserializes Firestore document and builds `PriceBreakdown` | `dueNow` matches persisted values | **PASS** |
| **AUT-08** | FR-03 | Unit | `test/product_validators_test.dart` | `ProductValidators.requiredField` blank/whitespace rejection | Rejects empty and whitespace strings; accepts non-empty | Required text validation enforced | **PASS** |
| **AUT-09** | FR-03 | Unit | `test/product_validators_test.dart` | `ProductValidators.money` non-numeric and negative values | Rejects letters, negative values; accepts valid dollar amounts | Currency validation enforced | **PASS** |
| **AUT-10** | FR-03 | Unit | `test/product_validators_test.dart` | `ProductValidators.quantity` non-integer and negative inputs | Rejects decimal numbers, negative numbers; accepts >= 0 integers | Integer stock quantity enforced | **PASS** |
| **AUT-11** | FR-03 | Unit / Service | `test/shop_product_service_test.dart` | **CREATE**: `addProduct` stores product in `shop_products` | Document written to `shop_products` with owner ID & timestamps | Document exists in Firestore | **PASS** |
| **AUT-12** | FR-03 | Unit / Service | `test/shop_product_service_test.dart` | **READ**: `streamMyProducts` queries by ownerId | Streams only items matching authenticated shop owner ID | Filtered by ownerId | **PASS** |
| **AUT-13** | FR-03 | Unit / Service | `test/shop_product_service_test.dart` | **READ**: `streamAvailableProducts` queries active items | Streams only products where `isAvailable == true` | Non-available items excluded | **PASS** |
| **AUT-14** | FR-03 | Unit / Service | `test/shop_product_service_test.dart` | **UPDATE**: `updateProduct` updates catalog fields | Modified name, category, price, deposit updated in Firestore | Updated values reflected | **PASS** |
| **AUT-15** | FR-03 | Unit / Service | `test/shop_product_service_test.dart` | **UPDATE**: `setAvailability` toggles active status | Switches `isAvailable` boolean on product document | Availability flag inverted | **PASS** |
| **AUT-16** | FR-03 | Unit / Service | `test/shop_product_service_test.dart` | **DELETE**: `deleteProduct` removes equipment document | Document removed from `shop_products` collection | Document no longer exists | **PASS** |
| **AUT-17** | FR-03 | Unit / Service | `test/transaction_service_test.dart` | **CREATE**: `createBooking` atomic transaction & stock decrement | Creates transaction doc AND decrements product quantity by 1 | Transaction created & stock reduced | **PASS** |
| **AUT-18** | FR-03 | Unit / Service | `test/transaction_service_test.dart` | **CREATE**: Rejects booking if product quantity is 0 (out of stock) | Throws `StateError('This item is currently out of stock')` | Error caught, no doc created | **PASS** |
| **AUT-19** | FR-03 | Unit / Service | `test/transaction_service_test.dart` | **CREATE**: Self-rental rejection (shop owner cannot rent own gear) | Throws `StateError('You cannot rent your own listing')` | Booking blocked | **PASS** |
| **AUT-20** | FR-03, FR-07 | Unit / Service | `test/transaction_service_test.dart` | **READ**: `streamMyBookings` and `streamShopOrders` role filtering | Renters see own bookings; shop owners see orders for their shop | Strict role partitioning | **PASS** |
| **AUT-21** | FR-07 | Unit / Service | `test/transaction_service_test.dart` | **UPDATE**: `updateDelivery` modifies address and time window | Updates delivery destination and window on transaction doc | New delivery details saved | **PASS** |
| **AUT-22** | FR-03 | Unit / Service | `test/transaction_service_test.dart` | **UPDATE**: `completeBooking` status progression & deposit release | Marks status `completed`, updates deposit status to `refunded` | Completed state recorded | **PASS** |
| **AUT-23** | FR-03 | Unit / Service | `test/transaction_service_test.dart` | **UPDATE**: `cancelBooking` atomic cancellation & stock restore | Marks status `cancelled`, refunds payment, increments stock + 1 | Stock returned to inventory | **PASS** |
| **AUT-24** | FR-03 | Unit / Service | `test/transaction_service_test.dart` | **DELETE**: `deleteBooking` removes transaction record | Removes transaction document from collection | Document deleted | **PASS** |
| **AUT-25** | FR-03 | Widget | `test/product_form_screen_test.dart` | `ProductFormScreen` creation mode rendering & validator triggers | Renders inputs, catches blank required fields, shows error labels | Validation errors displayed | **PASS** |
| **AUT-26** | FR-03 | Widget | `test/product_form_screen_test.dart` | `ProductFormScreen` accepts valid inputs without validation errors | Valid inputs clear all form validation errors | Form valid, submission ready | **PASS** |
| **AUT-27** | FR-03 | Widget | `test/product_form_screen_test.dart` | `ProductFormScreen` edit mode prefilling | Prefills existing product name, price, deposit, quantity | All fields pre-populated | **PASS** |

---

## 2. Interactive / Manual Verification Matrix (Android Emulator)

Tested live on Android Emulator `emulator-5554` (Pixel 9 Pro XL):

| Test ID | Requirement | Prototype Screen | Implemented Screen / File | Test Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **MAN-01** | Architecture | Home Dashboard | `lib/screens/home/home.dart` -> `lib/screens/shop/shop_transactions_home.dart` | 1. Open app.<br>2. On Home screen, locate "Shop & Rentals" quick action card.<br>3. Tap card. | Navigates to Shop & Transactions Hub with tabs: "Renter Bookings", "My Equipment Shop", and "Shop Orders". | Screen opened smoothly, all 3 tabs visible. | **PASS** |
| **MAN-02** | FR-03 | Shop Management | `lib/screens/shop/my_shop_screen.dart`<br>`lib/screens/shop/product_form_screen.dart` | 1. Go to "My Equipment Shop" tab.<br>2. Tap "Add Equipment" floating button.<br>3. Fill name, category, price ($45), deposit ($100), quantity (3).<br>4. Tap "Add to inventory". | New item appears in the shop inventory list with stock badge "3 in stock". | Product listed immediately via StreamBuilder. | **PASS** |
| **MAN-03** | FR-03 | Shop Management | `lib/screens/shop/product_form_screen.dart` | 1. Tap edit (pencil) icon on an existing item.<br>2. Update price from $45 to $50.<br>3. Tap "Save changes". | List updates in real-time showing $50.00 / day. | Updated price rendered without page refresh. | **PASS** |
| **MAN-04** | FR-03 | Shop Management | `lib/screens/shop/my_shop_screen.dart` | 1. Toggle availability switch off for an item. | Availability status updates to "Unavailable", badge turns grey. | Status updated atomically in Firestore. | **PASS** |
| **MAN-05** | FR-03 | Shop Management | `lib/screens/shop/my_shop_screen.dart` | 1. Tap delete icon on test equipment.<br>2. Confirm deletion in alert dialog. | Item removed from Firestore collection and disappears from UI. | Item deleted and removed from view. | **PASS** |
| **MAN-06** | FR-03, FR-07 | Booking Flow | `lib/screens/shop/booking_screen.dart` | 1. Open an available equipment item as a renter.<br>2. Tap "Book this item".<br>3. Select start and end dates.<br>4. Inspect price breakdown table. | Displays Rental fee (price * days), Platform service fee (8%), Refundable deposit, Due now. | Correct live calculations displayed. | **PASS** |
| **MAN-07** | FR-07 | Delivery Option | `lib/screens/shop/booking_screen.dart` | 1. In Booking screen, toggle fulfillment to "Delivery".<br>2. Observe breakdown and delivery section. | Delivery fee ($15.00) added to "Due now". Address selector & delivery window dropdown appear. | Fee added dynamically, address section exposed. | **PASS** |
| **MAN-08** | FR-07 | Address Persistence | `lib/screens/shop/booking_screen.dart`<br>`lib/services/address_service.dart` | 1. Select "Add new address".<br>2. Enter label "Home", address "42 Marine Drive, Colombo 03".<br>3. Check "Save address for future rentals".<br>4. Save address. | Address saved to `users/{uid}/addresses` and auto-selected for current booking. | Address saved in Firestore subcollection. | **PASS** |
| **MAN-09** | FR-03 | Checkout / Payment | `lib/screens/shop/booking_screen.dart` | 1. Select payment method ("Card: Visa •••• 4242").<br>2. Tap "Confirm & Pay".<br>3. Inspect processing state and confirmation. | Button disables to prevent double-tap; simulated payment succeeds; navigates to Confirmation screen with booking reference `GG-XXXX-XX`. | Booking reference generated, stock atomically reduced by 1. | **PASS** |
| **MAN-10** | FR-03 | Transaction History | `lib/screens/shop/renter_bookings_screen.dart`<br>`lib/screens/shop/transaction_detail_screen.dart` | 1. Open "Renter Bookings" tab.<br>2. Tap the newly created booking. | Displays full details: status banner, equipment info, rental period, delivery details, price breakdown, and transaction timeline. | Transaction details rendered accurately. | **PASS** |
| **MAN-11** | FR-03 | Order Management | `lib/screens/shop/shop_orders_screen.dart`<br>`lib/screens/shop/transaction_detail_screen.dart` | 1. Open "Shop Orders" tab as the shop owner.<br>2. Tap active order.<br>3. Tap "Mark as Returned / Completed". | Booking status transitions to `completed`, deposit status transitions to `refunded`. | Status badge shows green "Completed", hold released. | **PASS** |
| **MAN-12** | FR-03 | Cancellation & Restock | `lib/screens/shop/transaction_detail_screen.dart` | 1. Tap "Cancel booking" on an active confirmed rental.<br>2. Confirm prompt. | Status transitions to `cancelled`, refund recorded, and product inventory stock increments by 1. | Stock quantity restored in `shop_products`. | **PASS** |
| **MAN-13** | Robustness | Booking Screen | `lib/screens/shop/booking_screen.dart` | 1. Pick end date before or equal to start date. | Date picker enforces end date after start date; booking button is disabled if range invalid. | Prevented invalid date selection. | **PASS** |
| **MAN-14** | Robustness | Unauthenticated Guard | All module screens | 1. Access module screens when signed out. | Displays friendly warning "Please sign in to view your bookings/shop" without uncaught null pointer exceptions. | Graceful fallbacks rendered. | **PASS** |
