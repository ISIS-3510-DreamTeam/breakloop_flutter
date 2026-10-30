import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

//Small bordered label with a hard bottom shadow, used for status chips and compact buttons
class AppPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  //Smaller padding and text, for buttons inside compact cards
  final bool small;

  const AppPill({
    super.key,
    required this.label,
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkCoffee, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.darkCoffee,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.spicyPaprika,
          fontSize: small ? 11 : 13,
          letterSpacing: 0,
        ),
      ),
    );

    if (onTap == null) {
      return pill;
    }
    return GestureDetector(onTap: onTap, child: pill);
  }
}
