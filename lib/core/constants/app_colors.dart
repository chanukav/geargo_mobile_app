import 'package:flutter/material.dart';

/// Centralized color palette for GearGo application.
class AppColors {
  AppColors._();

  // Official GearGo Brand Guide
  static const Color deepNavy = Color(0xFF123B5D); // Header, navbar, footer, headings, important text (40%)
  static const Color blue = Color(0xFF2F80ED);     // Primary buttons, links, active states, icons (35%)
  static const Color orange = Color(0xFFFF8A3D);   // Main CTA, highlights, badges, important actions (10%)
  static const Color white = Color(0xFFFFFFFF);    // Cards, navbar text, input areas (10%)
  static const Color lightGray = Color(0xFFF6F8FA);// Main page background (5%)

  // Primary brand palette
  static const Color primary = blue;
  static const Color primaryLight = Color(0xFF5BA2F4);
  static const Color primaryDark = deepNavy;

  // Secondary accent
  static const Color secondary = orange;
  static const Color secondaryLight = Color(0xFFFFA768);

  // Status & Feedback colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = blue;

  // Neutrals - Light Theme
  static const Color backgroundLight = lightGray;
  static const Color surfaceLight = white;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = deepNavy;
  static const Color textSecondaryLight = Color(0xFF5A6E82);
  static const Color textMutedLight = Color(0xFF8E9BAE);

  // Neutrals - Dark Theme
  static const Color backgroundDark = Color(0xFF0C1622);
  static const Color surfaceDark = Color(0xFF132337);
  static const Color borderDark = Color(0xFF1E3550);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Social Brand Colors
  static const Color googleRed = Color(0xFFEA4335);
  static const Color anonymousGrey = Color(0xFF64748B);
}
