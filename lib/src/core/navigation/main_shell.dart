import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import 'app_header.dart';
import '../../features/context_aware/view/active_activity_banner.dart';
import 'package:breakloop_flutter/src/features/focus_session/viewmodel/focus_viewmodel.dart';

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
  }

  // Stops the sound when the app goes to the background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      widget.focusViewModel.stopSoundscape();
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

  return Scaffold(
    body: Column(
      children: [
        // The title is the tab name, also inside child routes
        AppHeader(title: _tabs[widget.navigationShell.currentIndex].$1),
        //Activity in progress, like the banner of the Kotlin app
        if (!widget.location.startsWith('/offline/activity/')) const ActiveActivityBanner(),
        Expanded(child: widget.navigationShell),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: AppColors.navBackground,
      indicatorColor: Colors.transparent,
      selectedIndex: widget.navigationShell.currentIndex,

      // Selected label in golden orange
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium?.copyWith(
          color: selected
              ? AppColors.goldenOrange
              : AppColors.navUnselected,
        );
      }),

      onDestinationSelected: (index) {
        // Stop the sound when leaving the Focus tab
        if (widget.navigationShell.currentIndex == 1 && index != 1) {
          widget.focusViewModel.stopSoundscape();
        }

        widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
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
  );
}}
