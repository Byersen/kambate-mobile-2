import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/sport_type.dart';
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

  final event = EventModel(
    id: 'real-event',
    sport: SportType.soccer,
    league: 'Primera División',
    status: EventStatus.live,
    startTime: DateTime.utc(2026, 10, 4, 21),
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
}
