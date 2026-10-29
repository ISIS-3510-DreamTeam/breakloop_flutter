import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.spicyPaprika,
          foregroundColor: AppColors.snow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: AppColors.darkCoffee, width: 2.5),
          ),
          elevation: 0,
        ),
        child: loading
          ? const SizedBox(
            height: 18, width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.snow),
          )
          : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.snow)),
            ],
          ),
      ),
    );
  }
}