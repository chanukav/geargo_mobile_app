import 'package:flutter/material.dart';

/// Milestone 02 design-system palette (report section 7.1.2).
/// Used only by the Commercial Shop & Transaction module so the shared
/// AppTheme used by the other members' screens is left untouched.
class ShopPalette {
  ShopPalette._();

  static const Color blue = Color(0xFF2563EB); // primary royal blue
  static const Color navy = Color(0xFF0F2B48); // headers, headings
  static const Color orange = Color(0xFFFF6B35); // main calls-to-action button
  static const Color orangeLight = Color(0xFFFFF1EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color blueTint = Color(0xFFEFF6FF);
  static const Color badgeBlue = Color(0xFFE0F2FE);
  static const Color badgeBlueText = Color(0xFF0284C7);
  static const Color green = Color(0xFF16A34A);
  static const Color greenTint = Color(0xFFDCFCE7);
  static const Color text = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
}

class ShopTheme {
  ShopTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ShopPalette.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: ShopPalette.blue,
      onPrimary: Colors.white,
      secondary: ShopPalette.orange,
      onSecondary: Colors.white,
      primaryContainer: ShopPalette.blueTint,
      onPrimaryContainer: ShopPalette.navy,
      tertiaryContainer: const Color(0xFFD9F3E6),
      onTertiaryContainer: const Color(0xFF14532D),
      errorContainer: const Color(0xFFFDE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: Colors.white,
      onSurface: ShopPalette.text,
    );

    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ShopPalette.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ShopPalette.background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: ShopPalette.navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xB3FFFFFF),
        indicatorColor: ShopPalette.orange,
        dividerColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ShopPalette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
          borderSide: const BorderSide(color: ShopPalette.blue, width: 1.5),
        ),
        errorBorder: roundedBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: roundedBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      // Orange is the main call-to-action colour in the M02 hi-fi screens.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ShopPalette.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShopPalette.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ShopPalette.navy,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: ShopPalette.navy),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ShopPalette.blue),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ShopPalette.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: ShopPalette.blueTint,
        side: const BorderSide(color: ShopPalette.border),
        labelStyle: const TextStyle(color: ShopPalette.navy),
        checkmarkColor: ShopPalette.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: ShopPalette.blueTint,
          selectedForegroundColor: ShopPalette.navy,
          side: const BorderSide(color: ShopPalette.border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? ShopPalette.blue : null,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: ShopPalette.border),
    );
  }
}

/// Wraps a screen of the shop/transaction module in [ShopTheme.light].
/// The [builder] receives a context that sits below the theme, so
/// Theme.of(context) inside the screen returns the module theme.
class ShopThemed extends StatelessWidget {
  const ShopThemed({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ShopTheme.light,
      child: Builder(builder: builder),
    );
  }
}
