import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _serif = 'PlayfairDisplay';

  // Display / Headlines (Playfair Display)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _serif,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _serif,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.25,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _serif,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _serif,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.35,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _serif,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.4,
  );

  // Body (system default / sans)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.inkLight,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: 0.3,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.inkLight,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.inkFaint,
    letterSpacing: 0.2,
  );
}
