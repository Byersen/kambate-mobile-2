import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kambate_mobile/core/theme/app_theme.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/ufc_fight_detail_screen.dart';
import 'package:kambate_mobile/features/match_detail/presentation/widgets/ufc_cartelera_view.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/models/ufc_card_model.dart';

Map<String, dynamic> sampleUfcCardJson() => {
  'version': 1,
  'cardId': 'ufc-card-santiago',
  'name': 'Santiago',
  'subtitle': 'Cartelera de ejemplo • Hora de Chile',
  'venue': 'Movistar Arena, Santiago',
  'city': 'Santiago',
  'country': 'Chile',
  'status': 'live',
  'fights': [
    {
      'id': 'fight-1',
      'order': 1,
      'segment': 'main',
      'isMainEvent': true,
      'isCoMainEvent': false,
      'weightClass': 'Peso ligero',
      'titleFight': false,
      'roundsScheduled': 5,
      'status': 'scheduled',
      'currentRound': null,
      'clock': null,
      'scheduledTime': null,
      'fighter1': {
        'id': 'f1',
        'name': 'Diego Silva',
        'nickname': 'El Cazador',
        'record': '16-2-0',
        'country': 'Brasil',
        'ranking': '#4',
        'corner': 'red',
      },
      'fighter2': {
        'id': 'f2',
        'name': 'Lucas Costa',
        'nickname': 'Predador',
        'record': '18-4-0',
        'country': 'Brasil',
        'ranking': '#6',
        'corner': 'blue',
      },
      'taleOfTheTape': {
        'division': 'Peso ligero (155 lbs)',
        'record1': '16-2-0',
        'record2': '18-4-0',
        'height1': '1.78 m (5\'10")',
        'height2': '1.80 m (5\'11")',
        'reach1': '180 cm (71")',
        'reach2': '183 cm (72")',
        'stance1': 'Ortodoxa',
        'stance2': 'Switch',
        'age1': '29',
        'age2': '31',
      },
    },
    {
      'id': 'fight-2',
      'order': 2,
      'segment': 'main',
      'isMainEvent': false,
      'isCoMainEvent': true,
      'weightClass': 'Peso wélter',
      'titleFight': false,
      'roundsScheduled': 3,
      'status': 'live',
      'currentRound': 2,
      'clock': '03:12',
      'scheduledTime': null,
      'fighter1': {
        'id': 'f3',
        'name': 'Mateo Rojas',
        'nickname': 'El Tanque',
        'record': '13-1-0',
        'country': 'Chile',
        'ranking': '#8',
        'corner': 'red',
      },
      'fighter2': {
        'id': 'f4',
        'name': 'Bruno Alves',
        'nickname': 'Pitbull',
        'record': '15-3-0',
        'country': 'Brasil',
        'ranking': '#9',
        'corner': 'blue',
      },
      'taleOfTheTape': {
        'division': 'Peso wélter (170 lbs)',
        'record1': '13-1-0',
        'record2': '15-3-0',
        'height1': '1.83 m (6\'0")',
        'height2': '1.85 m (6\'1")',
        'reach1': '188 cm (74")',
        'reach2': '185 cm (73")',
        'stance1': 'Ortodoxa',
        'stance2': 'Ortodoxa',
        'age1': '27',
        'age2': '29',
      },
      'stats': {
        'homeSigStrikes': '42 / 78',
        'awaySigStrikes': '35 / 65',
        'homeSigStrikeRatio': 0.54,
        'homeSigStrikePct': '53%',
        'awaySigStrikePct': '53%',
        'homeSigStrikePctRatio': 0.5,
        'homeTakedowns': '2 / 3',
        'awayTakedowns': '0 / 1',
        'homeTakedownRatio': 1.0,
        'homeSubAttempts': '1',
        'awaySubAttempts': '0',
        'homeSubAttemptRatio': 1.0,
        'homeControlTime': '02:15 min',
        'awayControlTime': '00:45 min',
        'homeControlRatio': 0.75,
        'rounds': [
          {
            'roundNumber': 1,
            'homeSigStrikes': '24 / 45',
            'awaySigStrikes': '20 / 38',
            'homeTotalStrikes': '32 / 54',
            'awayTotalStrikes': '22 / 40',
            'homeTakedowns': '1 / 2',
            'awayTakedowns': '0 / 0',
            'homeControlTime': '01:30',
            'awayControlTime': '00:15',
          },
          {
            'roundNumber': 2,
            'homeSigStrikes': '18 / 33',
            'awaySigStrikes': '15 / 27',
            'homeTotalStrikes': '20 / 35',
            'awayTotalStrikes': '17 / 29',
            'homeTakedowns': '1 / 1',
            'awayTakedowns': '0 / 1',
            'homeControlTime': '00:45',
            'awayControlTime': '00:30',
          },
        ],
      },
    },
    {
      'id': 'fight-3',
      'order': 3,
      'segment': 'prelims',
      'isMainEvent': false,
      'isCoMainEvent': false,
      'weightClass': 'Peso pluma',
      'titleFight': false,
      'roundsScheduled': 3,
      'status': 'finished',
      'currentRound': 2,
      'clock': '01:48',
      'fighter1': {
        'id': 'f5',
        'name': 'Tomás Vega',
        'nickname': 'El Rayo',
        'record': '11-2-0',
        'country': 'Chile',
        'corner': 'red',
      },
      'fighter2': {
        'id': 'f6',
        'name': 'Rafael Lima',
        'nickname': 'Samurai',
        'record': '12-4-0',
        'country': 'Brasil',
        'corner': 'blue',
      },
      'result': {
        'winnerId': 'f5',
        'winnerName': 'Vega',
        'method': 'KO/TKO',
        'methodDetail': 'Golpes',
        'round': 2,
        'time': '01:48',
      },
    },
    {
      'id': 'fight-4',
      'order': 4,
      'segment': 'prelims',
      'isMainEvent': false,
      'isCoMainEvent': false,
      'weightClass': 'Peso mosca',
      'titleFight': false,
      'roundsScheduled': 3,
      'status': 'finished',
      'currentRound': 3,
      'clock': '05:00',
      'fighter1': {
        'id': 'f7',
        'name': 'Ana Torres',
        'nickname': 'La Furia',
        'record': '9-1-0',
        'country': 'Chile',
        'corner': 'red',
      },
      'fighter2': {
        'id': 'f8',
        'name': 'Carla Mendes',
        'nickname': 'Guerreira',
        'record': '10-3-0',
        'country': 'Brasil',
        'corner': 'blue',
      },
      'result': {
        'winnerId': 'f7',
        'winnerName': 'Torres',
        'method': 'Decisión unánime',
        'methodDetail': '30-27, 29-28, 29-28',
        'round': 3,
        'time': '05:00',
      },
    },
  ],
};

EventModel buildSampleUfcEvent({Map<String, dynamic>? cardPayload}) {
  return EventModel(
    id: 'ufc-event-test',
    sport: SportType.ufc,
    league: 'UFC • Noche de combates',
    status: EventStatus.live,
    startTime: DateTime(2026, 10, 20, 20, 0),
    venue: 'Movistar Arena, Santiago',
    fighter1: const FighterModel(
      id: 'f1',
      name: 'Diego Silva',
      record: '16-2-0',
      weightClass: 'Peso ligero',
    ),
    fighter2: const FighterModel(
      id: 'f2',
      name: 'Lucas Costa',
      record: '18-4-0',
      weightClass: 'Peso ligero',
    ),
    ufcStats: UfcStatsModel(
      id: 'us-test',
      winnerName: null,
      round: 2,
      time: '03:12',
      extraStats: {
        'card': cardPayload ?? sampleUfcCardJson(),
      },
    ),
  );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Contrato UfcCardModel y dominio', () {
    test('Parsea versión 1 y rechaza versiones desconocidas', () {
      final json = sampleUfcCardJson();
      final model = UfcCardModel.parse(json);
      expect(model, isNotNull);
      expect(model!.version, equals(1));
      expect(model.name, equals('Santiago'));
      expect(model.fights.length, equals(4));

      final invalid = UfcCardModel.parse({'version': 99, 'name': 'Test'});
      expect(invalid, isNull);
    });

    test('Preserva el orden estricto de los combates', () {
      final json = sampleUfcCardJson();
      final model = UfcCardModel.parse(json)!;

      for (var i = 0; i < model.fights.length; i++) {
        expect(model.fights[i].order, equals(i + 1));
      }
    });

    test('Clasifica combates en mainCard y prelims adecuadamente', () {
      final model = UfcCardModel.parse(sampleUfcCardJson())!;
      expect(model.mainFights.length, equals(2));
      expect(model.prelimFights.length, equals(2));
      expect(model.mainEvent?.isMainEvent, isTrue);
      expect(model.mainEvent?.fighter1.name, equals('Diego Silva'));
    });

    test('Detecta combate en vivo activo en la cartelera', () {
      final model = UfcCardModel.parse(sampleUfcCardJson())!;
      expect(model.liveFight, isNotNull);
      expect(model.liveFight!.fighter1.name, equals('Mateo Rojas'));
      expect(model.liveFight!.clock, equals('03:12'));
    });

    test('Usa A continuación para combates programados sin hora individual', () {
      final model = UfcCardModel.parse(sampleUfcCardJson())!;
      final fight1 = model.fights[0];
      expect(fight1.isScheduled, isTrue);
      expect(fight1.scheduledTime, isNull);
      expect(fight1.timeOrOrderLabel, equals('A continuación'));
    });

    test('Formatea resultado oficial sin inventar datos', () {
      final model = UfcCardModel.parse(sampleUfcCardJson())!;
      final fight3 = model.fights[2];
      expect(fight3.hasConfirmedResult, isTrue);
      expect(
        fight3.result?.formattedSummary(fallbackWinner: fight3.winnerName),
        equals('Ganó Vega • KO/TKO • A2 • 01:48'),
      );

      final fight4 = model.fights[3];
      expect(
        fight4.result?.formattedSummary(fallbackWinner: fight4.winnerName),
        equals('Ganó Torres • Decisión unánime • A3 • 05:00'),
      );
    });

    test('UfcCardModel.fromEvent construye cartelera segura si no hay extraStats', () {
      final basicEvent = EventModel(
        id: 'ufc-basic',
        sport: SportType.ufc,
        league: 'UFC 300',
        status: EventStatus.scheduled,
        startTime: DateTime.utc(2026, 10, 20),
        fighter1: const FighterModel(id: 'f-a', name: 'Peleador A'),
        fighter2: const FighterModel(id: 'f-b', name: 'Peleador B'),
      );

      final synthesized = UfcCardModel.fromEvent(basicEvent);
      expect(synthesized.name, equals('UFC 300'));
      expect(synthesized.fights.length, equals(1));
      expect(synthesized.fights.first.fighter1.name, equals('Peleador A'));
      expect(synthesized.fights.first.timeOrOrderLabel, equals('A continuación'));
    });

    test('UfcCardModel.fromEvents agrupa múltiples combates individuales de una velada', () {
      final startTime = DateTime(2024, 10, 26, 14, 0);
      final events = List.generate(6, (index) {
        final order = index + 1;
        final isMain = order == 1;
        final isCoMain = order == 2;
        return EventModel(
          id: 'event-$order',
          externalId: 'ufc-308-comp-$order',
          sport: SportType.ufc,
          league: 'UFC 308: Topuria vs. Holloway',
          venue: 'Etihad Arena, Abu Dhabi',
          status: EventStatus.finished,
          startTime: startTime,
          fighter1: FighterModel(
            id: 'f1-$order',
            name: isMain ? 'Ilia Topuria' : (isCoMain ? 'Robert Whittaker' : 'Peleador 1-$order'),
            weightClass: isMain ? 'Peso pluma' : 'Peso medio',
          ),
          fighter2: FighterModel(
            id: 'f2-$order',
            name: isMain ? 'Max Holloway' : (isCoMain ? 'Khamzat Chimaev' : 'Peleador 2-$order'),
            weightClass: isMain ? 'Peso pluma' : 'Peso medio',
          ),
          ufcStats: UfcStatsModel(
            id: 'stats-$order',
            round: isMain || isCoMain ? 5 : 3,
            time: '01:34',
            method: 'KO / TKO',
            winnerName: isMain ? 'Ilia Topuria' : 'Khamzat Chimaev',
          ),
        );
      });

      final card = UfcCardModel.fromEvents(events, currentEvent: events.first);

      expect(card.cardId, equals('ufc-card-308'));
      expect(card.name, equals('UFC 308: Topuria vs. Holloway'));
      expect(card.venue, equals('Etihad Arena, Abu Dhabi'));
      expect(card.date, equals(startTime));
      expect(card.formattedDate, isNotNull);
      expect(card.fights.length, equals(6));
      expect(card.mainFights.length, equals(5));
      expect(card.prelimFights.length, equals(1));
      expect(card.mainEvent?.fighter1.name, equals('Ilia Topuria'));
      expect(card.mainEvent?.isMainEvent, isTrue);
      expect(card.coMainEvent?.fighter1.name, equals('Robert Whittaker'));
      expect(card.coMainEvent?.isCoMainEvent, isTrue);
      expect(card.mainEvent?.result?.winnerName, equals('Ilia Topuria'));
    });

    test('UfcCardModel.fromEvent con allEvents agrupa combates hermanos automáticamente', () {
      final startTime = DateTime(2024, 10, 26, 14, 0);
      final events = List.generate(4, (index) {
        final order = index + 1;
        return EventModel(
          id: 'ev-$order',
          externalId: 'ufc-308-c-$order',
          sport: SportType.ufc,
          league: 'UFC 308',
          venue: 'Etihad Arena',
          status: EventStatus.scheduled,
          startTime: startTime,
          fighter1: FighterModel(id: 'a-$order', name: 'Luchador A-$order'),
          fighter2: FighterModel(id: 'b-$order', name: 'Luchador B-$order'),
        );
      });

      final card = UfcCardModel.fromEvent(events.first, allEvents: events);
      expect(card.fights.length, equals(4));
      expect(card.venue, equals('Etihad Arena'));
    });

    test('Conserva estados parciales sin rellenar registros ni ranking ficticios', () {
      final sparseEvent = EventModel(
        id: 'ufc-sparse',
        sport: SportType.ufc,
        league: 'UFC Fight Night',
        status: EventStatus.scheduled,
        startTime: DateTime(2025, 1, 1),
        fighter1: const FighterModel(id: 'f1', name: 'Peleador Sin Récord'),
        fighter2: const FighterModel(id: 'f2', name: 'Peleador Sin Récord 2'),
      );

      final card = UfcCardModel.fromEvent(sparseEvent);
      final fight = card.fights.first;
      expect(fight.fighter1.record, isNull);
      expect(fight.fighter1.ranking, isNull);
      expect(fight.fighter1.nickname, isNull);
      expect(fight.result, isNull);
      expect(fight.taleOfTheTape?.record1, isNull);
    });
  });

  group('Interfaz y widgets de Cartelera UFC', () {
    testWidgets('Header muestra disciplina UFC, título Santiago, subtítulo y EVENTO EN CURSO', (tester) async {
      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UfcCarteleraView(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UFC'), findsWidgets);
      expect(find.text('Santiago'), findsOneWidget);
      expect(find.text('Cartelera de ejemplo • Hora de Chile'), findsOneWidget);
      expect(find.text('EVENTO EN CURSO'), findsOneWidget);
    });

    testWidgets('Banner superior muestra Ir al combate en vivo y nombres del combate activo', (tester) async {
      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UfcCarteleraView(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ir al combate en vivo'), findsOneWidget);
      expect(find.textContaining('Mateo Rojas vs Bruno Alves'), findsOneWidget);
    });

    testWidgets('Filtros Todas, Principal y Preliminares aíslan combates correctamente', (tester) async {
      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UfcCarteleraView(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Por defecto "Todas": se muestran ambas secciones
      expect(find.byKey(const Key('section-header-main')), findsOneWidget);
      expect(find.byKey(const Key('section-header-prelims')), findsOneWidget);
      expect(find.text('Diego Silva'), findsOneWidget);
      expect(find.text('Tomás Vega'), findsOneWidget);

      // Pulsar "Principal"
      await tester.tap(find.byKey(const Key('filter-pill-Principal')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section-header-main')), findsOneWidget);
      expect(find.byKey(const Key('section-header-prelims')), findsNothing);
      expect(find.text('Diego Silva'), findsOneWidget);
      expect(find.text('Tomás Vega'), findsNothing);

      // Pulsar "Preliminares"
      await tester.tap(find.byKey(const Key('filter-pill-Preliminares')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section-header-main')), findsNothing);
      expect(find.byKey(const Key('section-header-prelims')), findsOneWidget);
      expect(find.text('Diego Silva'), findsNothing);
      expect(find.text('Tomás Vega'), findsOneWidget);

      // Volver a "Todas"
      await tester.tap(find.byKey(const Key('filter-pill-Todas')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section-header-main')), findsOneWidget);
      expect(find.byKey(const Key('section-header-prelims')), findsOneWidget);
    });

    testWidgets('Combate estelar muestra COMBATE ESTELAR y A continuación', (tester) async {
      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UfcCarteleraView(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('COMBATE ESTELAR'), findsOneWidget);
      expect(find.text('A continuación'), findsOneWidget);
    });

    testWidgets('Combates finalizados muestran resultado oficial confirmado', (tester) async {
      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UfcCarteleraView(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ganó Vega • KO/TKO • A2 • 01:48'), findsOneWidget);
      expect(find.textContaining('Ganó Torres • Decisión unánime'), findsOneWidget);
    });

    testWidgets('Pestaña Información muestra sede y detalles de la velada', (tester) async {
      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UfcCarteleraView(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Información'));
      await tester.pumpAndSettle();

      expect(find.text('DETALLES DE LA VELADA'), findsOneWidget);
      expect(find.text('Movistar Arena, Santiago'), findsOneWidget);
      expect(find.text('Santiago, Chile'), findsOneWidget);
      expect(find.text('Total de combates'), findsOneWidget);
      expect(find.text('Promoción'), findsOneWidget);
      expect(find.text('Ultimate Fighting Championship (UFC)'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Combate estelar'), findsOneWidget);
    });

    testWidgets('Pulsar una pelea abre el detalle de combate y volver regresa a la cartelera', (tester) async {
      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UfcCarteleraView(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pulsar la tarjeta de Mateo Rojas vs Bruno Alves
      await tester.tap(find.text('Mateo Rojas'));
      await tester.pumpAndSettle();

      // Verificamos que se abrió la pantalla de detalle del combate
      expect(find.byType(UfcFightDetailScreen), findsOneWidget);
      expect(find.text('TALE OF THE TAPE • CARA A CARA'), findsNothing); // Estamos en Resumen

      // Conmutar a "Cara a cara"
      await tester.tap(find.text('Cara a cara'));
      await tester.pumpAndSettle();
      expect(find.text('TALE OF THE TAPE • CARA A CARA'), findsOneWidget);
      expect(find.text('Peso wélter (170 lbs)'), findsWidgets);

      // Conmutar a "Estadísticas"
      await tester.tap(find.text('Estadísticas'));
      await tester.pumpAndSettle();
      expect(find.text('ESTADÍSTICAS DEL COMBATE'), findsOneWidget);
      expect(find.text('Golpes Significativos'), findsOneWidget);
      expect(find.text('ESTADÍSTICAS POR ASALTO DISPONIBLES'), findsOneWidget);
      expect(find.text('Asalto 1'), findsOneWidget);

      // Pulsar botón de volver (conservar retorno)
      await tester.tap(find.byTooltip('Volver a la cartelera'));
      await tester.pumpAndSettle();

      // Regresamos a la cartelera
      expect(find.byType(UfcFightDetailScreen), findsNothing);
      expect(find.text('Santiago'), findsOneWidget);
      expect(find.text('Cartelera principal'), findsOneWidget);
    });

    testWidgets('Pulsar Ir al combate en vivo abre directamente la pelea activa', (tester) async {
      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UfcCarteleraView(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ir al combate en vivo'));
      await tester.pumpAndSettle();

      expect(find.byType(UfcFightDetailScreen), findsOneWidget);
      expect(find.text('Mateo Rojas'), findsOneWidget);
      expect(find.text('Bruno Alves'), findsOneWidget);
      expect(find.textContaining('EN VIVO'), findsWidgets);
    });

    testWidgets('Maneja escala de texto x2 y ancho estrecho sin desbordamientos', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final event = buildSampleUfcEvent();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: UfcCarteleraView(event: event),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
