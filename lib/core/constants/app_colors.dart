import 'package:flutter/material.dart';

/// Centralized color palette for GearGo application.
class AppColors {
  AppColors._();

  // Primary brand palette
  static const Color primary = Color(0xFF1E50FF); // Electric Blue
  static const Color primaryLight = Color(0xFF4E77FF);
  static const Color primaryDark = Color(0xFF0F32B8);

  // Secondary accent
  static const Color secondary = Color(0xFFFF8A00); // Amber orange
  static const Color secondaryLight = Color(0xFFFFAE42);

  // Status & Feedback colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutrals - Light Theme
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Neutrals - Dark Theme
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF151C2C);
  static const Color borderDark = Color(0xFF26324D);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Social Brand Colors
  static const Color googleRed = Color(0xFFEA4335);
  static const Color anonymousGrey = Color(0xFF64748B);
}
