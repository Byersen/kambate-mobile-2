import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/realtime_service.dart';
import '../../../services/supabase_service.dart';

enum ConnectionStatus {
  liveConnected,
  syncing,
  offlineCached,
}

final connectionStatusProvider = StateNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>((ref) {
  return ConnectionStatusNotifier();
});

class ConnectionStatusNotifier extends StateNotifier<ConnectionStatus> {
  ConnectionStatusNotifier() : super(ConnectionStatus.liveConnected) {
    _init();
  }

  void _init() {
    if (SupabaseService.isInitialized) {
      state = ConnectionStatus.liveConnected;
    }

    final realtime = RealtimeService();
    _mapState(realtime.currentState);

    realtime.onConnectionStateChanged.listen((realtimeState) {
      _mapState(realtimeState);
    });
  }

  void _mapState(RealtimeConnectionState realtimeState) {
    switch (realtimeState) {
      case RealtimeConnectionState.connected:
        state = ConnectionStatus.liveConnected;
        break;
      case RealtimeConnectionState.connecting:
        state = ConnectionStatus.syncing;
        break;
      case RealtimeConnectionState.disconnected:
      case RealtimeConnectionState.offline:
        state = ConnectionStatus.offlineCached;
        break;
    }
  }

  void setOffline() {
    state = ConnectionStatus.offlineCached;
  }

  void setSyncing() {
    state = ConnectionStatus.syncing;
  }

  void setConnected() {
    state = ConnectionStatus.liveConnected;
  }
}
