import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../viewmodel/flagged_apps_ui_state.dart';
import '../viewmodel/flagged_apps_viewmodel.dart';
import 'app_icon.dart';
import 'daily_limit_sheet.dart';

//Screen to choose the distracting apps and their daily limit
class FlaggedAppsPage extends StatefulWidget {
  const FlaggedAppsPage({super.key});

  @override
  State<FlaggedAppsPage> createState() => _FlaggedAppsPageState();
}

class _FlaggedAppsPageState extends State<FlaggedAppsPage> {
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<FlaggedAppsViewModel>().onScreenOpened();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FlaggedAppsViewModel>();
    final state = vm.uiState;
    final textTheme = Theme.of(context).textTheme;

    //The sheet is opened when the ViewModel says an app is being edited
    if (state is FlaggedAppsContent && state.editing != null && !_sheetOpen) {
      _sheetOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLimitSheet(vm, state.editing!));
    }

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.darkCoffee),
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                ),
                Text('DISTRACTING APPS', style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose your focus apps', style: textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  "Pick the apps you'd like to use more intentionally, then set a daily limit that feels right.",
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state) {
              FlaggedAppsLoading() => const Center(child: CircularProgressIndicator(color: AppColors.spicyPaprika)),
              FlaggedAppsEmpty() => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      "We couldn't find any apps to choose from. Install a few and come back.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
                    ),
                  ),
                ),
              FlaggedAppsContent content => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: content.rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.neutral100),
                  itemBuilder: (context, index) => _AppRow(
                    key: ValueKey(content.rows[index].app.packageName),
                    row: content.rows[index],
                    onCheckboxClick: () => vm.onCheckboxClick(content.rows[index]),
                    onEditClick: () => vm.onEditClick(content.rows[index]),
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showLimitSheet(FlaggedAppsViewModel vm, FlaggedAppRow row) async {
    var saved = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.snow,
      showDragHandle: true,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        //The app icon in the sheet reads the same ViewModel
        value: vm,
        child: DailyLimitSheet(
          row: row,
          onDismiss: () => Navigator.of(sheetContext).pop(),
          onSave: (hours, minutes, noLimit) {
            saved = true;
            Navigator.of(sheetContext).pop();
            vm.onLimitSave(hours, minutes, noLimit);
          },
        ),
      ),
    );
    //Closing the sheet in any other way (back, tap outside) cancels the edit
    if (!saved) vm.onDismissEdit();
    _sheetOpen = false;
  }
}

class _AppRow extends StatelessWidget {
  final FlaggedAppRow row;
  final VoidCallback onCheckboxClick;
  final VoidCallback onEditClick;

  const _AppRow({super.key, required this.row, required this.onCheckboxClick, required this.onEditClick});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final flagged = row.flagged != null;

    return InkWell(
      onTap: onCheckboxClick,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              AppIcon(packageName: row.app.packageName, label: row.app.label, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.app.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                    if (flagged)
                      GestureDetector(
                        onTap: onEditClick,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 32),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${formatDailyLimit(row.flagged?.dailyLimitMin)} · Edit',
                              style: textTheme.labelMedium?.copyWith(color: AppColors.paprika700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Checkbox(
                value: flagged,
                onChanged: (_) => onCheckboxClick(),
                activeColor: AppColors.spicyPaprika,
                checkColor: AppColors.snow,
                side: const BorderSide(color: AppColors.neutral500, width: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
