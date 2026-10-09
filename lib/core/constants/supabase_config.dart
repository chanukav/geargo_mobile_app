/// Supabase Configuration for GearGo
///
/// Replace [url] and [anonKey] with your actual Supabase project credentials
/// from the Supabase Dashboard -> Project Settings -> API.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase Project URL (e.g., https://xyzcompany.supabase.co)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_SUPABASE_PROJECT_URL.supabase.co',
  );

  /// Your Supabase Anon / Publishable Public Key
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  /// Alias for anonKey (Supabase Flutter 2.18+ standard)
  static String get publishableKey => anonKey;

  /// Public Storage Bucket for Equipment Photos
  static const String equipmentBucket = 'equipment-images';

  /// Checks if Supabase credentials have been filled in
  static bool get isConfigured {
    return url.isNotEmpty &&
        !url.contains('https://eiezkelexlvswihxajfe.supabase.co') &&
        anonKey.isNotEmpty &&
        !anonKey.contains(
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpZXprZWxleGx2c3dpaHhhamZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NTIwNTUsImV4cCI6MjEwNzEyODA1NX0.i0U_wllt3c4LjBfo5Ls-kvviNtmYiTt4i3uMBiZGycM',
        );
  }
}
