import 'dart:async';
import 'dart:math' as math;
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

  /// Topic name used for live feed channel
  static const String channelName = 'kambate_live_feed';

  /// Exact PascalCase tables in PostgreSQL (matching Prisma schema models without @@map)
  static const List<String> monitoredTables = [
    'Event',
    'FootballStats',
    'NbaStats',
    'EsportsStats',
    'UfcStats',
  ];

  RealtimeChannel? _eventChannel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isSubscribing = false;

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

  bool _mockActiveChannelForTesting = false;

  bool get isSubscribed =>
      _currentState == RealtimeConnectionState.connected &&
      (_eventChannel != null || _mockActiveChannelForTesting);
  bool get isConnecting => _currentState == RealtimeConnectionState.connecting;
  bool get isDisconnected =>
      _currentState == RealtimeConnectionState.disconnected;
  bool get isOffline => _currentState == RealtimeConnectionState.offline;
  bool get hasActiveChannel =>
      _eventChannel != null || _mockActiveChannelForTesting;
  int get reconnectAttempts => _reconnectAttempts;

  /// Verifies current subscription health and state.
  /// If uninitialized or offline, sets offline state and returns false.
  /// If disconnected or missing channel, attempts reconnection.
  Future<bool> verifySubscription() async {
    final client = SupabaseService.client;
    if (client == null || !SupabaseService.isInitialized) {
      _setConnectionState(RealtimeConnectionState.offline);
      return false;
    }

    if (isSubscribed) {
      return true;
    }

    await reconnectIfNeeded();
    return isSubscribed;
  }

  /// Start subscribing to the PostgreSQL realtime updates for feed tables.
  /// Deduplicates calls to prevent multiple channels or duplicate listener bindings.
  void subscribeToEvents() {
    final client = SupabaseService.client;
    if (client == null || !SupabaseService.isInitialized) {
      _setConnectionState(RealtimeConnectionState.offline);
      return;
    }

    if (isSubscribed) {
      debugPrint(
        'RealtimeService: Already subscribed to channel, skipping duplicate call.',
      );
      return;
    }

    if (_isSubscribing) {
      debugPrint(
        'RealtimeService: Subscription currently in-flight, skipping duplicate call.',
      );
      return;
    }

    _isSubscribing = true;
    _setConnectionState(RealtimeConnectionState.connecting);

    // Cancel pending reconnect timer when explicitly starting subscription
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Remove existing channel instance if any to avoid channel leaks
    if (_eventChannel != null) {
      try {
        client.removeChannel(_eventChannel!);
      } catch (_) {}
      _eventChannel = null;
    }

    try {
      _eventChannel = client.channel(channelName)
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Event',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
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
        ..subscribe((status, [error]) {
          _isSubscribing = false;
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint(
              'RealtimeService: Connected to Supabase Realtime channel',
            );
            _reconnectTimer?.cancel();
            _reconnectTimer = null;
            _reconnectAttempts = 0;
            _setConnectionState(RealtimeConnectionState.connected);
          } else if (status == RealtimeSubscribeStatus.closed ||
              status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            debugPrint(
              'RealtimeService channel notice ($status): $error',
            );
            _setConnectionState(RealtimeConnectionState.disconnected);
            if (SupabaseService.isInitialized) {
              _scheduleReconnect();
            }
          }
        });
    } catch (e) {
      _isSubscribing = false;
      debugPrint('RealtimeService subscription exception: $e');
      _setConnectionState(RealtimeConnectionState.offline);
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }

    _reconnectTimer?.cancel();
    final delaySeconds = math.min(5 * (_reconnectAttempts + 1), 30);
    _reconnectAttempts++;

    debugPrint(
      'RealtimeService: Scheduling reconnect attempt $_reconnectAttempts in ${delaySeconds}s...',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_currentState != RealtimeConnectionState.connected) {
        debugPrint(
          'RealtimeService: Executing channel reconnect attempt $_reconnectAttempts...',
        );
        unsubscribe();
        subscribeToEvents();
      }
    });
  }

  /// Unsubscribe and close channels cleanly
  void unsubscribe() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isSubscribing = false;
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

  /// Cancel pending timers when the app is paused or inactive
  void pause() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Reconnect to realtime channels if disconnected, avoiding duplicate timers
  Future<void> reconnectIfNeeded() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (!isSubscribed) {
      unsubscribe();
      subscribeToEvents();
    }
  }

  void _setConnectionState(RealtimeConnectionState state) {
    if (_currentState == state) return;
    _currentState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  @visibleForTesting
  void handleIncomingUpdate(RealtimeEventUpdate update) {
    if (!_eventUpdateController.isClosed) {
      _eventUpdateController.add(update);
    }
  }

  @visibleForTesting
  void handleConnectionStatusForTesting(
    RealtimeSubscribeStatus status, [
    Object? error,
  ]) {
    _isSubscribing = false;
    if (status == RealtimeSubscribeStatus.subscribed) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _reconnectAttempts = 0;
      _setConnectionState(RealtimeConnectionState.connected);
    } else if (status == RealtimeSubscribeStatus.closed ||
        status == RealtimeSubscribeStatus.channelError ||
        status == RealtimeSubscribeStatus.timedOut) {
      _setConnectionState(RealtimeConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  @visibleForTesting
  void setMockConnectedForTesting() {
    _mockActiveChannelForTesting = true;
    _isSubscribing = false;
    _setConnectionState(RealtimeConnectionState.connected);
  }

  @visibleForTesting
  void resetForTesting({
    RealtimeConnectionState initialState = RealtimeConnectionState.connecting,
  }) {
    unsubscribe();
    _mockActiveChannelForTesting = false;
    _reconnectAttempts = 0;
    _isSubscribing = false;
    _currentState = initialState;
  }

  void dispose() {
    unsubscribe();
    _eventUpdateController.close();
    _connectionStateController.close();
  }
}
