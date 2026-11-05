import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/football_detail_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/services/cache_service.dart';

class TestRepository extends FeedRepository {
  TestRepository({this.events = const [], this.fail = false})
    : super(subscribeToRealtime: false);
  final List<EventModel> events;
  final bool fail;

  @override
  Future<List<EventModel>> fetchRemoteEvents() async {
    if (fail) throw StateError('Sin conexión');
    return events;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('El feed excluye detalles pesados y conserva el reloj en vivo', () {
    final select = FeedRepository.buildFeedSelect({SportType.soccer, SportType.nba});
    expect(select, contains('clock:extraStats->>clock'));
    expect(select, contains('homeTeamId:extraStats->>homeTeamId'));
    expect(select, isNot(contains('FootballStats(*)')));
    expect(select, isNot(contains('NbaStats(*)')));
    final football = FootballStatsModel.fromJson({
      'id': 'stats-1',
      'clock': "42'",
      'homeGoals': 1,
      'homeTeamId': '86',
      'awayTeamId': '83',
    });
    expect(football.extraStats?['clock'], "42'");
    expect(football.extraStats?['homeTeamId'], '86');
    expect(football.homeGoals, 1);
  });

  test(
    'buildFootballEventWithSummary enriquece acciones, estadísticas y alineaciones al entrar al partido',
    () {
      final baseEvent = EventModel.fromJson({
        'id': 'ev-1',
        'externalId': 'football-espn-7001',
        'sport': 'football',
        'status': 'LIVE',
        'score': '1 - 0',
        'startDate': '2026-11-05T19:00:00Z',
        'participants': [
          {
            'id': 'p-home',
            'name': 'Real Madrid',
            'externalId': 'football-team-86',
          },
          {
            'id': 'p-away',
            'name': 'Barcelona',
            'externalId': 'football-team-83',
          },
        ],
        'footballStats': {
          'id': 'fs-1',
          'homeGoals': 1,
          'awayGoals': 0,
          'extraStats': {
            'homeTeamId': '86',
            'awayTeamId': '83',
          },
        },
      });

      final enriched = FeedRepository.buildFootballEventWithSummary(
        baseEvent,
        {
          'keyEvents': [
            {
              'type': {'text': 'Goal'},
              'scoringPlay': true,
              'clock': {'displayValue': "23'"},
              'team': {'id': '86'},
              'participants': [
                {
                  'athlete': {'displayName': 'Vinícius Júnior'},
                },
                {
                  'athlete': {'displayName': 'Jude Bellingham'},
                },
              ],
            },
            {
              'type': {'text': 'Yellow Card'},
              'scoringPlay': false,
              'clock': {'displayValue': "41'"},
              'team': {'id': '83'},
              'participants': [
                {
                  'athlete': {'displayName': 'Gavi'},
                },
              ],
            },
          ],
          'boxscore': {
            'teams': [
              {
                'homeAway': 'home',
                'team': {'id': '86'},
                'statistics': [
                  {'name': 'possessionPct', 'displayValue': '54'},
                  {'name': 'shotsOnTarget', 'displayValue': '6'},
                ],
              },
              {
                'homeAway': 'away',
                'team': {'id': '83'},
                'statistics': [
                  {'name': 'possessionPct', 'displayValue': '46'},
                  {'name': 'shotsOnTarget', 'displayValue': '4'},
                ],
              },
            ],
          },
        },
      );

      final parsedDetail = FootballDetailModel.parse(
        enriched.footballStats?.extraStats?['detail'],
      );
      expect(parsedDetail, isNotNull);
      expect(parsedDetail!.timeline, isNotNull);
      expect(parsedDetail.timeline!.length, 2);
      expect(parsedDetail.timeline!.first.kind, 'goal');
      expect(parsedDetail.timeline!.first.player, 'Vinícius Júnior');
      expect(parsedDetail.timeline!.first.secondaryPlayer, 'Jude Bellingham');
      expect(parsedDetail.timeline!.last.kind, 'yellowCard');
      expect(parsedDetail.timeline!.last.player, 'Gavi');
      expect(parsedDetail.statistics.length, 2);
    },
  );

  final nowLocal = DateTime.now();
  final todayNoonUtc = DateTime(
    nowLocal.year,
    nowLocal.month,
    nowLocal.day,
    12,
  ).toUtc();

  final event = EventModel(
    id: 'real-event',
    sport: SportType.soccer,
    league: 'Primera División',
    status: EventStatus.live,
    startTime: todayNoonUtc,
    homeScore: 2,
    awayScore: 1,
  );

  test('Un fallo sin caché no genera partidos ficticios', () async {
    final repository = TestRepository(fail: true);
    await expectLater(
      repository.getEvents(forceRefresh: true),
      throwsStateError,
    );
    expect(await CacheService.getCachedEvents(), isNull);
  });

  test('Un fallo conserva los datos reales y marca su procedencia', () async {
    await CacheService.saveEvents([event]);
    final repository = TestRepository(fail: true);
    final events = await repository.getEvents(forceRefresh: true);
    expect(events.single.id, 'real-event');
    expect(repository.source, FeedDataSource.cache);
    expect(repository.lastUpdated, isNotNull);
  });

  test('Una respuesta vacía borra resultados antiguos de la caché', () async {
    await CacheService.saveEvents([event]);
    final repository = TestRepository();
    expect(await repository.getEvents(forceRefresh: true), isEmpty);
    expect(await CacheService.getCachedEvents(), isEmpty);
    expect(repository.source, FeedDataSource.remote);
  });

  test('La caché mantiene el instante después de varias lecturas', () async {
    await CacheService.saveEvents([event]);
    final first = (await CacheService.getCachedEvents())!.single;
    await CacheService.saveEvents([first]);
    final second = (await CacheService.getCachedEvents())!.single;
    expect(first.startTime.toUtc(), event.startTime);
    expect(second.startTime.toUtc(), event.startTime);
  });

  test('El modelo respeta offsets y prioriza el score recibido', () {
    final parsed = EventModel.fromJson({
      'id': 'sample',
      'sport': 'football',
      'status': 'LIVE',
      'startDate': '2026-10-04T18:00:00-03:00',
      'score': '3 - 2',
      'footballStats': {'homeGoals': 1, 'awayGoals': 0},
    });
    expect(parsed.startTime.toUtc(), DateTime.utc(2026, 10, 4, 21));
    expect(parsed.homeScore, 3);
    expect(parsed.awayScore, 2);
  });

  test('Cancelados y archivados no se convierten en programados', () {
    expect(EventStatus.fromString('CANCELED'), EventStatus.canceled);
    expect(EventStatus.fromString('cancelled'), EventStatus.canceled);
    expect(EventStatus.fromString('ARCHIVED'), EventStatus.archived);
    expect(EventStatus.fromString('postponed'), EventStatus.postponed);
  });

  test(
    'No se reutiliza la caché antigua que podía contener ejemplos',
    () async {
      SharedPreferences.setMockInitialValues({
        'kambate_cached_events_v1': '[]',
      });
      expect(await CacheService.getCachedEvents(), isNull);
    },
  );

  test(
    'Autolimpieza diaria invalida la caché cuando cambia la fecha local',
    () async {
      await CacheService.saveEvents([event]);
      expect(await CacheService.getCachedEvents(), isNotNull);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kambate_cached_events_date', '2000-01-01');

      expect(await CacheService.getCachedEvents(), isNull);
      expect(prefs.getString('kambate_cached_events_v2'), isNull);
      expect(prefs.getString('kambate_last_sync_timestamp'), isNull);
      expect(prefs.getString('kambate_cached_events_date'), isNull);
    },
  );

  test(
    'saveEvents guarda únicamente eventos dentro de la ventana activa [ayer, hoy, mañana]',
    () async {
      final yesterdayEvent = event.copyWith(
        id: 'yesterday-event',
        startTime: DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day - 1,
          15,
        ),
      );
      final tomorrowEvent = event.copyWith(
        id: 'tomorrow-event',
        startTime: DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day + 1,
          18,
        ),
      );
      final oldHistoricalEvent = event.copyWith(
        id: 'historical-event',
        startTime: DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day - 5,
          12,
        ),
      );
      final farFutureEvent = event.copyWith(
        id: 'future-event',
        startTime: DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day + 4,
          12,
        ),
      );

      await CacheService.saveEvents([
        oldHistoricalEvent,
        yesterdayEvent,
        event,
        tomorrowEvent,
        farFutureEvent,
      ]);

      final cached = await CacheService.getCachedEvents();
      expect(cached, isNotNull);
      expect(
        cached!.map((e) => e.id).toList(),
        equals(['yesterday-event', 'real-event', 'tomorrow-event']),
      );
    },
  );

  test(
    'fetchEventsForDateRange filtra el rango solicitado en UTC bajo demanda',
    () async {
      final targetDay = DateTime(2026, 11, 15);
      final targetEvent = event.copyWith(
        id: 'target-day-event',
        startTime: DateTime(2026, 11, 15, 18, 30).toUtc(),
      );
      final otherDayEvent = event.copyWith(
        id: 'other-day-event',
        startTime: DateTime(2026, 11, 18, 18, 30).toUtc(),
      );

      final repository = TestRepository(events: [targetEvent, otherDayEvent]);
      final result = await repository.fetchEventsForDateRange(
        targetDay,
        targetDay,
      );

      expect(result.map((e) => e.id).toList(), equals(['target-day-event']));
    },
  );

  test(
    'getEventsForDate obtiene los partidos del día especificado respetando hora local',
    () async {
      final requestedDate = DateTime(2026, 11, 20);
      final matchEvent = event.copyWith(
        id: 'date-match-event',
        status: EventStatus.finished,
        homeScore: 3,
        awayScore: 0,
        startTime: DateTime(2026, 11, 20, 15, 0).toUtc(),
      );
      final nextDayEvent = event.copyWith(
        id: 'next-day-match-event',
        startTime: DateTime(2026, 11, 21, 15, 0).toUtc(),
      );

      final repository = TestRepository(events: [matchEvent, nextDayEvent]);
      final result = await repository.getEventsForDate(requestedDate);

      expect(result.length, 1);
      expect(result.single.id, 'date-match-event');
      expect(result.single.homeScore, 3);
      expect(result.single.status, EventStatus.finished);
    },
  );
}
