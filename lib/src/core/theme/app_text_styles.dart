import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

//Mono styles for buttons, chips and brand labels
class AppTextStyles {
  AppTextStyles._();

  static final monoLabel = GoogleFonts.spaceMono(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
    color: AppColors.darkCoffee,
  );

  static final monoTitle = GoogleFonts.spaceMono(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
    color: AppColors.darkCoffee,
  );
}
