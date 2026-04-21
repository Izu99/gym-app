import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/members/screens/members_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/layouts/app_shell.dart';
import 'app_constants.dart';

final appRouter = GoRouter(
  initialLocation: AppConstants.routeLogin,
  routes: [
    GoRoute(
      path: AppConstants.routeLogin,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(currentRoute: state.matchedLocation, child: child),
      routes: [
        GoRoute(
          path: AppConstants.routeDashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppConstants.routeMembers,
          builder: (context, state) => const MembersScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAttendance,
          builder: (context, state) => const AttendanceScreen(),
        ),
        GoRoute(
          path: AppConstants.routePayments,
          builder: (context, state) => const PaymentsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
