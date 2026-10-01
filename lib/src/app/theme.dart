// app/theme.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

final appColorScheme = const ColorScheme.light(
  primary: AppColors.spicyPaprika,
  onPrimary: AppColors.snow,
  secondary: AppColors.goldenOrange,
  onSecondary: AppColors.darkCoffee,
  tertiary: AppColors.fern,
  onTertiary: AppColors.snow,
  surface: AppColors.snow,
  onSurface: AppColors.darkCoffee,
  error: AppColors.spicyPaprika,
  onError: AppColors.snow,
);

final appTextTheme = TextTheme(
  // Titles and labels- Space Mono
  headlineLarge: GoogleFonts.spaceMono(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkCoffee),
  headlineMedium: GoogleFonts.spaceMono(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkCoffee),
  titleLarge: GoogleFonts.spaceMono(fontSize: 21, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.darkCoffee),
  labelLarge: GoogleFonts.spaceMono(fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.darkCoffee),

  // Body — Plus Jakarta Sans
  bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 19, color: AppColors.darkCoffee),
  bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 17, color: AppColors.darkCoffee),
);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: appColorScheme,
  scaffoldBackgroundColor: AppColors.snow,
  textTheme: appTextTheme,
);