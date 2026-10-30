import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/goals/viewmodel/goals_viewmodel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

//Top bar shared by all the tabs
class AppHeader extends StatelessWidget {
  final String title;

  const AppHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final goalsVm = context.watch<GoalsViewModel>();
    final streak = goalsVm.goal.currentStreak;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.snow,
        border: Border(bottom: BorderSide(color: AppColors.darkCoffee, width: 2)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                Image.asset('assets/images/logo_name.png', width: 36, height: 36),
                const SizedBox(width: 10),
                Expanded(child: Text(title.toUpperCase(), style: AppTextStyles.monoLabel)),
                //Static shield badge until the shield test is implemented
                const _HeaderBadge(icon: 'assets/icons/shield.svg'),
                const SizedBox(width: 6),
                _HeaderBadge(icon: 'assets/icons/streak.svg', text: '${streak}d'),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20, color: AppColors.neutral700),
                  tooltip: 'Sign out',
                  onPressed: () => context.read<AuthRepository>().signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String icon;
  final String? text;

  const _HeaderBadge({required this.icon, this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.darkCoffee, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(AppColors.darkCoffee, BlendMode.srcIn),
          ),
          if (text != null) ...[
            const SizedBox(width: 4),
            Text(text!, style: AppTextStyles.monoLabel),
          ],
        ],
      ),
    );
  }
}
