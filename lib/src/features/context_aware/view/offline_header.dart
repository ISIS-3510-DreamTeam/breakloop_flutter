import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_pill.dart';

//Header shared by the Offline and Activity Detail views
class OfflineHeader extends StatelessWidget {
  final String section;

  const OfflineHeader({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(bottom: BorderSide(color: AppColors.darkCoffee, width: 3)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/board_logo.png', width: 56, height: 56),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BREAKLOOP', style: textTheme.titleLarge?.copyWith(color: AppColors.spicyPaprika, letterSpacing: 3)),
                      Text(section, style: textTheme.labelLarge?.copyWith(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              //Static chips until the shield test and streaks are implemented
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppPill(label: '🛡 Shield Test'),
                  SizedBox(width: 12),
                  AppPill(label: '🔥 12d'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
