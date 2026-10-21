import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum RealtimeConnectionState { connecting, connected, disconnected, offline }

class RealtimeEventUpdate {
  const RealtimeEventUpdate({
    required this.eventId,
    required this.record,
    required this.requiresRefresh,
  });

  final String eventId;
  final Map<String, dynamic> record;
  final bool requiresRefresh;

  static RealtimeEventUpdate? event(Map<String, dynamic> record) {
    final eventId = record['id']?.toString();
    if (eventId == null || eventId.isEmpty) return null;
    return RealtimeEventUpdate(
      eventId: eventId,
      record: record,
      requiresRefresh: false,
    );
  }

  static RealtimeEventUpdate? footballStats(Map<String, dynamic> record) {
    final eventId =
        record['eventId']?.toString() ?? record['event_id']?.toString();
    if (eventId == null || eventId.isEmpty) return null;
    return RealtimeEventUpdate(
      eventId: eventId,
      record: record,
      requiresRefresh: true,
    );
  }

  static RealtimeEventUpdate? nbaStats(Map<String, dynamic> record) {
    final eventId =
        record['eventId']?.toString() ?? record['event_id']?.toString();
    if (eventId == null || eventId.isEmpty) return null;
    return RealtimeEventUpdate(
      eventId: eventId,
      record: record,
      requiresRefresh: true,
    );
  }

  static RealtimeEventUpdate? esportsStats(Map<String, dynamic> record) {
    final eventId =
        record['eventId']?.toString() ?? record['event_id']?.toString();
    if (eventId == null || eventId.isEmpty) return null;
    return RealtimeEventUpdate(
      eventId: eventId,
      record: record,
      requiresRefresh: true,
    );
  }

  static RealtimeEventUpdate? ufcStats(Map<String, dynamic> record) {
    final eventId =
        record['eventId']?.toString() ?? record['event_id']?.toString();
    if (eventId == null || eventId.isEmpty) return null;
    return RealtimeEventUpdate(
      eventId: eventId,
      record: record,
      requiresRefresh: true,
    );
  }
}

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  RealtimeChannel? _eventChannel;
  Timer? _reconnectTimer;
  final _eventUpdateController =
      StreamController<RealtimeEventUpdate>.broadcast();
  final _connectionStateController =
      StreamController<RealtimeConnectionState>.broadcast();

  RealtimeConnectionState _currentState = RealtimeConnectionState.connecting;
  RealtimeConnectionState get currentState => _currentState;

  Stream<RealtimeEventUpdate> get onEventUpdate =>
      _eventUpdateController.stream;
  Stream<RealtimeConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;

  /// Start subscribing to the 'Event' table realtime updates
  void subscribeToEvents() {
    final client = SupabaseService.client;
    if (client == null) {
      _setConnectionState(RealtimeConnectionState.offline);
      return;
    }

    if (_eventChannel != null) {
      return;
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
              debugPrint(
                'RealtimeService received Event update: ${record['id']}',
              );
              final update = RealtimeEventUpdate.event(record);
              if (update != null) _eventUpdateController.add(update);
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
              debugPrint(
                'RealtimeService received event update: ${record['id']}',
              );
              final update = RealtimeEventUpdate.event(record);
              if (update != null) _eventUpdateController.add(update);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'FootballStats',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final update = RealtimeEventUpdate.footballStats(record);
            if (update != null) {
              debugPrint(
                'RealtimeService received FootballStats update: ${update.eventId}',
              );
              _eventUpdateController.add(update);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'football_stats',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final update = RealtimeEventUpdate.footballStats(record);
            if (update != null) {
              debugPrint(
                'RealtimeService received football_stats update: ${update.eventId}',
              );
              _eventUpdateController.add(update);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'NbaStats',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final update = RealtimeEventUpdate.nbaStats(record);
            if (update != null) {
              debugPrint(
                'RealtimeService received NbaStats update: ${update.eventId}',
              );
              _eventUpdateController.add(update);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'nba_stats',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final update = RealtimeEventUpdate.nbaStats(record);
            if (update != null) {
              debugPrint(
                'RealtimeService received nba_stats update: ${update.eventId}',
              );
              _eventUpdateController.add(update);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'EsportsStats',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final update = RealtimeEventUpdate.esportsStats(record);
            if (update != null) {
              debugPrint(
                'RealtimeService received EsportsStats update: ${update.eventId}',
              );
              _eventUpdateController.add(update);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'esports_stats',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final update = RealtimeEventUpdate.esportsStats(record);
            if (update != null) {
              debugPrint(
                'RealtimeService received esports_stats update: ${update.eventId}',
              );
              _eventUpdateController.add(update);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'UfcStats',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final update = RealtimeEventUpdate.ufcStats(record);
            if (update != null) {
              debugPrint(
                'RealtimeService received UfcStats update: ${update.eventId}',
              );
              _eventUpdateController.add(update);
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ufc_stats',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final update = RealtimeEventUpdate.ufcStats(record);
            if (update != null) {
              debugPrint(
                'RealtimeService received ufc_stats update: ${update.eventId}',
              );
              _eventUpdateController.add(update);
            }
          },
        )
        ..subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint(
              'RealtimeService: Connected to Supabase Realtime channel',
            );
            _reconnectTimer?.cancel();
            _setConnectionState(RealtimeConnectionState.connected);
          } else if (status == RealtimeSubscribeStatus.closed ||
              status == RealtimeSubscribeStatus.channelError) {
            debugPrint('RealtimeService channel notice: $error');
            _setConnectionState(RealtimeConnectionState.disconnected);
            if (SupabaseService.isInitialized) {
              _scheduleReconnect();
            }
          }
        });
    } catch (e) {
      debugPrint('RealtimeService subscription exception: $e');
      _setConnectionState(RealtimeConnectionState.offline);
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
