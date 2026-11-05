import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../models/basketball_detail_model.dart';
import '../../../models/event_model.dart';
import '../../../models/event_status.dart';
import '../../../models/football_detail_model.dart';
import '../../../models/sport_type.dart';
import '../../../models/stats_models.dart';
import '../../../models/team_model.dart';
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
    'footballStats:FootballStats(id,eventId,homeGoals,awayGoals,homeCards,awayCards,clock:extraStats->>clock,period:extraStats->>period,statusDetail:extraStats->>statusDetail,leagueLogo:extraStats->>leagueLogo,venue:extraStats->>venue,round:extraStats->>round,homeTeamId:extraStats->>homeTeamId,awayTeamId:extraStats->>awayTeamId)';
const _lightNbaStats =
    'nbaStats:NbaStats(id,eventId,homePoints,awayPoints,quarter,clock:extraStats->>clock,period:extraStats->>period,statusDetail:extraStats->>statusDetail,venue:extraStats->>venue)';

class FeedRepository {
  final Dio _dio;

  FeedRepository({bool subscribeToRealtime = true, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 6),
            ),
          ) {
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

  /// Obtiene los próximos encuentros de League of Legends Worlds desde Supabase.
  Future<List<EventModel>> fetchUpcomingWorldsMatches() async {
    final client = SupabaseService.client;
    if (client == null) return const <EventModel>[];
    final now = DateTime.now().toUtc();
    final selectClause = _eventSelect
        .replaceFirst('league:League(', 'league:League!inner(');
    final data = await client
        .from('Event')
        .select(selectClause)
        .eq('league.slug', 'worlds')
        .gte(
          'startDate',
          now.subtract(const Duration(hours: 6)).toIso8601String(),
        )
        .lte(
          'startDate',
          now.add(const Duration(days: 30)).toIso8601String(),
        )
        .order('startDate')
        .limit(100);
    return data
        .map(EventModel.fromJson)
        .where((e) => e.status != EventStatus.finished)
        .toList();
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

  /// Prioridad: consulta inicialmente solo los partidos de HOY [hoy 00:00, hoy 23:59:59] en UTC.
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
            DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 0, 0, 0))
        .toUtc();
    final rangeEnd = (end ??
            DateTime(
              nowLocal.year,
              nowLocal.month,
              nowLocal.day,
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
    EventModel? resolved;
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
        if (response != null) {
          resolved = EventModel.fromJson(response);
        }
      }
    } catch (error) {
      debugPrint('No se pudo actualizar el encuentro: $error');
    }

    if (resolved == null) {
      final cached = await CacheService.getCachedEvents();
      for (final event in cached ?? <EventModel>[]) {
        if (event.id == id || event.externalId == id) {
          resolved = event;
          break;
        }
      }
    }

    if (resolved == null) return null;
    return enrichEventDetailOnDemand(resolved);
  }

  /// Carga bajo demanda las acciones y detalles completos del partido
  /// únicamente cuando el usuario entra a la vista de detalle.
  @visibleForTesting
  Future<EventModel> enrichEventDetailOnDemand(EventModel event) async {
    if (event.status == EventStatus.scheduled) return event;
    if (event.sport == SportType.soccer) {
      return _enrichFootballEventIfNeeded(event);
    }
    if (event.sport == SportType.nba) {
      return _enrichNbaEventIfNeeded(event);
    }
    return event;
  }

  String? _extractEspnEventId(EventModel event, Map<String, dynamic>? extra) {
    final fromExtra = extra?['espnEventId']?.toString().trim();
    if (fromExtra != null && fromExtra.isNotEmpty) return fromExtra;

    final ext = event.externalId?.trim();
    if (ext != null && ext.isNotEmpty) {
      final match = RegExp(r'espn-(\d+)$').firstMatch(ext);
      if (match != null) return match.group(1);
      if (RegExp(r'^\d+$').hasMatch(ext)) return ext;
    }
    return null;
  }

  Future<EventModel> _enrichFootballEventIfNeeded(EventModel event) async {
    final extra = event.footballStats?.extraStats ?? const <String, dynamic>{};
    final existing = FootballDetailModel.parse(
      extra['detail'],
      extraStats: extra,
    );

    final hasTimeline =
        existing?.timeline != null && existing!.timeline!.isNotEmpty;
    final hasStats = existing != null && existing.statistics.isNotEmpty;
    final hasLineups = existing != null &&
        (existing.homeLineup != null || existing.awayLineup != null);

    if (!event.isLive && hasTimeline && hasStats && hasLineups) {
      return event;
    }

    final espnEventId = _extractEspnEventId(event, extra);
    if (espnEventId == null) return event;

    final rawLeagueSlug =
        extra['leagueSlug']?.toString().trim() ?? event.leagueModel?.slug.trim();
    final candidateSlugs = <String>{
      if (rawLeagueSlug != null && rawLeagueSlug.isNotEmpty) rawLeagueSlug,
      'all',
    };

    Map<String, dynamic>? summaryData;
    for (final slug in candidateSlugs) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          'https://site.api.espn.com/apis/site/v2/sports/soccer/$slug/summary',
          queryParameters: {'event': espnEventId},
        );
        if (response.statusCode == 200 && response.data != null) {
          summaryData = response.data;
          break;
        }
      } catch (_) {}
    }

    if (summaryData == null) return event;
    return buildFootballEventWithSummary(event, summaryData);
  }

  @visibleForTesting
  static EventModel buildFootballEventWithSummary(
    EventModel event,
    Map<String, dynamic> summaryData,
  ) {
    final extra = Map<String, dynamic>.from(
      event.footballStats?.extraStats ?? const <String, dynamic>{},
    );
    final existingDetail = FootballDetailModel.parse(
      extra['detail'],
      extraStats: extra,
    );

    String? homeTeamId = extra['homeTeamId']?.toString();
    String? awayTeamId = extra['awayTeamId']?.toString();

    final headerComps = summaryData['header'] is Map
        ? (summaryData['header'] as Map)['competitions']
        : null;
    final firstComp = headerComps is List && headerComps.isNotEmpty
        ? headerComps.first
        : null;
    final competitors =
        firstComp is Map ? firstComp['competitors'] : null;

    if (competitors is List) {
      for (final c in competitors) {
        if (c is! Map) continue;
        final homeAway = c['homeAway']?.toString();
        final teamMap = c['team'] is Map ? c['team'] as Map : null;
        final id = (teamMap?['id'] ?? c['id'])?.toString();
        if (id == null || id.isEmpty) continue;
        if (homeAway == 'home') homeTeamId ??= id;
        if (homeAway == 'away') awayTeamId ??= id;
      }
    }

    final boxTeams = summaryData['boxscore'] is Map
        ? (summaryData['boxscore'] as Map)['teams']
        : null;
    if (boxTeams is List) {
      for (final bt in boxTeams) {
        if (bt is! Map) continue;
        final homeAway = bt['homeAway']?.toString();
        final teamMap = bt['team'] is Map ? bt['team'] as Map : null;
        final id = teamMap?['id']?.toString();
        if (id == null || id.isEmpty) continue;
        if (homeAway == 'home') homeTeamId ??= id;
        if (homeAway == 'away') awayTeamId ??= id;
      }
    }

    TeamModel? resolvedHome = event.homeTeam;
    TeamModel? resolvedAway = event.awayTeam;
    if (event.participants.length >= 2 &&
        homeTeamId != null &&
        awayTeamId != null) {
      final homeP = event.participants
          .where((p) =>
              p.externalId == 'football-team-$homeTeamId' ||
              p.externalId == homeTeamId ||
              (p.externalId?.endsWith('-$homeTeamId') ?? false))
          .firstOrNull;
      final awayP = event.participants
          .where((p) =>
              p.externalId == 'football-team-$awayTeamId' ||
              p.externalId == awayTeamId ||
              (p.externalId?.endsWith('-$awayTeamId') ?? false))
          .firstOrNull;
      if (homeP != null && awayP != null) {
        resolvedHome = TeamModel(
          id: homeP.id,
          name: homeP.name,
          shortName: homeP.shortName,
          logoUrl: homeP.logoUrl,
        );
        resolvedAway = TeamModel(
          id: awayP.id,
          name: awayP.name,
          shortName: awayP.shortName,
          logoUrl: awayP.logoUrl,
        );
      }
    }

    final homeParticipantId =
        resolvedHome?.id ?? existingDetail?.homeParticipantId ?? 'home';
    final awayParticipantId =
        resolvedAway?.id ?? existingDetail?.awayParticipantId ?? 'away';

    String? sideForTeamId(String? teamId) {
      if (teamId == null || teamId.isEmpty) return null;
      if (homeTeamId != null && teamId == homeTeamId) return 'home';
      if (awayTeamId != null && teamId == awayTeamId) return 'away';
      return null;
    }

    // 1. Extraer acciones del partido (timeline: goles, asistencias, tarjetas, cambios)
    final timelineList = <Map<String, dynamic>>[];
    final keyEvents = summaryData['keyEvents'];
    if (keyEvents is List && keyEvents.isNotEmpty) {
      for (final rawKe in keyEvents) {
        if (rawKe is! Map) continue;
        final typeMap = rawKe['type'] is Map ? rawKe['type'] as Map : null;
        final typeText =
            (typeMap?['text'] ?? typeMap?['type'] ?? '').toString().toLowerCase();
        final scoringPlay = rawKe['scoringPlay'] == true;

        String? kind;
        if (scoringPlay ||
            typeText.contains('goal') ||
            typeText.contains('gol') ||
            typeText.contains('penal')) {
          kind = 'goal';
        } else if (typeText.contains('yellow') ||
            typeText.contains('amarilla')) {
          kind = 'yellowCard';
        } else if (typeText.contains('red') || typeText.contains('roja')) {
          kind = 'redCard';
        } else if (typeText.contains('sub') || typeText.contains('cambio')) {
          kind = 'substitution';
        }
        if (kind == null) continue;

        final teamMap = rawKe['team'] is Map ? rawKe['team'] as Map : null;
        final side = sideForTeamId(teamMap?['id']?.toString());
        if (side == null) continue;

        final clockMap = rawKe['clock'] is Map ? rawKe['clock'] as Map : null;
        final minute = clockMap?['displayValue']?.toString().trim();

        String? player;
        String? secondaryPlayer;
        final parts = rawKe['participants'];
        if (parts is List && parts.isNotEmpty) {
          final p0 = parts[0] is Map ? (parts[0] as Map)['athlete'] : null;
          if (p0 is Map) {
            player =
                (p0['displayName'] ?? p0['fullName'])?.toString().trim();
          }
          if (parts.length > 1) {
            final p1 = parts[1] is Map ? (parts[1] as Map)['athlete'] : null;
            if (p1 is Map) {
              secondaryPlayer =
                  (p1['displayName'] ?? p1['fullName'])?.toString().trim();
            }
          }
        }

        timelineList.add({
          'kind': kind,
          'side': side,
          if (minute != null && minute.isNotEmpty) 'minute': minute,
          if (player != null && player.isNotEmpty) 'player': player,
          if (secondaryPlayer != null && secondaryPlayer.isNotEmpty)
            'secondaryPlayer': secondaryPlayer,
        });
      }
    }

    if (timelineList.isEmpty && firstComp is Map) {
      final compDetails = firstComp['details'];
      if (compDetails is List) {
        for (final rawD in compDetails) {
          if (rawD is! Map) continue;
          final typeMap = rawD['type'] is Map ? rawD['type'] as Map : null;
          final typeText = (typeMap?['text'] ?? '').toString().toLowerCase();

          String? kind;
          if (rawD['yellowCard'] == true) {
            kind = 'yellowCard';
          } else if (rawD['redCard'] == true) {
            kind = 'redCard';
          } else if (typeText.contains('substitution') ||
              typeText.contains('sub')) {
            kind = 'substitution';
          } else if (rawD['scoringPlay'] == true ||
              typeText.contains('goal')) {
            kind = 'goal';
          }
          if (kind == null) continue;

          final teamMap = rawD['team'] is Map ? rawD['team'] as Map : null;
          final side = sideForTeamId(teamMap?['id']?.toString());
          if (side == null) continue;

          final clockMap = rawD['clock'] is Map ? rawD['clock'] as Map : null;
          final minute = clockMap?['displayValue']?.toString().trim();

          String? player;
          String? secondaryPlayer;
          final athletes = rawD['athletesInvolved'];
          if (athletes is List && athletes.isNotEmpty) {
            if (athletes[0] is Map) {
              final a0 = athletes[0] as Map;
              player =
                  (a0['displayName'] ?? a0['fullName'])?.toString().trim();
            }
            if (athletes.length > 1 && athletes[1] is Map) {
              final a1 = athletes[1] as Map;
              secondaryPlayer =
                  (a1['displayName'] ?? a1['fullName'])?.toString().trim();
            }
          }

          timelineList.add({
            'kind': kind,
            'side': side,
            if (minute != null && minute.isNotEmpty) 'minute': minute,
            if (player != null && player.isNotEmpty) 'player': player,
            if (secondaryPlayer != null && secondaryPlayer.isNotEmpty)
              'secondaryPlayer': secondaryPlayer,
          });
        }
      }
    }

    // 2. Extraer estadísticas del encuentro
    Map<String, String> extractBoxMap(String targetSide, String? targetTeamId) {
      if (boxTeams is! List) return const {};
      for (final bt in boxTeams) {
        if (bt is! Map) continue;
        final ha = bt['homeAway']?.toString();
        final tMap = bt['team'] is Map ? bt['team'] as Map : null;
        final tid = tMap?['id']?.toString();
        if (ha == targetSide || (targetTeamId != null && tid == targetTeamId)) {
          final statsList = bt['statistics'];
          if (statsList is! List) return const {};
          final map = <String, String>{};
          for (final s in statsList) {
            if (s is! Map) continue;
            final name = s['name']?.toString();
            final val = s['displayValue']?.toString() ?? s['value']?.toString();
            if (name != null && val != null) {
              map[name] = val;
            }
          }
          return map;
        }
      }
      return const {};
    }

    final boxHome = extractBoxMap('home', homeTeamId);
    final boxAway = extractBoxMap('away', awayTeamId);

    num? parseStatNum(String? raw) {
      if (raw == null) return null;
      final cleaned = raw.replaceAll('%', '').trim();
      return num.tryParse(cleaned);
    }

    final statisticsList = <Map<String, dynamic>>[];
    if (boxHome.isNotEmpty || boxAway.isNotEmpty) {
      const statMappings = <String, List<String>>{
        'possession': ['possessionPct'],
        'shots': ['totalShots', 'shotsSummary'],
        'shotsOnTarget': ['shotsOnTarget'],
        'corners': ['wonCorners', 'corners'],
        'fouls': ['foulsCommitted', 'fouls'],
        'yellowCards': ['yellowCards'],
        'redCards': ['redCards'],
        'offsides': ['offsides'],
      };

      for (final entry in statMappings.entries) {
        num? homeVal;
        num? awayVal;
        for (final candidateKey in entry.value) {
          homeVal ??= parseStatNum(boxHome[candidateKey]);
          awayVal ??= parseStatNum(boxAway[candidateKey]);
        }
        if (homeVal != null || awayVal != null) {
          statisticsList.add({
            'key': entry.key,
            'home': homeVal,
            'away': awayVal,
          });
        }
      }
    }

    // 3. Extraer alineaciones (rosters)
    Map<String, dynamic>? extractLineup(String targetSide, String? targetTeamId) {
      final rosters = summaryData['rosters'];
      if (rosters is! List) return null;
      for (final r in rosters) {
        if (r is! Map) continue;
        final ha = r['homeAway']?.toString();
        final tMap = r['team'] is Map ? r['team'] as Map : null;
        final tid = tMap?['id']?.toString();
        if (ha == targetSide || (targetTeamId != null && tid == targetTeamId)) {
          final rosterList = r['roster'];
          if (rosterList is! List || rosterList.isEmpty) return null;
          final starters = <Map<String, dynamic>>[];
          final substitutes = <Map<String, dynamic>>[];
          for (final p in rosterList) {
            if (p is! Map) continue;
            final athlete = p['athlete'] is Map ? p['athlete'] as Map : null;
            final name =
                (athlete?['displayName'] ?? athlete?['fullName'])
                    ?.toString()
                    .trim();
            if (name == null || name.isEmpty) continue;
            final number = p['jersey']?.toString().trim();
            final posMap = p['position'] is Map ? p['position'] as Map : null;
            final position =
                (posMap?['displayName'] ??
                        posMap?['name'] ??
                        posMap?['abbreviation'])
                    ?.toString()
                    .trim();
            final playerMap = <String, dynamic>{
              'name': name,
              if (number != null && number.isNotEmpty) 'number': number,
              if (position != null && position.isNotEmpty) 'position': position,
            };
            if (p['starter'] == true) {
              starters.add(playerMap);
            } else {
              substitutes.add(playerMap);
            }
          }
          if (starters.isEmpty && substitutes.isEmpty) return null;
          final formation = r['formation']?.toString().trim();
          return {
            if (formation != null && formation.isNotEmpty)
              'formation': formation,
            'starters': starters,
            'substitutes': substitutes,
          };
        }
      }
      return null;
    }

    final existingDetailMap = extra['detail'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(extra['detail'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final homeLineup =
        extractLineup('home', homeTeamId) ?? existingDetailMap['homeLineup'];
    final awayLineup =
        extractLineup('away', awayTeamId) ?? existingDetailMap['awayLineup'];

    final mergedDetail = <String, dynamic>{
      'version': 1,
      'homeParticipantId': homeParticipantId,
      'awayParticipantId': awayParticipantId,
      'statistics': statisticsList.isNotEmpty
          ? statisticsList
          : (existingDetailMap['statistics'] is List
              ? existingDetailMap['statistics']
              : <Map<String, dynamic>>[]),
      'timeline': timelineList.isNotEmpty
          ? timelineList
          : (existingDetailMap['timeline'] is List
              ? existingDetailMap['timeline']
              : <Map<String, dynamic>>[]),
      'homeLineup': homeLineup,
      'awayLineup': awayLineup,
    };

    extra['detail'] = mergedDetail;
    if (homeTeamId != null) extra['homeTeamId'] = homeTeamId;
    if (awayTeamId != null) extra['awayTeamId'] = awayTeamId;

    final updatedStats = FootballStatsModel(
      id: event.footballStats?.id ?? '',
      eventId: event.footballStats?.eventId ?? event.id,
      homeGoals: event.footballStats?.homeGoals ?? event.homeScore,
      awayGoals: event.footballStats?.awayGoals ?? event.awayScore,
      homeCards: event.footballStats?.homeCards,
      awayCards: event.footballStats?.awayCards,
      extraStats: extra,
    );

    return event.copyWith(
      homeTeam: resolvedHome,
      awayTeam: resolvedAway,
      footballStats: updatedStats,
    );
  }

  Future<EventModel> _enrichNbaEventIfNeeded(EventModel event) async {
    final extra = event.nbaStats?.extraStats ?? const <String, dynamic>{};
    final existing = BasketballDetailModel.parse(extra['detail']);

    final hasPeriods = existing != null && existing.periods.isNotEmpty;
    final hasStats = existing != null && existing.statistics.isNotEmpty;
    final hasPlayers = existing != null &&
        ((existing.homePlayers != null && existing.homePlayers!.isNotEmpty) ||
            (existing.awayPlayers != null && existing.awayPlayers!.isNotEmpty));

    if (!event.isLive && hasPeriods && hasStats && hasPlayers) {
      return event;
    }

    final espnEventId = _extractEspnEventId(event, extra);
    if (espnEventId == null) return event;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://site.api.espn.com/apis/site/v2/sports/basketball/nba/summary',
        queryParameters: {'event': espnEventId},
      );
      if (response.statusCode != 200 || response.data == null) return event;
      return _buildNbaEventWithSummary(event, response.data!);
    } catch (_) {
      return event;
    }
  }

  EventModel _buildNbaEventWithSummary(
    EventModel event,
    Map<String, dynamic> summaryData,
  ) {
    final extra = Map<String, dynamic>.from(
      event.nbaStats?.extraStats ?? const <String, dynamic>{},
    );
    final existingDetailMap = extra['detail'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(extra['detail'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final headerComps = summaryData['header'] is Map
        ? (summaryData['header'] as Map)['competitions']
        : null;
    final firstComp = headerComps is List && headerComps.isNotEmpty
        ? headerComps.first
        : null;
    final competitors = firstComp is Map ? firstComp['competitors'] : null;

    Map? homeComp;
    Map? awayComp;
    if (competitors is List) {
      for (final c in competitors) {
        if (c is! Map) continue;
        if (c['homeAway'] == 'home') homeComp = c;
        if (c['homeAway'] == 'away') awayComp = c;
      }
    }

    final homeLines = homeComp?['linescores'];
    final awayLines = awayComp?['linescores'];
    final periods = <Map<String, dynamic>>[];
    if (homeLines is List || awayLines is List) {
      final hList = homeLines is List ? homeLines : const [];
      final aList = awayLines is List ? awayLines : const [];
      final count = hList.length > aList.length ? hList.length : aList.length;
      for (var i = 0; i < count; i++) {
        final hItem = i < hList.length && hList[i] is Map ? hList[i] as Map : null;
        final aItem = i < aList.length && aList[i] is Map ? aList[i] as Map : null;
        final label = i < 4 ? '${i + 1}' : (i == 4 ? 'OT' : 'OT${i - 3}');
        periods.add({
          'period': label,
          'home': int.tryParse(hItem?['displayValue']?.toString() ?? ''),
          'away': int.tryParse(aItem?['displayValue']?.toString() ?? ''),
        });
      }
    }

    final homeParticipantId =
        event.homeTeam?.id ??
        existingDetailMap['homeParticipantId']?.toString() ??
        'home';
    final awayParticipantId =
        event.awayTeam?.id ??
        existingDetailMap['awayParticipantId']?.toString() ??
        'away';

    final mergedDetail = <String, dynamic>{
      ...existingDetailMap,
      'version': 1,
      'homeParticipantId': homeParticipantId,
      'awayParticipantId': awayParticipantId,
      if (periods.isNotEmpty) 'periods': periods,
    };

    extra['detail'] = mergedDetail;
    final updatedStats = NbaStatsModel(
      id: event.nbaStats?.id ?? '',
      eventId: event.nbaStats?.eventId ?? event.id,
      homePoints: event.nbaStats?.homePoints ?? event.homeScore,
      awayPoints: event.nbaStats?.awayPoints ?? event.awayScore,
      quarter: event.nbaStats?.quarter,
      extraStats: extra,
    );

    return event.copyWith(nbaStats: updatedStats);
  }
}

