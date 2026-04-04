import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/kinetic_logo.dart';
import '../../core/services/data_sync_controller.dart';
import '../../features/members/widgets/add_member_dialog.dart';
import '../../data/services/auth_service.dart';

import '../widgets/custom_top_bar.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  void _showAddMember(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddMemberDialog(),
    );
    if (result == true) {
      if (mounted) {
        dataSync.notify(DataRefreshEvent.members);
        final router = GoRouter.of(context);
        router.refresh();
      }
    }
  }

  void _handleLogout(BuildContext context) async {
    await AuthService.logout();
    if (mounted) context.go(AppConstants.routeLogin);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;
    final String routeName = widget.currentRoute.split('/').last.replaceAll('_', ' ').toUpperCase();
    final String displayTitle = routeName.isEmpty ? 'DASHBOARD' : routeName;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Row(
          children: [
            _SideNav(
              currentRoute: widget.currentRoute,
              onAddMember: () => _showAddMember(context),
              onLogout: () => _handleLogout(context),
            ),
            Expanded(
              child: Column(
                children: [
                  CustomTopBar(
                    title: displayTitle,
                    actions: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined,
                            color: AppColors.onSurfaceVariant),
                        splashRadius: 24,
                      ),
                      IconButton(
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(Icons.settings_outlined,
                            color: AppColors.onSurfaceVariant),
                        splashRadius: 24,
                      ),
                      const SizedBox(width: 8),
                      _UserAvatar(),
                    ],
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: CustomTopBar(
        title: displayTitle,
        leading: const KineticLogo(),
        height: AppConstants.topNavHeight,
      ),
      body: widget.child,
      bottomNavigationBar: _MobileBottomNav(currentRoute: widget.currentRoute),
    );
  }
}

class _SideNav extends StatelessWidget {
  final String currentRoute;
  final VoidCallback onAddMember;
  final VoidCallback onLogout;
  const _SideNav({
    required this.currentRoute,
    required this.onAddMember,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.sideNavWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: Color(0x1A484847), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    AuthService.user?['companyName']?.toString().toUpperCase() ?? 'IRON PULSE',
                    style: GoogleFonts.syncopate(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.primaryContainer, letterSpacing: -0.5,
                    ),
                  ),
                Text(
                  'ELITE PERFORMANCE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8, fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant, letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: AppConstants.routeDashboard,
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.group_outlined,
                    label: 'Members',
                    route: AppConstants.routeMembers,
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.fact_check_outlined,
                    label: 'Attendance',
                    route: AppConstants.routeAttendance,
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.payments_outlined,
                    label: 'Payments',
                    route: AppConstants.routePayments,
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: '/settings',
                    currentRoute: currentRoute,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddMember,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('ADD MEMBER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.lexend(
                        fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0x1A484847)),
                _NavItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  route: AppConstants.routeLogin,
                  currentRoute: currentRoute,
                  isDestructive: true,
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => context.go(route),
          borderRadius: BorderRadius.circular(2),
          hoverColor: isActive
              ? AppColors.primaryContainer.withOpacity(0.9)
              : AppColors.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? AppColors.onPrimaryContainer
                      : isDestructive
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    color: isActive
                        ? AppColors.onPrimaryContainer
                        : isDestructive
                            ? AppColors.error
                            : AppColors.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        (AuthService.user?['name'] as String?)?.substring(0, 2).toUpperCase() ??
            'OW',
        style: GoogleFonts.lexend(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryContainer,
        ),
      ),
    );
  }
}


class _MobileBottomNav extends StatelessWidget {
  final String currentRoute;
  const _MobileBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0x1A484847))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.dashboard_outlined,
            label: 'HOME',
            route: AppConstants.routeDashboard,
            currentRoute: currentRoute,
          ),
          _BottomNavItem(
            icon: Icons.group_outlined,
            label: 'MEMBERS',
            route: AppConstants.routeMembers,
            currentRoute: currentRoute,
          ),
          _BottomNavItem(
            icon: Icons.fact_check_outlined,
            label: 'ATTEND',
            route: AppConstants.routeAttendance,
            currentRoute: currentRoute,
          ),
          _BottomNavItem(
            icon: Icons.payments_outlined,
            label: 'PAYMENTS',
            route: AppConstants.routePayments,
            currentRoute: currentRoute,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _BottomNavItem({
    required this.icon, required this.label,
    required this.route, required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22,
            color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceVariant),
          const SizedBox(height: 2),
          Text(label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 8, fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
              letterSpacing: 1,
            )),
        ],
      ),
    );
  }
}
