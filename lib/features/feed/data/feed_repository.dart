import 'package:flutter/foundation.dart';
import '../../../models/event_model.dart';
import '../../../models/sport_type.dart';
import '../../../services/cache_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/supabase_service.dart';

enum FeedDataSource { remote, cache }

const _eventSelect = '''
  id, externalId, startDate, status, score,
  sport:Sport(id, name, slug),
  league:League(id, name, slug, country, logoUrl, isActive),
  season:Season(id, name, slug, isCurrent),
  participants:Participant(id, name, externalId, logoUrl),
  footballStats:FootballStats(*), nbaStats:NbaStats(*),
  ufcStats:UfcStats(*), esportsStats:EsportsStats(*)
''';

const _lightFootballStats =
    'footballStats:FootballStats(id,eventId,homeGoals,awayGoals,homeCards,awayCards,clock:extraStats->>clock,period:extraStats->>period,leagueLogo:extraStats->>leagueLogo,venue:extraStats->>venue)';
const _lightNbaStats =
    'nbaStats:NbaStats(id,eventId,homePoints,awayPoints,quarter,clock:extraStats->>clock,period:extraStats->>period,venue:extraStats->>venue)';

class FeedRepository {
  FeedRepository({bool subscribeToRealtime = true}) {
    if (subscribeToRealtime) RealtimeService().subscribeToEvents();
  }

  FeedDataSource source = FeedDataSource.remote;

  /// Las veladas UFC pueden estar programadas semanas después del feed diario.
  Future<List<EventModel>> fetchUpcomingUfcCards() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Conexión de datos no disponible');
    final now = DateTime.now().toUtc();
    final data = await client.from('Event').select(
      _eventSelect.replaceFirst('sport:Sport(', 'sport:Sport!inner('),
    ).eq('sport.slug', 'ufc')
      .gte('startDate', now.subtract(const Duration(hours: 12)).toIso8601String())
      .lte('startDate', now.add(const Duration(days: 60)).toIso8601String())
      .order('startDate')
      .limit(500);
    return data.map(EventModel.fromJson).toList();
  }
  DateTime? lastUpdated;

  static const int _totalSupportedSportsCount = 5;

  static bool _isSubsetSelection(Set<SportType>? selectedSports) {
    if (selectedSports == null || selectedSports.isEmpty) return false;
    final valid = selectedSports.where((s) => s != SportType.all).toSet();
    return valid.isNotEmpty && valid.length < _totalSupportedSportsCount;
  }

  /// Construye la proyección PostgREST incluyendo únicamente las tablas de estadísticas
  /// de los deportes seleccionados por el usuario para ahorrar ancho de banda y memoria.
  @visibleForTesting
  static String buildEventSelect([Set<SportType>? selectedSports]) {
    if (!_isSubsetSelection(selectedSports)) {
      return _eventSelect;
    }
    final valid = selectedSports!.where((s) => s != SportType.all).toSet();
    final fields = <String>[
      'id, externalId, startDate, status, score',
      'sport:Sport!inner(id, name, slug)',
      'league:League(id, name, slug, country, logoUrl, isActive)',
      'season:Season(id, name, slug, isCurrent)',
      'participants:Participant(id, name, externalId, logoUrl)',
      if (valid.contains(SportType.soccer)) 'footballStats:FootballStats(*)',
      if (valid.contains(SportType.nba)) 'nbaStats:NbaStats(*)',
      if (valid.contains(SportType.ufc)) 'ufcStats:UfcStats(*)',
      if (valid.contains(SportType.lol) || valid.contains(SportType.valorant))
        'esportsStats:EsportsStats(*)',
    ];
    return fields.join(',\n  ');
  }

  @visibleForTesting
  static String buildFeedSelect([Set<SportType>? selectedSports]) =>
      buildEventSelect(selectedSports)
          .replaceAll('footballStats:FootballStats(*)', _lightFootballStats)
          .replaceAll('nbaStats:NbaStats(*)', _lightNbaStats);

  /// Mapea los deportes seleccionados en la app a los slugs de la tabla `Sport` en Supabase.
  @visibleForTesting
  static List<String> backendSportSlugs(Set<SportType> selectedSports) {
    final slugs = <String>{};
    for (final sport in selectedSports) {
      switch (sport) {
        case SportType.soccer:
          slugs.addAll(['football', 'soccer']);
          break;
        case SportType.nba:
          slugs.addAll(['nba', 'basketball']);
          break;
        case SportType.ufc:
          slugs.addAll(['ufc', 'mma']);
          break;
        case SportType.lol:
        case SportType.valorant:
          slugs.addAll(['esports', 'lol', 'valorant']);
          break;
        case SportType.all:
          break;
      }
    }
    return slugs.toList();
  }

  /// Solo se almacena información obtenida de Supabase, nunca datos de ejemplo.
  Future<List<EventModel>> getEvents({
    SportType? sport,
    int? leagueTier,
    bool forceRefresh = false,
  }) async {
    final effectiveSelectedSports = await CacheService.getSelectedSportTypes();
    final cached = await CacheService.getCachedEvents();
    final lastSync = await CacheService.getLastSyncTime();
    final isCacheFresh = lastSync != null &&
        DateTime.now().difference(lastSync) < const Duration(minutes: 5);

    // Solo usar cache si fue actualizada hace menos de 5 minutos
    if (!forceRefresh && cached != null && isCacheFresh) {
      source = FeedDataSource.remote;
      lastUpdated = lastSync;
      return _filter(cached, sport, leagueTier, effectiveSelectedSports);
    }

    try {
      final rawEvents = await fetchRemoteEvents();
      final filteredBySelection = _filterBySelectedSports(
        rawEvents,
        effectiveSelectedSports,
      );
      await CacheService.saveEvents(filteredBySelection);
      source = FeedDataSource.remote;
      lastUpdated = DateTime.now();
      return _filter(
        filteredBySelection,
        sport,
        leagueTier,
        effectiveSelectedSports,
      );
    } catch (error) {
      debugPrint('No se pudieron actualizar los partidos remotamente: $error');
      final fallbackCached = cached ?? await CacheService.getCachedEvents();
      if (fallbackCached == null) rethrow;
      source = FeedDataSource.cache;
      lastUpdated = lastSync ?? await CacheService.getLastSyncTime();
      return _filter(
        fallbackCached,
        sport,
        leagueTier,
        effectiveSelectedSports,
      );
    }
  }

  /// Consulta por defecto únicamente la ventana [ayer 00:00, mañana 23:59:59] en UTC.
  @visibleForTesting
  Future<List<EventModel>> fetchRemoteEvents() async {
    return _fetchRemoteEventsInWindow();
  }

  Future<List<EventModel>> _fetchRemoteEventsInWindow({
    DateTime? start,
    DateTime? end,
  }) async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Conexión de datos no disponible');

    final effectiveSelectedSports = await CacheService.getSelectedSportTypes();
    final isSubset = _isSubsetSelection(effectiveSelectedSports);
    final selectClause = buildFeedSelect(effectiveSelectedSports);
    final allowedSlugs =
        isSubset ? backendSportSlugs(effectiveSelectedSports) : const <String>[];

    final nowLocal = DateTime.now();
    final rangeStart = (start ??
            DateTime(nowLocal.year, nowLocal.month, nowLocal.day - 1, 0, 0, 0))
        .toUtc();
    final rangeEnd = (end ??
            DateTime(
              nowLocal.year,
              nowLocal.month,
              nowLocal.day + 1,
              23,
              59,
              59,
              999,
            ))
        .toUtc();

    final events = <EventModel>[];
    const pageSize = 1000;
    for (var offset = 0; ; offset += pageSize) {
      var query = client
          .from('Event')
          .select(selectClause)
          .gte('startDate', rangeStart.toIso8601String())
          .lte('startDate', rangeEnd.toIso8601String());

      if (isSubset && allowedSlugs.isNotEmpty) {
        query = query.inFilter('sport.slug', allowedSlugs);
      }

      final data = await query
          .order('startDate')
          .order('id')
          .range(offset, offset + pageSize - 1);
      final parsed = data.map(EventModel.fromJson);
      events.addAll(_filterBySelectedSports(parsed, effectiveSelectedSports));
      if (data.length < pageSize) break;
    }
    return events;
  }

  /// Pulso ligero de alta prioridad:
  /// a) Eventos con status = 'LIVE'
  /// b) Eventos cuyos IDs estén en [trackedLiveIds] (transición LIVE -> FINISHED)
  /// c) Eventos de hoy con status = 'SCHEDULED' y startDate <= DateTime.now().toUtc() (transición SCHEDULED -> LIVE)
  Future<List<EventModel>> fetchLiveAndDueEvents(
    List<String> trackedLiveIds,
  ) async {
    final effectiveSelectedSports = await CacheService.getSelectedSportTypes();
    final client = SupabaseService.client;
    if (client == null) {
      return getEvents(forceRefresh: true);
    }

    final isSubset = _isSubsetSelection(effectiveSelectedSports);
    final selectClause = buildFeedSelect(effectiveSelectedSports);
    final allowedSlugs =
        isSubset ? backendSportSlugs(effectiveSelectedSports) : const <String>[];

    final nowLocal = DateTime.now();
    final nowUtcIso = nowLocal.toUtc().toIso8601String();
    final todayStartIso = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      0,
      0,
      0,
    ).toUtc().toIso8601String();

    final cleanTrackedIds = trackedLiveIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final orFilters = <String>[
      'status.eq.LIVE',
      'and(status.eq.SCHEDULED,startDate.gte.$todayStartIso,startDate.lte.$nowUtcIso)',
      if (cleanTrackedIds.isNotEmpty)
        'id.in.(${cleanTrackedIds.map((id) => '"$id"').join(',')})',
    ];

    var query = client
        .from('Event')
        .select(selectClause)
        .or(orFilters.join(','));

    if (isSubset && allowedSlugs.isNotEmpty) {
      query = query.inFilter('sport.slug', allowedSlugs);
    }

    final data = await query.order('startDate').order('id');

    final seenIds = <String>{};
    final result = <EventModel>[];
    for (final row in data) {
      final event = EventModel.fromJson(row);
      if (effectiveSelectedSports.isNotEmpty &&
          !effectiveSelectedSports.contains(event.sport)) {
        continue;
      }
      if (seenIds.add(event.id)) {
        result.add(event);
      }
    }
    return result;
  }

  /// Carga bajo demanda para un rango de fechas (carrusel o calendario).
  Future<List<EventModel>> fetchEventsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final effectiveSelectedSports = await CacheService.getSelectedSportTypes();
    final normalizedStart = start.isUtc
        ? start
        : DateTime(
            start.year,
            start.month,
            start.day,
            start.hour,
            start.minute,
            start.second,
            start.millisecond,
          ).toUtc();

    final isEndMidnight =
        end.hour == 0 &&
        end.minute == 0 &&
        end.second == 0 &&
        end.millisecond == 0;
    final normalizedEnd = isEndMidnight
        ? (end.isUtc
            ? DateTime.utc(end.year, end.month, end.day, 23, 59, 59, 999)
            : DateTime(end.year, end.month, end.day, 23, 59, 59, 999).toUtc())
        : end.toUtc();

    if (SupabaseService.client == null) {
      final all = await fetchRemoteEvents();
      return _filterBySelectedSports(all, effectiveSelectedSports).where((event) {
        final t = event.startTime.toUtc();
        return !t.isBefore(normalizedStart) && !t.isAfter(normalizedEnd);
      }).toList();
    }

    return _fetchRemoteEventsInWindow(
      start: normalizedStart,
      end: normalizedEnd,
    );
  }
  /// Obtiene los eventos de un día específico (resultados para fechas pasadas y partidos para fechas futuras).
  Future<List<EventModel>> getEventsForDate(
    DateTime date, {
    SportType? sport,
    int? leagueTier,
  }) async {
    final startLocal = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endLocal = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    final effectiveSelectedSports = await CacheService.getSelectedSportTypes();
    final events = await fetchEventsForDateRange(startLocal, endLocal);
    return _filter(events, sport, leagueTier, effectiveSelectedSports);
  }

  List<EventModel> _filterBySelectedSports(
    Iterable<EventModel> events,
    Set<SportType>? selectedSports,
  ) {
    if (selectedSports == null || selectedSports.isEmpty) {
      return events.toList();
    }
    final valid = selectedSports.where((s) => s != SportType.all).toSet();
    if (valid.isEmpty) return events.toList();
    return events.where((e) => valid.contains(e.sport)).toList();
  }

  List<EventModel> _filter(
    List<EventModel> events,
    SportType? sport,
    int? tier, [
    Set<SportType>? selectedSports,
  ]) {
    final validSelected = selectedSports
        ?.where((s) => s != SportType.all)
        .toSet();
    return events
        .where(
          (event) =>
              (validSelected == null ||
                  validSelected.isEmpty ||
                  validSelected.contains(event.sport)) &&
              (sport == null ||
                  sport == SportType.all ||
                  event.sport == sport) &&
              (tier == null ||
                  event.leagueModel == null ||
                  event.leagueModel!.tier == tier),
        )
        .toList();
  }

  Future<EventModel?> getEventById(String id) async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        var response = await client
            .from('Event')
            .select(_eventSelect)
            .eq('id', id)
            .maybeSingle();
        response ??= await client
            .from('Event')
            .select(_eventSelect)
            .eq('externalId', id)
            .maybeSingle();
        if (response != null) return EventModel.fromJson(response);
      }
    } catch (error) {
      debugPrint('No se pudo actualizar el encuentro: $error');
    }
    final cached = await CacheService.getCachedEvents();
    for (final event in cached ?? <EventModel>[]) {
      if (event.id == id || event.externalId == id) return event;
    }
    return null;
  }
}

