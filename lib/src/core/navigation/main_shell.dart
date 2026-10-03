import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_header.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

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
          AppHeader(title: titles[navigationShell.currentIndex]),
          Expanded(child: navigationShell)
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index ==navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Focus'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.wifi_off_outlined), selectedIcon: Icon(Icons.wifi_off), label: 'Offline'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Social'),
        ],
      ),
    );
  }
}