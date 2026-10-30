import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'app_header.dart';
import '../../features/context_aware/view/active_activity_banner.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  //Current path, to hide the activity banner inside the activity itself
  final String location;
  const MainShell({super.key, required this.navigationShell, required this.location});

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
          //The title is the tab name, also inside child routes like Deep Stats or Activity Detail
          AppHeader(title: _tabs[navigationShell.currentIndex].$1),
          //Activity in progress, like the banner of the Kotlin app
          if (!location.startsWith('/offline/activity/')) const ActiveActivityBanner(),
          Expanded(child: navigationShell)
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navBackground,
        indicatorColor: Colors.transparent,
        selectedIndex: navigationShell.currentIndex,
        //Selected label in golden orange
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.goldenOrange : AppColors.navUnselected,
          );
        }),
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index ==navigationShell.currentIndex,
        ),
        destinations: [
          for (final (label, icon) in _tabs)
            NavigationDestination(
              icon: SvgPicture.asset('assets/icons/nav/$icon.svg', height: 24),
              selectedIcon: SvgPicture.asset('assets/icons/nav/${icon}_selected.svg', height: 24),
              label: label,
            ),
        ],
      ),
    );
  }
}
