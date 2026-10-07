import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide Settings Service managing Theme (Light/Dark/System)
/// and Language (English, Sinhala, Tamil) with persistence.
class AppSettingsService extends ChangeNotifier {
  static final AppSettingsService instance = AppSettingsService._internal();

  AppSettingsService._internal();

  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyLanguage = 'app_language_code';

  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'en';

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Initialize saved settings from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_keyThemeMode);
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      }

      final savedLang = prefs.getString(_keyLanguage);
      if (savedLang != null && (savedLang == 'en' || savedLang == 'si' || savedLang == 'ta')) {
        _languageCode = savedLang;
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Update and persist theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'system';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.dark) val = 'dark';
      await prefs.setString(_keyThemeMode, val);
    } catch (_) {}
  }

  /// Update and persist language code ('en', 'si', 'ta')
  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, code);
    } catch (_) {}
  }

  /// Translate a key into the active language
  String tr(String key) {
    final dict = _translations[_languageCode] ?? _translations['en']!;
    return dict[key] ?? _translations['en']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // ---------------- English ----------------
    'en': {
      'app_name': 'GearGo',
      'your_profile': 'Your profile',
      'trail_member': 'TRAIL MEMBER',
      'member_since': 'Member since 2022',
      'reviews': 'reviews',
      'verified': 'Verified',
      'trusted_renter': 'Trusted renter',
      'trips_completed': 'Trips completed',
      'profile_ready_title': 'Your profile is almost trail-ready',
      'profile_ready_sub': 'Add an emergency contact to reach 100%',
      'account_trust': 'Account & trust',
      'manage': 'Manage',
      'personal_info': 'Personal information',
      'personal_info_sub': 'Name, email, phone and emergency contact',
      'identity_verification': 'Identity verification',
      'identity_verification_sub': 'Government ID and selfie confirmed',
      'payments': 'Payments',
      'add_new': 'Add new',
      'default_badge': 'Default',
      'default_payment_sub': 'Default payment method · Expires 09/28',
      'payout_account': 'Payout account',
      'preferences_display': 'Appearance & Language',
      'theme_mode': 'Theme Mode',
      'language': 'Language',
      'theme_system': 'Auto',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'rental_preferences': 'Rental preferences',
      'edit': 'Edit',
      'favorite_activities': 'FAVORITE ACTIVITIES',
      'activity_hiking': 'Hiking',
      'activity_cycling': 'Cycling',
      'activity_camping': 'Camping',
      'pickup_radius': 'Pickup radius',
      'preferred_handover': 'Preferred handover',
      'weekends': 'Weekends',
      'notifications': 'Notifications',
      'booking_updates': 'Booking updates',
      'booking_updates_sub': 'Requests, handovers and returns',
      'offers_near_you': 'Offers near you',
      'offers_near_you_sub': 'Price drops and new local gear',
      'help_adventure_title': 'Help for every adventure',
      'help_adventure_sub': 'Safety guidance and support, whenever you need it.',
      'get_help': 'Get help',
      'sign_out': 'Sign out',
      'sign_out_confirm_title': 'Sign Out',
      'sign_out_confirm_desc': 'Are you sure you want to sign out of GearGo?',
      'cancel': 'Cancel',
      'nav_home': 'Home',
      'nav_search': 'Search',
      'nav_bookings': 'Bookings',
      'nav_messages': 'Messages',
      'nav_profile': 'Profile',
      'search_hint': 'Search equipment...',
      'items_found': 'items found nearby',
      'filter': 'Filters',
      'apply_filters': 'Apply Filters',
      'reset_filters': 'Reset All Filters',
      'distance_radius': 'Distance Radius',
      'categories': 'Categories',
      'price_per_day': 'Price Per Day',
      'available_now': 'Available Now',
      'only_available_today': 'Only show items ready to pick up today',
      'contact_support': 'Contact Support',
      'close': 'Close',
      'gear_up_today': 'Gear up today',
      'hello': 'Hello',
      'browse_by_sport': 'Browse by Sport',
      'popular_rentals': 'Popular Rentals',
      'see_all': 'See All',
      'insured_banner': 'Condition verified. All rentals are 100% insured against damage.',
      'quick_display': 'Display & Language',
    },

    // ---------------- සිංහල (Sinhala) ----------------
    'si': {
      'app_name': 'GearGo',
      'your_profile': 'ඔබගේ ගිණුම',
      'trail_member': 'විශේෂ සාමාජික',
      'member_since': '2022 සිට සාමාජික',
      'reviews': 'සමාලෝචන',
      'verified': 'තහවුරු කළ',
      'trusted_renter': 'විශ්වාසදායක කුලීකරු',
      'trips_completed': 'චාරිකා නිම කර ඇත',
      'profile_ready_title': 'ඔබගේ ගිණුම සූදානම් වීමට ආසන්නයි',
      'profile_ready_sub': '100% සම්පූර්ණ කිරීමට හදිසි ඇමතුමක් එක් කරන්න',
      'account_trust': 'ගිණුම සහ ආරක්ෂාව',
      'manage': 'කළමනාකරණය',
      'personal_info': 'පුද්ගලික තොරතුරු',
      'personal_info_sub': 'නම, ඊමේල්, දුරකථන සහ හදිසි ඇමතුම',
      'identity_verification': 'අනන්‍යතාව තහවුරු කිරීම',
      'identity_verification_sub': 'රජයේ හැඳුනුම්පත සහ සෙල්ෆි තහවුරු කර ඇත',
      'payments': 'ගෙවීම් ක්‍රම',
      'add_new': 'අලුත් එකක්',
      'default_badge': 'ප්‍රධාන',
      'default_payment_sub': 'ප්‍රධාන ගෙවීම් ක්‍රමය · කල් ඉකුත්වීම 09/28',
      'payout_account': 'මුදල් ලබාගන්නා ගිණුම',
      'preferences_display': 'පෙනුම සහ භාෂාව',
      'theme_mode': 'තේමාව',
      'language': 'භාෂාව',
      'theme_system': 'ස්වයංක්‍රීය',
      'theme_light': 'ආලෝකමත්',
      'theme_dark': 'අඳුරු (Dark)',
      'rental_preferences': 'කුලී මනාපයන්',
      'edit': 'සංස්කරණය',
      'favorite_activities': 'ප්‍රියතම ක්‍රියාකාරකම්',
      'activity_hiking': 'කඳු නැගීම',
      'activity_cycling': 'බයිසිකල් පැදීම',
      'activity_camping': 'කඳවුරු බැඳීම',
      'pickup_radius': 'ලබා ගැනීමේ දුර',
      'preferred_handover': 'භාරදෙන වේලාව',
      'weekends': 'සති අන්ත',
      'notifications': 'දැනුම්දීම්',
      'booking_updates': 'වෙන්කිරීම් යාවත්කාලීන',
      'booking_updates_sub': 'ඉල්ලීම්, භාරදීම් සහ ආපසු ලබාදීම්',
      'offers_near_you': 'ඔබට ආසන්න දීමනා',
      'offers_near_you_sub': 'මිල අඩු කිරීම් සහ නව උපකරණ',
      'help_adventure_title': 'සෑම ගමනකටම සහයෝගය',
      'help_adventure_sub': 'ඕනෑම මොහොතක ආරක්ෂාව සහ පාරිභෝගික සහය.',
      'get_help': 'උදව් ලබාගන්න',
      'sign_out': 'පිටවන්න',
      'sign_out_confirm_title': 'පිටවීම තහවුරු කරන්න',
      'sign_out_confirm_desc': 'ඔබට GearGo ගිණුමෙන් පිටවීමට අවශ්‍ය බව සහතිකද?',
      'cancel': 'අවලංගු කරන්න',
      'nav_home': 'මුල් පිටුව',
      'nav_search': 'සොයන්න',
      'nav_bookings': 'වෙන්කිරීම්',
      'nav_messages': 'පණිවිඩ',
      'nav_profile': 'ගිණුම',
      'search_hint': 'ක්‍රීඩා උපකරණ සොයන්න...',
      'items_found': 'භාණ්ඩ ආසන්නයේ හමුවිය',
      'filter': 'පෙරහන්',
      'apply_filters': 'පෙරහන් යොදන්න',
      'reset_filters': 'සියලු පෙරහන් ඉවත් කරන්න',
      'distance_radius': 'දුර ප්‍රමාණය',
      'categories': 'කාණ්ඩ',
      'price_per_day': 'දිනකට මිල',
      'available_now': 'දැන් ලබාගත හැක',
      'only_available_today': 'අද ලබාගත හැකි භාණ්ඩ පමණක් පෙන්වන්න',
      'contact_support': 'සහාය සම්බන්ධ කරගන්න',
      'close': 'වසන්න',
      'gear_up_today': 'අදම උපකරණ සූදානම් කරගන්න',
      'hello': 'ආයුබෝවන්',
      'browse_by_sport': 'ක්‍රීඩාව අනුව සොයන්න',
      'popular_rentals': 'ජනප්‍රිය කුලී උපකරණ',
      'see_all': 'සියල්ල බලන්න',
      'insured_banner': 'තත්ත්වය තහවුරු කර ඇත. සියලුම කුලී උපකරණ 100% ක් රක්ෂණය කර ඇත.',
      'quick_display': 'පෙනුම සහ භාෂාව',
    },

    // ---------------- தமிழ் (Tamil) ----------------
    'ta': {
      'app_name': 'GearGo',
      'your_profile': 'உங்கள் சுயவிவரம்',
      'trail_member': 'டிரெயில் உறுப்பினர்',
      'member_since': '2022 முதல் உறுப்பினர்',
      'reviews': 'மதிப்புரைகள்',
      'verified': 'சரிபார்க்கப்பட்டது',
      'trusted_renter': 'நம்பகமான வாடகைதாரர்',
      'trips_completed': 'பயணங்கள் முடிந்தது',
      'profile_ready_title': 'உங்கள் சுயவிவரம் தயாராக உள்ளது',
      'profile_ready_sub': '100% அடைய அவசர தொடர்பைச் சேர்க்கவும்',
      'account_trust': 'கணக்கு & நம்பிக்கை',
      'manage': 'நிர்வகி',
      'personal_info': 'தனிப்பட்ட தகவல்',
      'personal_info_sub': 'பெயர், மின்னஞ்சல், தொலைபேசி மற்றும் அவசர தொடர்பு',
      'identity_verification': 'அடையாள சரிபார்ப்பு',
      'identity_verification_sub': 'அரசு அடையாள அட்டை மற்றும் செல்ஃபி உறுதிப்படுத்தப்பட்டது',
      'payments': 'கொடுப்பனவுகள்',
      'add_new': 'புதியது சேர்க்க',
      'default_badge': 'இயல்புநிலை',
      'default_payment_sub': 'இயல்புநிலை கட்டண முறை · காலாவதி 09/28',
      'payout_account': 'பணம் பெறும் கணக்கு',
      'preferences_display': 'தோற்றம் & மொழி',
      'theme_mode': 'தீம் பயன்முறை',
      'language': 'மொழி',
      'theme_system': 'தானியங்கி',
      'theme_light': 'வெளிச்சம்',
      'theme_dark': 'இருள் (Dark)',
      'rental_preferences': 'வாடகை விருப்பங்கள்',
      'edit': 'திருத்து',
      'favorite_activities': 'விருப்பமான செயல்பாடுகள்',
      'activity_hiking': 'நடைபயணம்',
      'activity_cycling': 'சைக்கிள் ஓட்டுதல்',
      'activity_camping': 'முகாம்',
      'pickup_radius': 'எடுக்கும் தூரம்',
      'preferred_handover': 'விரும்பிய ஒப்படைப்பு',
      'weekends': 'வார இறுதி நாட்கள்',
      'notifications': 'அறிவிப்புகள்',
      'booking_updates': 'முன்பதிவு புதுப்பிப்புகள்',
      'booking_updates_sub': 'கோரிக்கைகள், ஒப்படைப்புகள் மற்றும் திரும்பப் பெறுதல்கள்',
      'offers_near_you': 'உங்களுக்கு அருகிலுள்ள சலுகைகள்',
      'offers_near_you_sub': 'விலை குறைப்பு மற்றும் புதிய கியர்',
      'help_adventure_title': 'ஒவ்வொரு சாகசத்திற்கும் உதவி',
      'help_adventure_sub': 'உங்களுக்குத் தேவைப்படும் போதெல்லாம் பாதுகாப்பு வழிகாட்டுதல்.',
      'get_help': 'உதவி பெறுக',
      'sign_out': 'வெளியேறு',
      'sign_out_confirm_title': 'வெளியேறுவதை உறுதிப்படுத்தவும்',
      'sign_out_confirm_desc': 'GearGo இலிருந்து வெளியேற விரும்புகிறீர்களா?',
      'cancel': 'ரத்துசெய்',
      'nav_home': 'முகப்பு',
      'nav_search': 'தேடல்',
      'nav_bookings': 'முன்பதிவுகள்',
      'nav_messages': 'செய்திகள்',
      'nav_profile': 'சுயவிவரம்',
      'search_hint': 'உபகரணங்களைத் தேடுங்கள்...',
      'items_found': 'பொருட்கள் அருகில் கண்டறியப்பட்டன',
      'filter': 'வடிகட்டிகள்',
      'apply_filters': 'வடிகட்டிகளைப் பயன்படுத்து',
      'reset_filters': 'அனைத்து வடிகட்டிகளையும் மீட்டமை',
      'distance_radius': 'தொலைவு ஆரம்',
      'categories': 'வகைகள்',
      'price_per_day': 'ஒரு நாளைக்கு விலை',
      'available_now': 'இப்போது கிடைக்கிறது',
      'only_available_today': 'இன்று எடுக்கத் தயாராக உள்ளவற்றை மட்டும் காட்டு',
      'contact_support': 'ஆதரவைத் தொடர்பு கொள்ளவும்',
      'close': 'மூடு',
      'gear_up_today': 'இன்றே தயாராகுங்கள்',
      'hello': 'வணக்கம்',
      'browse_by_sport': 'விளையாட்டு வாரியாக',
      'popular_rentals': 'பிரபலமான வாடகைகள்',
      'see_all': 'அனைத்தையும் பார்',
      'insured_banner': 'நிலை சரிபார்க்கப்பட்டது. அனைத்து வாடகைகளுக்கும் 100% காப்பீடு செய்யப்பட்டுள்ளது.',
      'quick_display': 'தோற்றம் & மொழி',
    },
  };
}
