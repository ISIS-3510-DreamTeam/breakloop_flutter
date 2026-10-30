import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../viewmodel/flagged_apps_ui_state.dart';
import '../viewmodel/flagged_apps_viewmodel.dart';
import 'app_icon.dart';

const _maxVisibleApps = 5;

//"Tamed distraction loops" card of the Stats screen
class FlaggedAppsCard extends StatelessWidget {
  const FlaggedAppsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = context.watch<FlaggedAppsViewModel>().flaggedRows;
    void openScreen() => context.push('/stats/flagged-apps');

    return GestureDetector(
      //Only the empty card opens the screen with a tap anywhere
      onTap: rows != null && rows.isEmpty ? openScreen : null,
      child: AppCard(
        child: switch (rows) {
          null => _buildSkeleton(),
          [] => _buildPlaceholder(context, openScreen),
          _ => _buildList(context, rows, openScreen),
        },
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lock_reset_outlined, size: 16, color: AppColors.neutral700),
        const SizedBox(width: 6),
        Text(
          'TAMED DISTRACTION LOOPS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.neutral700),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context, VoidCallback onConfigure) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(context),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.golden100, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.tune, size: 26, color: AppColors.goldenOrange),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set limits per app', style: textTheme.titleMedium),
                  Text(
                    'Choose the apps you want to use more intentionally.',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppButton(label: 'Set up', onPressed: onConfigure),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<FlaggedAppRow> rows, VoidCallback onConfigure) {
    final textTheme = Theme.of(context).textTheme;
    final visible = rows.take(_maxVisibleApps).toList();
    final hidden = rows.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTitle(context)),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.darkCoffee),
              tooltip: 'Configure distracting apps',
              onPressed: onConfigure,
            ),
          ],
        ),
        for (var i = 0; i < visible.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                AppIcon(packageName: visible[i].app.packageName, label: visible[i].app.label, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    visible[i].app.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatDailyLimit(visible[i].flagged?.dailyLimitMin),
                  style: textTheme.labelMedium?.copyWith(
                    color: visible[i].flagged?.dailyLimitMin == null ? AppColors.neutral700 : AppColors.paprika700,
                  ),
                ),
              ],
            ),
          ),
          if (i != visible.length - 1) const Divider(height: 1, color: AppColors.neutral100),
        ],
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('+$hidden more', style: textTheme.labelMedium?.copyWith(color: AppColors.neutral700)),
          ),
      ],
    );
  }

  //Gray blocks while the apps load
  Widget _buildSkeleton() {
    Widget block(double? width, double height, double radius) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(radius)),
      );
    }

    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(context),
          for (var i = 0; i < 3; i++) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                block(40, 40, 10),
                const SizedBox(width: 12),
                Expanded(child: block(null, 14, 7)),
                const SizedBox(width: 12),
                block(48, 14, 7),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
