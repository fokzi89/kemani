import 'dart:async';
// import 'package:powersync/powersync.dart';
import '../database/powersync.dart';

class ConnectivityService {
  // Stream<SyncStatus> get syncStatus => PowerSyncService.db.statusStream;
  Stream<bool> get connected => Stream.value(true);

  bool get isConnected => true; // PowerSyncService.db.currentStatus.connected;

  // You can mix in connectivity_plus if needed for raw network check
}
