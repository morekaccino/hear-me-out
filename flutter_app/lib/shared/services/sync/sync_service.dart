import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum SyncStatus { online, offline, syncing, error }

class SyncService {
  final Connectivity _connectivity = Connectivity();
  SyncStatus _status = SyncStatus.online;
  StreamSubscription? _connectivitySubscription;

  SyncStatus get status => _status;

  Stream<SyncStatus> get statusStream =>
      _connectivity.onConnectivityChanged.map((List<ConnectivityResult> results) {
        if (results.contains(ConnectivityResult.none)) {
          _status = SyncStatus.offline;
        } else if (_status == SyncStatus.offline) {
          _status = SyncStatus.online;
          _performSync();
        }
        return _status;
      });

  void startMonitoring() {
    _connectivitySubscription = statusStream.listen((_) {});
  }

  Future<void> _performSync() async {
    _status = SyncStatus.syncing;
    try {
      // TODO: Pull latest from Firestore, merge with local
      // TODO: Push pending local changes
      // For now: Firestore wins on conflicts, except streak data (local wins)
      _status = SyncStatus.online;
    } catch (e) {
      _status = SyncStatus.error;
    }
  }

  Future<void> syncNow() async {
    if (_status == SyncStatus.online) {
      await _performSync();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

final syncService = SyncService();
