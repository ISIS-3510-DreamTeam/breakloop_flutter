import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/goals/viewmodel/goals_viewmodel.dart';
import '../theme/app_colors.dart';
import '../widgets/app_pill.dart';



class AppHeader extends StatelessWidget {
  final String title;

  const AppHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final goalsVm = context.watch<GoalsViewModel>();
    final streak = goalsVm.goal.currentStreak;

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
          child: Stack(
            children: [
              Column(
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
                          Text(title, style: textTheme.labelLarge?.copyWith(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  //Static chips until the shield test and streaks are implemented
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppPill(label: '🛡 Shield Test'),
                      SizedBox(width: 12),
                      AppPill(label: '🔥 ${streak}d'),
                    ],
                  ),
                ],
              ),
              Positioned(
                  top: 55,
                  right: -15,
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AuthRepository>().signOut(),
                  )
              )
            ],
          )
        ),
      ),
    );
  }
}

