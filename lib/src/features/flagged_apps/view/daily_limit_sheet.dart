import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../viewmodel/flagged_apps_ui_state.dart';
import 'app_icon.dart';

const _defaultMinutes = 30;

//Bottom sheet to choose the daily limit of a flagged app
class DailyLimitSheet extends StatefulWidget {
  final FlaggedAppRow row;
  final VoidCallback onDismiss;
  final void Function(int hours, int minutes, bool noLimit) onSave;

  const DailyLimitSheet({super.key, required this.row, required this.onDismiss, required this.onSave});

  @override
  State<DailyLimitSheet> createState() => _DailyLimitSheetState();
}

class _DailyLimitSheetState extends State<DailyLimitSheet> {
  late bool _noLimit;
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    final currentLimit = widget.row.flagged?.dailyLimitMin;
    _noLimit = currentLimit == null;
    _hours = (currentLimit ?? _defaultMinutes) ~/ 60;
    _minutes = (currentLimit ?? _defaultMinutes) % 60;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unitStyle = textTheme.titleMedium?.copyWith(color: AppColors.neutral700);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AppIcon(packageName: widget.row.app.packageName, label: widget.row.app.label, size: 44),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.row.app.label, style: textTheme.titleMedium),
                    Text('Daily limit', style: textTheme.bodySmall?.copyWith(color: AppColors.neutral700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(child: Text('No limit', style: textTheme.bodyLarge)),
                  Switch(
                    value: _noLimit,
                    onChanged: (value) => setState(() => _noLimit = value),
                    activeTrackColor: AppColors.spicyPaprika,
                    activeThumbColor: AppColors.snow,
                    inactiveTrackColor: AppColors.neutral100,
                    inactiveThumbColor: AppColors.neutral500,
                    trackOutlineColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected) ? null : AppColors.neutral200,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: _noLimit ? 0.35 : 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _WheelPicker(max: 23, initialValue: _hours, enabled: !_noLimit, onChanged: (value) => _hours = value),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('h', style: unitStyle)),
                  const SizedBox(width: 16),
                  _WheelPicker(max: 59, initialValue: _minutes, enabled: !_noLimit, onChanged: (value) => _minutes = value),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('min', style: unitStyle)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: widget.onDismiss,
                    child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: AppColors.neutral700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(label: 'Save', onPressed: () => widget.onSave(_hours, _minutes, _noLimit)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//iOS-style wheel from 0 to max, with the selected value highlighted in the middle
class _WheelPicker extends StatefulWidget {
  final int max;
  final int initialValue;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _WheelPicker({required this.max, required this.initialValue, required this.enabled, required this.onChanged});

  @override
  State<_WheelPicker> createState() => _WheelPickerState();
}

class _WheelPickerState extends State<_WheelPicker> {
  static const _itemHeight = 40.0;
  static const _visibleItems = 5;

  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    _controller = FixedExtentScrollController(initialItem: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 88,
      height: _itemHeight * _visibleItems,
      child: Stack(
        alignment: Alignment.center,
        children: [
          //Selection band
          Container(
            height: _itemHeight,
            decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(10)),
          ),
          IgnorePointer(
            ignoring: !widget.enabled,
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: _itemHeight,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() => _selected = index);
                widget.onChanged(index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.max + 1,
                builder: (context, index) {
                  final selected = index == _selected;
                  return Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: selected
                          ? textTheme.headlineSmall
                          : textTheme.titleMedium?.copyWith(color: AppColors.neutral500),
                    ),
                  );
                },
              ),
            ),
          ),
          //Fade at the top and the bottom
          IgnorePointer(
            child: Column(
              children: [
                _fade(Alignment.topCenter, Alignment.bottomCenter),
                const Spacer(),
                _fade(Alignment.bottomCenter, Alignment.topCenter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fade(Alignment begin, Alignment end) {
    return Container(
      height: _itemHeight * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [AppColors.snow, AppColors.snow.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
