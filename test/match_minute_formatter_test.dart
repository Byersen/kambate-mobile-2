import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/core/utils/match_minute_formatter.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';

void main() {
  group('MatchMinuteFormatter (Tarea 27: Minuto real en vivo)', () {
    EventModel makeEvent({
      required SportType sport,
      required EventStatus status,
      String? currentPeriod,
      FootballStatsModel? footballStats,
    }) {
      return EventModel(
        id: 'test-event-1',
        sport: sport,
        league: 'Test League',
        status: status,
        startTime: DateTime.now(),
        currentPeriod: currentPeriod,
        footballStats: footballStats,
      );
    }

    test('Minuto disponible estándar en fútbol', () {
      final ev1 = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: "23'",
      );
      expect(MatchMinuteFormatter.format(ev1), '23′');

      final ev2 = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: "67'",
      );
      expect(MatchMinuteFormatter.format(ev2), '67′');

      final evPrime = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: '45′',
      );
      expect(MatchMinuteFormatter.format(evPrime), '45′');

      final evDigitsOnly = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: '12',
      );
      expect(MatchMinuteFormatter.format(evDigitsOnly), '12′');

      final evColonZero = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: '78:00',
      );
      expect(MatchMinuteFormatter.format(evColonZero), '78′');
    });

    test('Respaldo en FootballStats.extraStats["clock"] cuando currentPeriod es null', () {
      final evFallback = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: null,
        footballStats: const FootballStatsModel(
          id: 'fs-1',
          extraStats: {'clock': "34'"},
        ),
      );
      expect(MatchMinuteFormatter.format(evFallback), '34′');
    });

    test(
      'usa el reloj real aunque currentPeriod sea un estado no numérico',
      () {
        final ev = makeEvent(
          sport: SportType.soccer,
          status: EventStatus.live,
          currentPeriod: 'En vivo',
          footballStats: const FootballStatsModel(
            id: 'fs-clock',
            extraStats: {'clock': "42'"},
          ),
        );
        expect(MatchMinuteFormatter.format(ev), '42′');

        final fromDetail = makeEvent(
          sport: SportType.soccer,
          status: EventStatus.live,
          currentPeriod: 'En vivo',
          footballStats: const FootballStatsModel(
            id: 'fs-detail',
            extraStats: {'statusDetail': "45+2'"},
          ),
        );
        expect(MatchMinuteFormatter.format(fromDetail), '45+2′');
      },
    );

    test('lee el descuento ESPN en el payload real de Supabase', () {
      final event = EventModel.fromJson({
        'id': 'espn-live',
        'sport': {'slug': 'football'},
        'status': 'LIVE',
        'startDate': '2026-10-24T20:00:00Z',
        'footballStats': [
          {'id': 'stats-live', 'extraStats': {'clock': "90'+5'"}},
        ],
      });
      expect(MatchMinuteFormatter.format(event), '90+5′');
      expect(MatchMinuteFormatter.formatRawMinute('45′+2′'), '45+2′');
    });

    test('Tiempo añadido real se conserva fielmente y no inventa sumas ni adiciones', () {
      final ev90Plus3 = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: "90+3'",
      );
      expect(MatchMinuteFormatter.format(ev90Plus3), '90+3′');
      expect(MatchMinuteFormatter.format(ev90Plus3), isNot('93′'));

      final ev45Plus2 = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: "45+2'",
      );
      expect(MatchMinuteFormatter.format(ev45Plus2), '45+2′');
      expect(MatchMinuteFormatter.format(ev45Plus2), isNot('47′'));

      final ev105Plus1 = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: '105+1',
      );
      expect(MatchMinuteFormatter.format(ev105Plus1), '105+1′');
    });

    test('Minuto ausente o estados de descanso (HT, Entretiempo, etc.) retornan null', () {
      final evNull = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: null,
      );
      expect(MatchMinuteFormatter.format(evNull), isNull);

      final evEmpty = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: '   ',
      );
      expect(MatchMinuteFormatter.format(evEmpty), isNull);

      final evHt = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: 'HT',
      );
      expect(MatchMinuteFormatter.format(evHt), isNull);

      final evEntretiempo = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: 'Entretiempo',
      );
      expect(MatchMinuteFormatter.format(evEntretiempo), isNull);

      final evDescanso = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: 'Descanso',
      );
      expect(MatchMinuteFormatter.format(evDescanso), isNull);
    });

    test('Valores de otros deportes con semántica no equivalente no se convierten a minutos de fútbol', () {
      // NBA: el reloj es cuenta regresiva de cuarto (e.g. 08:34), no minuto transcurrido
      final nbaLive = makeEvent(
        sport: SportType.nba,
        status: EventStatus.live,
        currentPeriod: '3.er cuarto · 02:34',
      );
      expect(MatchMinuteFormatter.format(nbaLive), isNull);

      final nbaClockOnly = makeEvent(
        sport: SportType.nba,
        status: EventStatus.live,
        currentPeriod: '08:34',
      );
      expect(MatchMinuteFormatter.format(nbaClockOnly), isNull);

      // UFC: reloj de asalto (e.g. 03:14 en round 2)
      final ufcLive = makeEvent(
        sport: SportType.ufc,
        status: EventStatus.live,
        currentPeriod: '03:14',
      );
      expect(MatchMinuteFormatter.format(ufcLive), isNull);

      // LoL y Valorant: partidas o rondas
      final lolLive = makeEvent(
        sport: SportType.lol,
        status: EventStatus.live,
        currentPeriod: 'Partida 3 · 24:15',
      );
      expect(MatchMinuteFormatter.format(lolLive), isNull);

      final valLive = makeEvent(
        sport: SportType.valorant,
        status: EventStatus.live,
        currentPeriod: 'Ascent · Ronda 19',
      );
      expect(MatchMinuteFormatter.format(valLive), isNull);
    });

    test('Estados no-live (SCHEDULED, FINISHED, CANCELED, POSTPONED) retornan null', () {
      final scheduled = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.scheduled,
        currentPeriod: "23'",
      );
      expect(MatchMinuteFormatter.format(scheduled), isNull);

      final finished = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.finished,
        currentPeriod: "90'",
      );
      expect(MatchMinuteFormatter.format(finished), isNull);

      final canceled = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.canceled,
        currentPeriod: "15'",
      );
      expect(MatchMinuteFormatter.format(canceled), isNull);

      final postponed = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.postponed,
        currentPeriod: "0'",
      );
      expect(MatchMinuteFormatter.format(postponed), isNull);
    });
  });
}
