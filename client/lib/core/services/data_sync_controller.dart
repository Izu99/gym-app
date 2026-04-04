import 'package:flutter/foundation.dart';

enum DataRefreshEvent { members, payments, attendance, tiers }

class DataSyncController extends ChangeNotifier {
  static final DataSyncController _instance = DataSyncController._internal();
  factory DataSyncController() => _instance;
  DataSyncController._internal();

  void notify(DataRefreshEvent event) {
    if (kDebugMode) {
      print('DATA REFRESH: $event');
    }
    notifyListeners();
  }
}

final dataSync = DataSyncController();
