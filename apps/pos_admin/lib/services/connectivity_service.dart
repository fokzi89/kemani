import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  /// Stream of connectivity changes (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
        print('Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      }
    });
  }

  void dispose() {
    _connectivityController.close();
  }
}
