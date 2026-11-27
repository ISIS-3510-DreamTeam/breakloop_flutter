import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Note shown while something is waiting to reach the cloud.
/// Shows only the icon by default. Tapping it expands the full message.
class PendingSyncNote extends StatefulWidget {
  const PendingSyncNote({super.key, required this.message});

  final String message;

  @override
  State<PendingSyncNote> createState() => _PendingSyncNoteState();
}

class _PendingSyncNoteState extends State<PendingSyncNote> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: widget.message,
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.golden100,
                border: Border.all(color: AppColors.darkCoffee, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: AppColors.darkCoffee,
                  ),
                  if (_expanded) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: AppColors.darkCoffee,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}