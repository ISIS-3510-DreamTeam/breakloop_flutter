import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import 'app_header.dart';
import '../../features/context_aware/view/active_activity_banner.dart';
import 'package:breakloop_flutter/src/features/focus_session/viewmodel/focus_viewmodel.dart';
import '../../features/focus_session/view/focus_recovery_dialog.dart';
import '../../features/focus_session/view/focus_completion_dialog.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final FocusViewModel focusViewModel;
  //Current path, to hide the activity banner inside the activity itself
  final String location;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.focusViewModel,
    required this.location,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with WidgetsBindingObserver {

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  // Check for an unfinished focus session when MainShell opens
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      widget.focusViewModel.restoreActiveSession();
    }
  });
}

  // Stops the sound when the app goes to the background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      widget.focusViewModel.stopSoundscape();
    }

    if (state == AppLifecycleState.resumed) {
      widget.focusViewModel.restoreActiveSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //Label and pixel-art icon of each tab, in the same order as the router branches
  static const _tabs = [
    ('Home', 'hearth'),
    ('Focus', 'focus'),
    ('Stats', 'stats'),
    ('Offline', 'offline'),
    ('Friends', 'friends'),
  ];

 
@override
Widget build(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;

  return ListenableBuilder(
    listenable: widget.focusViewModel,
    builder: (context, _) {
      final isRecoveryPending =
          widget.focusViewModel.state.isRecoveryPending;
      
      final isCompletionPending =
          widget.focusViewModel.state.isCompletionPending;
    
    

      return Stack(
        children: [
          // Main application
          Scaffold(
            body: Column(
              children: [
                AppHeader(
                  title: _tabs[widget.navigationShell.currentIndex].$1,
                ),
                if (!widget.location.startsWith('/offline/activity/'))
                  const ActiveActivityBanner(),
                Expanded(
                  child: widget.navigationShell,
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              backgroundColor: AppColors.navBackground,
              indicatorColor: Colors.transparent,
              selectedIndex: widget.navigationShell.currentIndex,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected =
                    states.contains(WidgetState.selected);

                return textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppColors.goldenOrange
                      : AppColors.navUnselected,
                );
              }),
              onDestinationSelected: (index) {
                if (widget.navigationShell.currentIndex == 1 &&
                    index != 1) {
                  widget.focusViewModel.stopSoundscape();
                }

                widget.navigationShell.goBranch(
                  index,
                  initialLocation:
                      index == widget.navigationShell.currentIndex,
                );
              },
              destinations: [
                for (final (label, icon) in _tabs)
                  NavigationDestination(
                    icon: SvgPicture.asset(
                      'assets/icons/nav/$icon.svg',
                      height: 24,
                    ),
                    selectedIcon: SvgPicture.asset(
                      'assets/icons/nav/${icon}_selected.svg',
                      height: 24,
                    ),
                    label: label,
                  ),
              ],
            ),
          ),

           // Recovery overlay
          if (isRecoveryPending) ...[
            const Positioned.fill(
              child: ModalBarrier(
                dismissible: false,
                color: Colors.black54,
              ),
            ),

            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FocusRecoveryDialog(
                    viewModel: widget.focusViewModel,
                    onRecoveryResolved: () {
                      widget.navigationShell.goBranch(1);
                    },
                  ),
                ),
              ),
            ),
          ],

          // Completion overlay
          if (isCompletionPending) ...[
            const Positioned.fill(
              child: ModalBarrier(
                dismissible: false,
                color: Colors.black54,
              ),
            ),

            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FocusCompletionDialog(
                    viewModel: widget.focusViewModel,
                    onContinue: () {
                      widget.navigationShell.goBranch(1);
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
}