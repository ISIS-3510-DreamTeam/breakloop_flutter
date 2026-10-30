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

//Space Mono for display and headlines, Plus Jakarta Sans for the rest.
TextStyle _mono(double size, FontWeight weight, double lineHeight, {double letterSpacing = 0}) {
  return GoogleFonts.spaceMono(
    fontSize: size,
    fontWeight: weight,
    height: lineHeight / size,
    letterSpacing: letterSpacing,
    color: AppColors.darkCoffee,
  );
}

TextStyle _jakarta(double size, FontWeight weight, double lineHeight, {double letterSpacing = 0}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    height: lineHeight / size,
    letterSpacing: letterSpacing,
    color: AppColors.darkCoffee,
  );
}

final appTextTheme = TextTheme(
  displayLarge: _mono(57, FontWeight.bold, 64, letterSpacing: -0.25),
  displayMedium: _mono(40, FontWeight.bold, 48),
  displaySmall: _mono(25, FontWeight.normal, 32),

  headlineLarge: _mono(32, FontWeight.bold, 40),
  headlineMedium: _mono(28, FontWeight.bold, 36),
  headlineSmall: _mono(24, FontWeight.w500, 32),

  titleLarge: _jakarta(22, FontWeight.bold, 28),
  titleMedium: _jakarta(16, FontWeight.w500, 24, letterSpacing: 0.15),
  titleSmall: _jakarta(14, FontWeight.w500, 20, letterSpacing: 0.1),

  bodyLarge: _jakarta(16, FontWeight.normal, 24, letterSpacing: 0.5),
  bodyMedium: _jakarta(14, FontWeight.normal, 20, letterSpacing: 0.25),
  bodySmall: _jakarta(12, FontWeight.normal, 16, letterSpacing: 0.4),

  labelLarge: _jakarta(14, FontWeight.w500, 20, letterSpacing: 0.1),
  labelMedium: _jakarta(12, FontWeight.w500, 16, letterSpacing: 0.5),
  labelSmall: _jakarta(11, FontWeight.w500, 16, letterSpacing: 0.5),
);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: appColorScheme,
  scaffoldBackgroundColor: AppColors.snow,
  textTheme: appTextTheme,
);
