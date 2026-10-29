import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/core/utils/match_minute_formatter.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';

void main() {
  group('MatchMinuteFormatter (Fútbol y NBA en vivo)', () {
    EventModel makeEvent({
      required SportType sport,
      required EventStatus status,
      String? currentPeriod,
      FootballStatsModel? footballStats,
      NbaStatsModel? nbaStats,
    }) {
      return EventModel(
        id: 'test-event-1',
        sport: sport,
        league: 'Test League',
        status: status,
        startTime: DateTime.now(),
        currentPeriod: currentPeriod,
        footballStats: footballStats,
        nbaStats: nbaStats,
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

    test('usa el reloj real aunque currentPeriod sea un estado no numérico', () {
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
    });

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

    test('Fútbol en entretiempo (HT, Entretiempo, Descanso, Halftime) muestra "ET"', () {
      final evHt = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: 'HT',
      );
      expect(MatchMinuteFormatter.format(evHt), 'ET');

      final evEntretiempo = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: 'Entretiempo',
      );
      expect(MatchMinuteFormatter.format(evEntretiempo), 'ET');

      final evDescanso = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: 'Descanso',
      );
      expect(MatchMinuteFormatter.format(evDescanso), 'ET');

      final evHalftime = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: 'Halftime',
      );
      expect(MatchMinuteFormatter.format(evHalftime), 'ET');

      final evFromStats = makeEvent(
        sport: SportType.soccer,
        status: EventStatus.live,
        currentPeriod: null,
        footballStats: const FootballStatsModel(
          id: 'fs-ht',
          extraStats: {'statusDetail': 'HT'},
        ),
      );
      expect(MatchMinuteFormatter.format(evFromStats), 'ET');
    });

    test('Minuto ausente sin indicación de entretiempo retorna null', () {
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
    });

    group('NBA en vivo (cuarto y reloj)', () {
      test('Formatea cuarto y minuto exacto como "C1 - 3:20" y "C4 - 12:24"', () {
        // Caso de ejemplo 1 del usuario: "C1 - 3:20"
        final c1Sample = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          currentPeriod: 'C1 - 3:20',
        );
        expect(MatchMinuteFormatter.format(c1Sample), 'C1 - 3:20');

        final c1FromStats = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          nbaStats: const NbaStatsModel(
            id: 'nba-1',
            quarter: '1',
            extraStats: {'clock': '3:20'},
          ),
        );
        expect(MatchMinuteFormatter.format(c1FromStats), 'C1 - 3:20');

        // Caso con minutos de dos dígitos: "C4 - 12:24"
        final c4Sample = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          currentPeriod: 'C4 - 12:24',
        );
        expect(MatchMinuteFormatter.format(c4Sample), 'C4 - 12:24');

        final c4FromStats = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          nbaStats: const NbaStatsModel(
            id: 'nba-4',
            quarter: '4',
            extraStats: {'clock': '12:24'},
          ),
        );
        expect(MatchMinuteFormatter.format(c4FromStats), 'C4 - 12:24');
      });

      test('Remueve ceros no significativos de minutos (ej. 03:20 -> 3:20, 04:12 -> 4:12)', () {
        final evLeadingZero = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          nbaStats: const NbaStatsModel(
            id: 'nba-lz',
            quarter: '1st Qtr',
            extraStats: {'clock': '03:20'},
          ),
        );
        expect(MatchMinuteFormatter.format(evLeadingZero), 'C1 - 3:20');

        final evQ3 = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          currentPeriod: 'Q3 04:12',
        );
        expect(MatchMinuteFormatter.format(evQ3), 'C3 - 4:12');

        final evSpanishPeriod = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          currentPeriod: '3.er cuarto · 02:34',
        );
        expect(MatchMinuteFormatter.format(evSpanishPeriod), 'C3 - 2:34');
      });

      test('Soporta prórroga (OT, OT2)', () {
        final otMatch = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          nbaStats: const NbaStatsModel(
            id: 'nba-ot',
            quarter: 'OT',
            extraStats: {'clock': '2:15'},
          ),
        );
        expect(MatchMinuteFormatter.format(otMatch), 'OT - 2:15');

        final ot2Match = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          nbaStats: const NbaStatsModel(
            id: 'nba-ot2',
            quarter: 'OT2',
            extraStats: {'clock': '0:45'},
          ),
        );
        expect(MatchMinuteFormatter.format(ot2Match), 'OT2 - 0:45');
      });

      test('NBA en entretiempo (Halftime / HT) retorna "ET"', () {
        final nbaHalftime = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          currentPeriod: 'Halftime',
        );
        expect(MatchMinuteFormatter.format(nbaHalftime), 'ET');

        final nbaHtStats = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          nbaStats: const NbaStatsModel(
            id: 'nba-ht',
            quarter: 'HT',
          ),
        );
        expect(MatchMinuteFormatter.format(nbaHtStats), 'ET');
      });

      test('Solo cuarto sin reloj muestra "C{n}"', () {
        final evQuarterOnly = makeEvent(
          sport: SportType.nba,
          status: EventStatus.live,
          nbaStats: const NbaStatsModel(
            id: 'nba-q2',
            quarter: '2',
          ),
        );
        expect(MatchMinuteFormatter.format(evQuarterOnly), 'C2');
      });
    });

    test('Valores de otros deportes (UFC, Esports) no inventan minuto y retornan null', () {
      // UFC: reloj de asalto
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

      final scheduledNba = makeEvent(
        sport: SportType.nba,
        status: EventStatus.scheduled,
        currentPeriod: 'C1 - 3:20',
      );
      expect(MatchMinuteFormatter.format(scheduledNba), isNull);

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
