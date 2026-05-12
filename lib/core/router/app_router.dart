import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/history/screens/history_detail_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/manual_entry/screens/manual_entry_screen.dart';
import '../../features/onboarding/screens/about_screen.dart';
import '../../features/onboarding/screens/patient_intake_screen.dart';
import '../../features/onboarding/screens/setup_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/profile/screens/profile_edit_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/tips/screens/tips_screen.dart';
import '../../features/vision_test/screens/astigmatism_test_screen.dart';
import '../../features/vision_test/screens/test_picker_screen.dart';
import '../../features/vision_test/screens/vision_test_screen.dart';
import '../../features/settings/screens/calibration_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/setup', builder: (_, __) => const SetupScreen()),
    GoRoute(
        path: '/patient-intake',
        builder: (_, __) => const PatientIntakeScreen()),
    GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),

    // Bottom-nav shell
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tests',
              builder: (_, __) => const TestPickerScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (_, __) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Top-level (pushed) routes
    GoRoute(
      path: '/vision-test',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const VisionTestScreen(),
    ),
    GoRoute(
      path: '/astigmatism-test',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const AstigmatismTestScreen(),
    ),
    GoRoute(
      path: '/manual-entry',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const ManualEntryScreen(),
    ),
    GoRoute(
      path: '/history/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          HistoryDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/profile-edit',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/calibration',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const CalibrationScreen(),
    ),
    GoRoute(
      path: '/tips',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const TipsScreen(),
    ),
  ],
);
