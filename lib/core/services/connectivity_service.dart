import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  StreamSubscription? _subscription;
  bool _wasOffline = false;

  void startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;

      if (isOnline && _wasOffline) {
        print('🌐 Connexion rétablie !');
        // Synchroniser les données en attente
        _db.syncPendingData().then((_) {
          if (_db.hasPendingSync()) {
            print('⚠️ Données toujours en attente, nouvelle tentative dans 30s...');
            Future.delayed(const Duration(seconds: 30), () => _db.syncPendingData());
          }
        });
      }

      _wasOffline = !isOnline;
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
  }
}
