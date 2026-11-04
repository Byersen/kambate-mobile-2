import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/league_detail/presentation/screens/league_detail_screen.dart';
import 'package:kambate_mobile/features/league_detail/presentation/widgets/ufc_rankings_view.dart';
import 'package:kambate_mobile/features/league_detail/presentation/widgets/ufc_upcoming_cards_view.dart';
import 'package:kambate_mobile/features/league_detail/providers/ufc_rankings_provider.dart';
import 'package:kambate_mobile/features/match_detail/presentation/screens/ufc_fight_detail_screen.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/ufc_card_model.dart';
import 'package:kambate_mobile/models/ufc_rankings_model.dart';

Map<String, dynamic> sampleBackendRankingsJson() => {
      'version': 1,
      'sport': 'ufc',
      'hasCoverage': true,
      'updatedAt': '2024-10-26T14:00:00Z',
      'categories': [
        {
          'id': 'pound-for-pound',
          'name': "Men's Pound for Pound Rankings",
          'translatedName': 'Libra por libra masculino',
          'weightLimit': null,
          'gender': 'MALE',
          'champion': null,
          'ranks': [
            {
              'position': 1,
              'athleteId': '3088812',
              'participantId': 'part-usman',
              'name': 'Kamaru Usman',
              'nickname': 'Nigerian Nightmare',
              'record': '21-5-0',
              'photoUrl': 'https://a.espncdn.com/usman.png',
              'trend': '-',
            },
            {
              'position': 2,
              'athleteId': '3933168',
              'participantId': 'part-volk',
              'name': 'Alexander Volkanovski',
              'nickname': 'The Great',
              'record': '26-4-0',
              'photoUrl': 'https://a.espncdn.com/volk.png',
              'trend': '+1',
            },
          ],
        },
        {
          'id': 'heavyweight',
          'name': 'Heavyweight Division Rankings (Up to 265 pounds)',
          'translatedName': 'Peso pesado',
          'weightLimit': 'Hasta 265 lbs',
          'gender': 'MALE',
          'champion': {
            'athleteId': '5001',
            'participantId': 'part-ngannou',
            'name': 'Francis Ngannou',
            'nickname': 'The Predator',
            'record': '19-3-0',
            'photoUrl': 'https://a.espncdn.com/ngannou.png',
            'defenses': 2,
            'trend': '-',
          },
          'ranks': [
            {
              'position': 1,
              'athleteId': '5002',
              'name': 'Ciryl Gane',
              'nickname': 'Bon Gamin',
              'record': '12-2-0',
              'trend': '-',
            },
            {
              'position': 2,
              'athleteId': '5003',
              'name': 'Tom Aspinall',
              'record': '15-3-0',
              'trend': '+1',
            },
          ],
        },
      ],
    };

Map<String, dynamic> sampleRawEspnRankingsJson() => {
      'rankings': [
        {
          'id': '1',
          'name': "Men's Pound for Pound Rankings",
          'type': 'pound-for-pound',
          'gender': 'MALE',
          'ranks': [
            {
              'current': 1,
              'trend': '-',
              'recordSummary': '21-5-0',
              'athlete': {
                'id': '3088812',
                'displayName': 'Kamaru Usman',
                'nickname': 'Nigerian Nightmare',
                'headshot': {'href': 'https://espn.com/headshots/3088812.png'},
              },
            },
          ],
        },
        {
          'id': '3',
          'name': 'Heavyweight Division Champions (Up to 265 pounds)',
          'type': 'heavyweight-champions',
          'gender': 'MALE',
          'weightClass': {'slug': 'heavyweight', 'text': 'Heavyweight'},
          'ranks': [
            {
              'current': 1,
              'hasAccolade': true,
              'defenses': 2,
              'recordSummary': '19-3-0',
              'athlete': {
                'id': '5001',
                'displayName': 'Francis Ngannou',
                'nickname': 'The Predator',
              },
            },
          ],
        },
        {
          'id': '13',
          'name': 'Heavyweight Division Rankings (Up to 265 pounds)',
          'type': 'heavyweight',
          'gender': 'MALE',
          'weightClass': {'slug': 'heavyweight', 'text': 'Heavyweight'},
          'ranks': [
            {
              'current': 1,
              'trend': '-',
              'recordSummary': '12-2-0',
              'athlete': {
                'id': '5002',
                'displayName': 'Ciryl Gane',
              },
            },
          ],
        },
      ],
    };

List<EventModel> buildSampleUfcEvents() {
  final now = DateTime.now();

  return [
    // Velada pasada (Finalizada) - Debe ser excluida de las próximas carteleras
    EventModel(
      id: 'ufc-past-1',
      externalId: 'ufc-307-comp-1',
      sport: SportType.ufc,
      league: 'UFC 307: Pereira vs. Rountree',
      startTime: now.subtract(const Duration(days: 14)),
      status: EventStatus.finished,
    ),
    // Velada futura A (dentro de 7 días, dos combates de la misma velada)
    EventModel(
      id: 'ufc-fut-1',
      externalId: 'ufc-310-comp-1',
      sport: SportType.ufc,
      league: 'UFC 310: Pantoja vs. Asakura',
      venue: 'T-Mobile Arena, Las Vegas',
      startTime: now.add(const Duration(days: 7)),
      status: EventStatus.scheduled,
      fighter1: const FighterModel(id: 'f1', name: 'Alexandre Pantoja', weightClass: 'Peso mosca'),
      fighter2: const FighterModel(id: 'f2', name: 'Kai Asakura', weightClass: 'Peso mosca'),
    ),
    EventModel(
      id: 'ufc-fut-2',
      externalId: 'ufc-310-comp-2',
      sport: SportType.ufc,
      league: 'UFC 310: Pantoja vs. Asakura',
      venue: 'T-Mobile Arena, Las Vegas',
      startTime: now.add(const Duration(days: 7, hours: 2)),
      status: EventStatus.scheduled,
      fighter1: const FighterModel(id: 'f3', name: 'Shavkat Rakhmonov', weightClass: 'Peso wélter'),
      fighter2: const FighterModel(id: 'f4', name: 'Ian Machado Garry', weightClass: 'Peso wélter'),
    ),
    // Velada futura B (dentro de 30 días)
    EventModel(
      id: 'ufc-fut-3',
      externalId: 'ufc-311-comp-1',
      sport: SportType.ufc,
      league: 'UFC 311: Makhachev vs. Tsarukyan 2',
      venue: 'Intuit Dome, Los Angeles',
      startTime: now.add(const Duration(days: 30)),
      status: EventStatus.scheduled,
      fighter1: const FighterModel(id: 'f5', name: 'Islam Makhachev', weightClass: 'Peso ligero'),
      fighter2: const FighterModel(id: 'f6', name: 'Arman Tsarukyan', weightClass: 'Peso ligero'),
    ),
  ];
}

void main() {
  group('Contrato UfcRankingsModel y dominio', () {
    test('Parsea contrato v1 desde backend con campeones y contendientes', () {
      final model = UfcRankingsModel.fromJson(sampleBackendRankingsJson());

      expect(model.version, equals(1));
      expect(model.sport, equals('ufc'));
      expect(model.hasCoverage, isTrue);
      expect(model.categories.length, equals(2));

      // Libra por libra
      final p4p = model.categories.first;
      expect(p4p.id, equals('pound-for-pound'));
      expect(p4p.translatedName, equals('Libra por libra masculino'));
      expect(p4p.champion, isNull);
      expect(p4p.ranks.length, equals(2));
      expect(p4p.ranks[0].position, equals(1));
      expect(p4p.ranks[0].name, equals('Kamaru Usman'));
      expect(p4p.ranks[0].nickname, equals('Nigerian Nightmare'));
      expect(p4p.ranks[0].record, equals('21-5-0'));
      expect(p4p.ranks[1].position, equals(2));
      expect(p4p.ranks[1].trend, equals('+1'));

      // Peso pesado
      final hw = model.categories[1];
      expect(hw.id, equals('heavyweight'));
      expect(hw.translatedName, equals('Peso pesado'));
      expect(hw.weightLimit, equals('Hasta 265 lbs'));
      expect(hw.champion, isNotNull);
      expect(hw.champion!.name, equals('Francis Ngannou'));
      expect(hw.champion!.nickname, equals('The Predator'));
      expect(hw.champion!.record, equals('19-3-0'));
      expect(hw.champion!.defenses, equals(2));
      expect(hw.champion!.participantId, equals('part-ngannou'));
      expect(hw.ranks.length, equals(2));
      expect(hw.ranks[0].position, equals(1));
      expect(hw.ranks[0].name, equals('Ciryl Gane'));
    });

    test('Parser de contingencia client-side desde raw ESPN empareja campeones', () {
      final model = UfcRankingsModel.fromEspnRaw(sampleRawEspnRankingsJson());

      expect(model.hasCoverage, isTrue);
      expect(model.categories.length, equals(2));

      final hw = model.categories.firstWhere((c) => c.id == 'heavyweight');
      expect(hw.champion, isNotNull);
      expect(hw.champion!.name, equals('Francis Ngannou'));
      expect(hw.champion!.defenses, equals(2));
      expect(hw.ranks.first.name, equals('Ciryl Gane'));
      expect(hw.ranks.first.position, equals(1));
    });

    test('Conserva estados parciales sin rellenar datos ficticios', () {
      final partial = UfcRankingsModel.fromJson({
        'version': 1,
        'categories': [
          {
            'id': 'middleweight',
            'name': 'Middleweight',
            'translatedName': 'Peso medio',
            'ranks': [
              {
                'position': 1,
                'athleteId': '123',
                'name': 'Peleador Parcial',
              }
            ],
          }
        ],
      });

      final fighter = partial.categories.first.ranks.first;
      expect(fighter.name, equals('Peleador Parcial'));
      expect(fighter.nickname, isNull);
      expect(fighter.record, isNull);
      expect(fighter.photoUrl, isNull);
      expect(fighter.participantId, isNull);
    });

    test('Maneja contrato vacío sin cobertura explícita', () {
      final empty = UfcRankingsModel.empty();
      expect(empty.hasCoverage, isFalse);
      expect(empty.categories, isEmpty);
    });
  });

  group('Agrupación de carteleras futuras (UfcCardModel.groupUpcomingCards)', () {
    test('Agrupa peleas de la misma velada y excluye peleas pasadas finalizadas', () {
      final events = buildSampleUfcEvents();
      final cards = UfcCardModel.groupUpcomingCards(events);

      // Debe haber exactamente 2 veladas futuras (UFC 310 y UFC 311)
      expect(cards.length, equals(2));

      // UFC 307 (finalizada) fue excluida
      expect(cards.any((c) => c.name.contains('307')), isFalse);

      // UFC 310 agrupa sus dos combates hermanos
      final ufc310 = cards.firstWhere((c) => c.name.contains('310'));
      expect(ufc310.fights.length, equals(2));
      expect(ufc310.venue, contains('T-Mobile Arena'));

      // UFC 311 contiene su combate
      final ufc311 = cards.firstWhere((c) => c.name.contains('311'));
      expect(ufc311.fights.length, equals(1));

      // Ordenadas cronológicamente (UFC 310 antes que UFC 311)
      expect(cards[0].name, contains('310'));
      expect(cards[1].name, contains('311'));
    });

    test('Retorna lista vacía si no hay eventos futuros', () {
      final now = DateTime.now();
      final pastOnly = [
        EventModel(
          id: 'past',
          sport: SportType.ufc,
          league: 'UFC Pasado',
          startTime: now.subtract(const Duration(days: 30)),
          status: EventStatus.finished,
        ),
      ];

      final cards = UfcCardModel.groupUpcomingCards(pastOnly);
      expect(cards, isEmpty);
    });
  });

  group('Interfaz y widgets de Sección UFC', () {
    testWidgets('Al entrar a UFC ofrece apartados separados para Próximas carteleras y Rankings', (tester) async {
      final rankings = UfcRankingsModel.fromJson(sampleBackendRankingsJson());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ufcRankingsProvider.overrideWith((ref) => Future.value(rankings)),
            upcomingUfcCardsProvider.overrideWith((ref) => Future.value(<EventModel>[])),
          ],
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'UFC',
              sport: SportType.ufc,
              leagueSlug: 'ufc',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica los dos apartados separados en el TabBar
      expect(find.text('Próximas carteleras'), findsOneWidget);
      expect(find.text('Rankings'), findsOneWidget);

      // Pestaña inicial muestra la vista de próximas carteleras
      expect(find.byType(UfcUpcomingCardsView), findsOneWidget);

      // Cambiar a la pestaña de Rankings
      await tester.tap(find.text('Rankings'));
      await tester.pumpAndSettle();

      // Se muestra la vista de rankings
      expect(find.byType(UfcRankingsView), findsOneWidget);

      // Cambiar de regreso a Próximas carteleras
      await tester.tap(find.text('Próximas carteleras'));
      await tester.pumpAndSettle();

      expect(find.byType(UfcUpcomingCardsView), findsOneWidget);
    });

    testWidgets('UfcRankingsView muestra divisiones plegadas y expande el ranking', (tester) async {
      final rankings = UfcRankingsModel.fromJson(sampleBackendRankingsJson());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UfcRankingsView(
              rankings: rankings,
              allEvents: buildSampleUfcEvents(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Todas las divisiones son visibles antes de abrir un ranking.
      expect(find.text('Peso pesado'), findsOneWidget);
      expect(find.text('Kamaru Usman "Nigerian Nightmare"'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('ufc-division-pound-for-pound')));
      await tester.pumpAndSettle();
      expect(find.text('LIBRA POR LIBRA MASCULINO'), findsOneWidget);
      expect(find.text('Kamaru Usman "Nigerian Nightmare"'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('Récord: 21-5-0'), findsNothing); // P4P contender record is in row
      expect(find.text('21-5-0'), findsOneWidget);

      // Cambiar a Peso pesado
      await tester.tap(find.text('Peso pesado'));
      await tester.pumpAndSettle();

      // Se despliega el campeón oficial de la división
      expect(find.text('CAMPEÓN DE LA DIVISIÓN'), findsOneWidget);
      expect(find.text('Francis Ngannou'), findsOneWidget);
      expect(find.text('"The Predator"'), findsOneWidget);
      expect(find.text('2 defensas'), findsOneWidget);
      expect(find.text('Hasta 265 lbs'), findsOneWidget);

      // Se despliegan los contendientes de Peso pesado
      expect(find.text('Ciryl Gane "Bon Gamin"'), findsOneWidget);
      expect(find.text('Tom Aspinall'), findsOneWidget);
    });

    testWidgets('UfcUpcomingCardsView agrupa carteleras y permite navegar a combate', (tester) async {
      final events = buildSampleUfcEvents();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UfcUpcomingCardsView(
              allEvents: events,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Muestra la cartelera futura UFC 310
      expect(find.text('UFC 310: Pantoja vs. Asakura'), findsOneWidget);

      // Cartelera desplegada muestra combates
      expect(find.text('Alexandre Pantoja'), findsOneWidget);
      expect(find.text('Kai Asakura'), findsOneWidget);

      // Pulsar el combate abre la pantalla de detalle de combate UFC
      await tester.tap(find.text('Alexandre Pantoja'));
      await tester.pumpAndSettle();

      expect(find.byType(UfcFightDetailScreen), findsOneWidget);

      // Retorno desde el detalle regresa a la lista de carteleras
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(UfcUpcomingCardsView), findsOneWidget);
    });

    testWidgets('Muestra estado limpio sin cobertura cuando no hay rankings disponibles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UfcRankingsView(
              rankings: UfcRankingsModel.empty(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cobertura no disponible'), findsOneWidget);
      expect(
        find.text('No se pudieron cargar los rankings oficiales de UFC desde la fuente oficial.'),
        findsOneWidget,
      );
    });

    testWidgets('Muestra estado limpio cuando no hay próximas carteleras programadas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UfcUpcomingCardsView(
              allEvents: [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No hay próximas carteleras'), findsOneWidget);
      expect(
        find.text('Actualmente no hay veladas de UFC programadas en el calendario oficial.'),
        findsOneWidget,
      );
    });
  });
}
