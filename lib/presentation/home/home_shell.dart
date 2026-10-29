import 'package:flutter/material.dart';

import '../../core/breakpoints.dart';
import '../history/history_screen.dart';
import '../today/today_screen.dart';

/// Top-level navigation: a bottom bar on phones, a rail on larger windows.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    (
      icon: Icon(Icons.water_drop_outlined),
      selectedIcon: Icon(Icons.water_drop),
      label: 'Today',
    ),
    (
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'History',
    ),
  ];

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final useRail = MediaQuery.sizeOf(context).width >= Breakpoints.medium;

    // IndexedStack keeps each tab's scroll position and state.
    final body = IndexedStack(
      index: _index,
      children: const [TodayScreen(), HistoryScreen()],
    );

    if (!useRail) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            groupAlignment: -0.9,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                ),
            ],
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
