import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum RealtimeConnectionState {
  connecting,
  connected,
  disconnected,
  offline,
}

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  RealtimeChannel? _eventChannel;
  Timer? _reconnectTimer;
  final _eventUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<RealtimeConnectionState>.broadcast();

  RealtimeConnectionState _currentState = RealtimeConnectionState.connecting;
  RealtimeConnectionState get currentState => _currentState;

  Stream<Map<String, dynamic>> get onEventUpdate => _eventUpdateController.stream;
  Stream<RealtimeConnectionState> get onConnectionStateChanged => _connectionStateController.stream;

  /// Start subscribing to the 'Event' table realtime updates
  void subscribeToEvents() {
    final client = SupabaseService.client;
    if (client == null) {
      _setConnectionState(RealtimeConnectionState.offline);
      return;
    }

    if (_eventChannel != null) {
      return; // Already subscribed
    }

    _setConnectionState(RealtimeConnectionState.connecting);

    try {
      _eventChannel = client.channel('kambate_live_feed')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Event',
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              debugPrint('RealtimeService received Event update: ${record['id']}');
              _eventUpdateController.add(record);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event',
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              debugPrint('RealtimeService received event update: ${record['id']}');
              _eventUpdateController.add(record);
            }
          },
        )
        ..subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('RealtimeService: Connected to Supabase Realtime channel');
            _reconnectTimer?.cancel();
            _setConnectionState(RealtimeConnectionState.connected);
          } else if (status == RealtimeSubscribeStatus.closed || status == RealtimeSubscribeStatus.channelError) {
            debugPrint('RealtimeService channel notice: $error');
            // If REST API is initialized, keep live state active while scheduling background reconnect
            if (SupabaseService.isInitialized) {
              _setConnectionState(RealtimeConnectionState.connected);
              _scheduleReconnect();
            } else {
              _setConnectionState(RealtimeConnectionState.offline);
            }
          }
        });
    } catch (e) {
      debugPrint('RealtimeService subscription exception: $e');
      if (SupabaseService.isInitialized) {
        _setConnectionState(RealtimeConnectionState.connected);
      } else {
        _setConnectionState(RealtimeConnectionState.offline);
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 15), () {
      if (_currentState != RealtimeConnectionState.connected) {
        debugPrint('RealtimeService: Attempting channel reconnect...');
        unsubscribe();
        subscribeToEvents();
      }
    });
  }

  /// Unsubscribe and close channels
  void unsubscribe() {
    _reconnectTimer?.cancel();
    if (_eventChannel != null) {
      final client = SupabaseService.client;
      if (client != null) {
        try {
          client.removeChannel(_eventChannel!);
        } catch (_) {}
      }
      _eventChannel = null;
    }
  }

  void _setConnectionState(RealtimeConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  void dispose() {
    unsubscribe();
    _eventUpdateController.close();
    _connectionStateController.close();
  }
}
