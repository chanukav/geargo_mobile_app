import '../../models/shop_product.dart';

/// Pre-populated high-fidelity dummy data directly matching Milestone 03 / 02
/// Commercial Rental Shop Interfaces (Report Page 17, Section 7.4).
class DummyShopData {
  DummyShopData._();

  static const String shopName = 'Apex Trail Rentals';
  static const String shopRating = '4.9 (148 reviews)';
  static const String pickupLocation =
      'Capitol Hill, Denver (1.4 miles away)\nMeet at a safe public location';
  static const String deliveryDescription =
      'Oct 12, 8:00 AM - 10:00 AM\nContactless drop-off & safe returns';

  static const String defaultHeroImage =
      'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?auto=format&fit=crop&w=1000&q=80';

  static const List<String> detailThumbnails = [
    'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1532298229144-0ec0c57515c7?auto=format&fit=crop&w=400&q=80',
  ];

  static const String hostAvatar =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80';

  static const defaultProduct = ShopProduct(
    id: 'trek-fuel-ex-8',
    ownerId: 'apex-trail-rentals',
    name: 'Trek Fuel EX 8 Gen 6',
    category: 'Mountain Bikes',
    description:
        'Extremely well-maintained. Light cosmetic scuffs on frame, mechanics are freshly tuned. Shocks serviced last month.',
    condition: 'Excellent',
    pricePerDay: 45.0,
    deposit: 100.0,
    quantity: 5,
    isAvailable: true,
    imageUrl: defaultHeroImage,
  );

  static const String homeAddress = '1230 N Lafayette St, Denver, CO 80218';
  static const String workAddress = '1700 Lincoln St, Denver, CO 80203';
  static const String defaultDeliveryAddress = '128 Pine Street, Denver, CO 80202';
  static const String defaultInstructions = 'Leave at front door, ring bell';
  static const String defaultPaymentMethod = 'Visa Ending in 4242';
  static const String defaultPaymentExpiry = 'Expires 12/28';
  static const String sampleBookingRef = 'GG-8942-09';
}
