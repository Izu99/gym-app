import 'package:flutter/foundation.dart';

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

  // Toggle: true = VPS, false = localhost (only affects debug builds)
  static const bool useVpsInDebug = false;

  static const String _vpsBase = 'http://82.25.180.20/gym/api';
  static const String _localBase = 'http://localhost:5000/api';

  static String get apiBase =>
      (!kDebugMode || useVpsInDebug) ? _vpsBase : _localBase;
}
