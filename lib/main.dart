import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'member4/emulators.dart';
import 'screens/splash/splash_screen.dart';
import 'services/app_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsService.instance.init();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyC72StYLf5ECEmohXZda84IqOREoWS6F6I',
        authDomain: 'geargo-e0035.firebaseapp.com',
        appId: '1:813025681886:android:9990a176c39fb6db267d4f', // Using your provided App ID
        messagingSenderId: '813025681886',
        projectId: 'geargo-e0035',
        storageBucket: 'geargo-e0035.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
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

