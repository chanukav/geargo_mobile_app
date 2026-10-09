import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'member4/emulators.dart';
import 'screens/splash/splash_screen.dart';
import 'services/app_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsService.instance.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase Storage for Equipment images
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
      debugPrint('Supabase initialized successfully for image storage.');
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
    }
  } else {
    debugPrint('Supabase credentials not configured in lib/core/constants/supabase_config.dart. Equipment images will fallback gracefully.');
  }

  await configureMember4Emulators();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettingsService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'GearGo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppSettingsService.instance.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

