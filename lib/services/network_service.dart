import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'sync_service.dart';

/// Monitors network connectivity and notifies listeners of changes.
/// Use `NetworkService.instance.isOnline` to check status anywhere.
class NetworkService extends ChangeNotifier {
  static final NetworkService instance = NetworkService._();
  NetworkService._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  StreamSubscription? _connectivitySub;

  Future<void> initialize() async {
    // Initial check
    _isOnline = await _checkInternet();

    // Listen for connectivity changes
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
      final wasOnline = _isOnline;
      _isOnline = await _checkInternet();
      if (wasOnline != _isOnline) {
        notifyListeners();
        if (_isOnline) {
          // Trigger sync when back online
          debugPrint('NetworkService: Back online — triggering sync');
          SyncService.instance.syncPendingActions();
        }
      }
    });
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
