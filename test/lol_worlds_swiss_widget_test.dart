import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/league_detail/presentation/screens/league_detail_screen.dart';
import 'package:kambate_mobile/features/league_detail/presentation/widgets/lol_worlds_swiss_view.dart';
import 'package:kambate_mobile/features/league_detail/providers/lol_worlds_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/lol_worlds_stage_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/stats_models.dart';
import 'package:kambate_mobile/models/team_model.dart';

void main() {
  group('LolWorldsSwissView & LeagueDetailScreen Worlds (Tarea 30)', () {
    final activeSwissStageData = LolWorldsStageModel(
      version: 1,
      competition: const LolWorldsCompetitionModel(
        slug: 'worlds',
        name: 'League of Legends World Championship',
        sport: 'lol',
      ),
      season: const LolWorldsSeasonModel(
        slug: '2026',
        name: 'Worlds 2026',
        year: 2026,
        isCurrent: true,
      ),
      stage: const LolWorldsStageInfoModel(
        id: 'stage-swiss-2026',
        slug: 'swiss-stage',
        name: 'Etapa Suiza',
        format: 'swiss',
        status: 'in_progress',
        currentRoundNumber: 2,
        totalRounds: 5,
      ),
      rounds: const [
        LolWorldsRoundModel(
          roundNumber: 1,
          name: 'Ronda 1',
          status: 'completed',
          matchIds: ['match-1'],
        ),
        LolWorldsRoundModel(
          roundNumber: 2,
          name: 'Ronda 2',
          status: 'in_progress',
          matchIds: ['match-2'],
        ),
      ],
      matches: [
        LolWorldsMatchModel(
          id: 'match-1',
          roundNumber: 1,
          roundName: 'Ronda 1 (0-0)',
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          status: 'FINISHED',
          homeTeam: const LolWorldsParticipantModel(
            id: 't1',
            name: 'T1',
            code: 'T1',
            score: 1,
          ),
          awayTeam: const LolWorldsParticipantModel(
            id: 'tes',
            name: 'Top Esports',
            code: 'TES',
            score: 0,
          ),
          format: 'Bo1',
          winnerTeamId: 't1',
        ),
        LolWorldsMatchModel(
          id: 'match-2',
          roundNumber: 2,
          roundName: 'Ronda 2 (1-0)',
          startTime: DateTime.now().add(const Duration(hours: 2)),
          status: 'LIVE',
          homeTeam: const LolWorldsParticipantModel(
            id: 'gen',
            name: 'Gen.G',
            code: 'GEN',
            score: 1,
          ),
          awayTeam: const LolWorldsParticipantModel(
            id: 'hle',
            name: 'Hanwha Life Esports',
            code: 'HLE',
            score: 0,
          ),
          format: 'Bo3',
        ),
      ],
      swissStandings: const [
        LolSwissStandingEntryModel(
          position: 1,
          teamId: 't1',
          teamName: 'T1',
          teamCode: 'T1',
          wins: 3,
          losses: 0,
          diff: 3,
          advancementStatus: 'QUALIFIED',
          advancementText: 'Clasificado a Cuartos de Final',
        ),
        LolSwissStandingEntryModel(
          position: 2,
          teamId: 'gen',
          teamName: 'Gen.G',
          teamCode: 'GEN',
          wins: 2,
          losses: 1,
          diff: 1,
          advancementStatus: 'IN_CONTENTION',
          advancementText: null, // Sin texto de avance artificial
        ),
        LolSwissStandingEntryModel(
          position: 16,
          teamId: 'mdk',
          teamName: 'MAD Lions KOI',
          teamCode: 'MDK',
          wins: 0,
          losses: 3,
          diff: -3,
          advancementStatus: 'ELIMINATED',
          advancementText: 'Eliminado',
        ),
      ],
      hasCoverage: true,
      coverageStatus: 'ACTIVE',
    );

    final unconfiguredStageData = LolWorldsStageModel.empty(
      slug: 'worlds',
      name: 'League of Legends World Championship',
      coverageStatus: 'UNCONFIGURED_CREDENTIALS',
      message:
          'La fuente oficial de Worlds requiere credenciales de API (LOL_ESPORTS_API_KEY o PANDASCORE_API_KEY) no configuradas en el entorno.',
    );

    testWidgets('No muestra el banner de etapa finalizada y muestra pestañas Partidos, Tabla y Cuadro Suizo', (tester) async {
      final upcomingPlayoffs = [
        EventModel(
          id: 'qf-1',
          externalId: 'pandascore-lol-match-1711013',
          sport: SportType.lol,
          league: 'League of Legends World Championship',
          status: EventStatus.scheduled,
          startTime: DateTime.now().add(const Duration(hours: 3)),
          homeTeam: const TeamModel(id: 'dk', name: 'Dplus KIA', shortName: 'DK'),
          awayTeam: const TeamModel(id: 'blg', name: 'Bilibili Gaming', shortName: 'BLG'),
          esportsStats: const EsportsStatsModel(
            id: 'es-1',
            format: 'Bo5',
            map: 'Bo5',
            extraStats: {
              'phase': 'Quarterfinal 1: DK vs BLG',
              'tournament': 'Playoffs',
              'format': 'Bo5',
            },
          ),
        ),
        EventModel(
          id: 'sf-1',
          externalId: 'pandascore-lol-match-1711019',
          sport: SportType.lol,
          league: 'League of Legends World Championship',
          status: EventStatus.scheduled,
          startTime: DateTime.now().add(const Duration(days: 3)),
          homeTeam: const TeamModel(id: 'tbd1', name: 'TBD'),
          awayTeam: const TeamModel(id: 'tbd2', name: 'TBD'),
          esportsStats: const EsportsStatsModel(
            id: 'es-2',
            format: 'Bo5',
            map: 'Bo5',
            extraStats: {
              'phase': 'Semifinal 1: TBD vs TBD',
              'tournament': 'Playoffs',
              'format': 'Bo5',
            },
          ),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: activeSwissStageData,
              upcomingEvents: upcomingPlayoffs,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No debe mostrar el banner superior de etapa/group stage finalizado
      expect(find.byKey(const ValueKey('lol-worlds-stage-title')), findsNothing);
      expect(find.text('FINALIZADA'), findsNothing);

      // Pestañas en orden: Partidos (antes de Tabla), Tabla, Cuadro Suizo
      expect(find.text('Partidos'), findsOneWidget);
      expect(find.text('Tabla'), findsOneWidget);
      expect(find.text('Cuadro Suizo'), findsOneWidget);

      // En la primera pestaña ("Partidos") se muestran los partidos futuros agrupados por fecha
      expect(find.byKey(const ValueKey('lol-upcoming-match-qf-1')), findsOneWidget);
      expect(find.text('DK'), findsOneWidget);
      expect(find.text('BLG'), findsOneWidget);
      expect(find.text('Worlds • Cuartos de Final'), findsOneWidget);
      expect(find.text('Worlds • Semifinales'), findsOneWidget);
      expect(find.text('TBD'), findsNWidgets(2));
      expect(find.text('Bo5'), findsWidgets);

      // Cambiar a la pestaña "Cuadro Suizo"
      await tester.tap(find.text('Cuadro Suizo'));
      await tester.pumpAndSettle();

      // Barra inferior de navegación horizontal
      expect(find.byKey(const ValueKey('lol-swiss-bottom-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-bottom-slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-nav-pill-0')), findsOneWidget);

      // Partidos renderizados en el cuadro suizo
      expect(find.byKey(const ValueKey('lol-match-card-match-2')), findsOneWidget);
      expect(find.text('Gen.G'), findsOneWidget);
      expect(find.text('Bo3'), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-match-card-match-1')), findsOneWidget);
      expect(find.text('FINAL'), findsOneWidget);
      expect(find.text('Bo1'), findsOneWidget);
    });

    testWidgets('Muestra tabla suiza con récord W-L, diferencia y avance solo cuando la fuente lo entrega', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: activeSwissStageData,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cambiar a la pestaña "Tabla"
      await tester.tap(find.text('Tabla'));
      await tester.pumpAndSettle();

      expect(find.text('EQUIPO'), findsOneWidget);
      expect(find.text('RÉCORD'), findsOneWidget);
      expect(find.text('DIF'), findsOneWidget);

      // Filas de los equipos
      expect(find.byKey(const ValueKey('lol-standing-row-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-standing-row-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-standing-row-16')), findsOneWidget);

      // Récord W-L
      expect(find.text('3-0'), findsOneWidget);
      expect(find.text('2-1'), findsOneWidget);
      expect(find.text('0-3'), findsOneWidget);

      // Avance: T1 tiene texto oficial de avance
      expect(find.byKey(const ValueKey('lol-advancement-badge-1')), findsOneWidget);
      expect(find.text('Clasificado a Cuartos de Final'), findsOneWidget);

      // MDK tiene insignia de Eliminado
      expect(find.byKey(const ValueKey('lol-advancement-badge-16')), findsOneWidget);
      expect(find.text('Eliminado'), findsOneWidget);

      // Gen.G está en competencia y su advancementText es null, no debe forzar texto ficticio
      expect(find.text('Clasificado a Semifinales'), findsNothing);
    });

    testWidgets('Muestra estado bloqueado/no disponible sin fixtures simulados cuando no hay credenciales', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: unconfiguredStageData,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cobertura oficial no disponible'), findsOneWidget);
      expect(find.textContaining('LOL_ESPORTS_API_KEY o PANDASCORE_API_KEY'), findsOneWidget);
      expect(find.text('Sin datos simulados ni fixtures inventados'), findsOneWidget);
      expect(find.text('Comprobar disponibilidad'), findsOneWidget);

      // No debe renderizar partidos ni tablas ficticias
      expect(find.text('ETAPA SUIZA'), findsNothing);
      expect(find.text('Tabla'), findsNothing);
    });

    testWidgets('LeagueDetailScreen para Worlds renderiza LolWorldsSwissView con Riverpod provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lolWorldsStageProvider('2026').overrideWith(
              (ref) => Future.value(activeSwissStageData),
            ),
            upcomingWorldsMatchesProvider.overrideWith(
              (ref) => Future.value(const <EventModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'Worlds',
              sport: SportType.lol,
              leagueSlug: 'worlds',
              seasonId: '2026',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WORLDS'), findsOneWidget);
      expect(find.byType(LolWorldsSwissView), findsOneWidget);
      expect(find.text('Partidos'), findsOneWidget);
      expect(find.text('Tabla'), findsOneWidget);
    });

    testWidgets('Renderiza formato broadcast suizo con columnas y badges de ADVANCES/ELIMINATED', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: activeSwissStageData,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cambiar a la pestaña "Cuadro Suizo"
      await tester.tap(find.text('Cuadro Suizo'));
      await tester.pumpAndSettle();

      // Barra inferior de navegación
      expect(find.byKey(const ValueKey('lol-swiss-bottom-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-nav-left')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-nav-right')), findsOneWidget);

      // InteractiveViewer para el canvas panorámico
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Badges oficiales de avance de Worlds (R3, R4, R5)
      expect(find.text('ADVANCES'), findsWidgets);
      expect(find.text('1ST/2ND'), findsOneWidget);
      expect(find.text('3RD/4TH/5TH'), findsOneWidget);
      expect(find.text('6TH/7TH/8TH'), findsOneWidget);

      // T1 tiene 3-0 en standings, por lo que figura en ADVANCES 1ST/2ND
      expect(find.text('T1'), findsWidgets);

      // Badges oficiales de eliminación
      expect(find.text('ELIMINATED'), findsWidgets);
    });

    testWidgets('Navega horizontalmente por el Cuadro Suizo usando la barra inferior (flechas, pills y slider)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: activeSwissStageData,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cambiar a la pestaña "Cuadro Suizo"
      await tester.tap(find.text('Cuadro Suizo'));
      await tester.pumpAndSettle();

      // Verificar que la barra inferior existe y tiene los controles
      expect(find.byKey(const ValueKey('lol-swiss-bottom-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-nav-left')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-nav-right')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-bottom-slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-nav-pill-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-swiss-nav-pill-1')), findsOneWidget);

      // Pulsar la flecha derecha para avanzar de columna
      await tester.tap(find.byKey(const ValueKey('lol-swiss-nav-right')));
      await tester.pumpAndSettle();

      // Pulsar en la pill de Ronda 3 (pill-2)
      await tester.tap(find.byKey(const ValueKey('lol-swiss-nav-pill-2')));
      await tester.pumpAndSettle();

      // Muestra partidos del canvas panorámico
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-match-card-match-2')), findsOneWidget);
    });

    testWidgets('Pulsar en una tarjeta de partido abre el modal con detalles del encuentro', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: activeSwissStageData,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cambiar a la pestaña "Cuadro Suizo"
      await tester.tap(find.text('Cuadro Suizo'));
      await tester.pumpAndSettle();

      // Pulsar la tarjeta de match-2
      await tester.tap(find.byKey(const ValueKey('lol-match-card-match-2')));
      await tester.pumpAndSettle();

      // Modal bottom sheet abierto con información del partido
      expect(find.text('Formato: Bo3'), findsOneWidget);
      expect(find.text('RONDA 2 (1-0)'), findsOneWidget);
      expect(find.text('Gen.G'), findsWidgets);
      expect(find.text('Hanwha Life Esports'), findsWidgets);
    });
  });
}
