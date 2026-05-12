import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_translations.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: cs.primary.withValues(alpha: 0.12),
          surfaceTintColor: Colors.transparent,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: cs.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: cs.primary,
              ),
              label: context.tr('tab_home'),
            ),
            NavigationDestination(
              icon: Icon(
                Icons.visibility_outlined,
                color: cs.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.visibility_rounded,
                color: cs.primary,
              ),
              label: context.tr('tab_tests'),
            ),
            NavigationDestination(
              icon: Icon(
                Icons.history_outlined,
                color: cs.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.history_rounded,
                color: cs.primary,
              ),
              label: context.tr('tab_history'),
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline_rounded,
                color: cs.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: cs.primary,
              ),
              label: context.tr('tab_profile'),
            ),
          ],
        ),
      ),
    );
  }
}
