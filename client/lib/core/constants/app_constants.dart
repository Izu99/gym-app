class AppConstants {
  static const double sideNavWidth = 240.0;
  static const double topNavHeight = 64.0;
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;

  // Route names
  static const String routeLogin = '/';
  static const String routeRegister = '/register';
  static const String routeDashboard = '/dashboard';
  static const String routeMembers = '/members';
  static const String routeAttendance = '/attendance';
  static const String routePayments = '/payments';

  // API base — change to your server IP/domain when deploying
  static const String apiBase = 'http://localhost:3000/api';
}
