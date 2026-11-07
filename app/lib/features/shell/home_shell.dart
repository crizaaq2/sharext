import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/components/sonar_mark.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// Bottom navigation on phones, a rail from 840 px (§6).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const List<String> _destinations = <String>[
    '/around',
    '/chats',
    '/you',
  ];

  int get _index {
    if (location.startsWith('/chats')) return 1;
    if (location.startsWith('/you')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SonarTokens tokens = SonarTokens.of(context);
    final List<({IconData icon, IconData selected, String label})> items =
        <({IconData icon, IconData selected, String label})>[
          (
            icon: Icons.radar_outlined,
            selected: Icons.radar,
            label: l10n.navAround,
          ),
          (
            icon: Icons.chat_bubble_outline,
            selected: Icons.chat_bubble,
            label: l10n.navChats,
          ),
          (
            icon: Icons.person_outline,
            selected: Icons.person,
            label: l10n.navYou,
          ),
        ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= SxBreakpoint.rail;
        if (wide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (int i) =>
                      context.go(_destinations[i]),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: SxSpace.x4),
                    child: SonarMark(size: 40),
                  ),
                  destinations: <NavigationRailDestination>[
                    for (final item in items)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selected, color: tokens.primary),
                        label: Text(item.label),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: tokens.raised),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (int i) => context.go(_destinations[i]),
            destinations: <Widget>[
              for (final item in items)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selected, color: tokens.primary),
                  label: item.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
