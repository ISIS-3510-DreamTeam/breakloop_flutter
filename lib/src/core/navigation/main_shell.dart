
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_header.dart';
import 'package:breakloop_flutter/src/features/focus_session/viewmodel/focus_viewmodel.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final FocusViewModel focusViewModel;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.focusViewModel,
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

  @override
  Widget build(BuildContext context) {
    const titles = [
      'HOME',
      'FOCUS',
      'STATS',
      'OFFLINE',
      'SOCIAL',
    ];

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: titles[widget.navigationShell.currentIndex],
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Stop the sound when leaving the Focus tab
          if (widget.navigationShell.currentIndex == 1 && index != 1) {
            widget.focusViewModel.stopSoundscape();
          }

          widget.navigationShell.goBranch(
            index,
            initialLocation:
                index == widget.navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi_off_outlined),
            selectedIcon: Icon(Icons.wifi_off),
            label: 'Offline',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Social',
          ),
        ],
      ),
    );
  }
}
