import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/features/league_detail/presentation/screens/league_detail_screen.dart';
import 'package:kambate_mobile/features/league_detail/presentation/widgets/lol_worlds_swiss_view.dart';
import 'package:kambate_mobile/features/league_detail/providers/lol_worlds_provider.dart';
import 'package:kambate_mobile/models/lol_worlds_stage_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';

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

    testWidgets('Muestra cabecera de etapa, selector de rondas, partidos y formato Bo1/Bo3', (tester) async {
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

      // Cabecera de etapa
      expect(find.byKey(const ValueKey('lol-worlds-stage-title')), findsOneWidget);
      expect(find.text('ETAPA SUIZA'), findsOneWidget);
      expect(find.text('Worlds 2026 • Formato Suizo'), findsOneWidget);
      expect(find.text('EN CURSO'), findsOneWidget);

      // Selector de rondas
      expect(find.byKey(const ValueKey('lol-round-chip-all')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-round-chip-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-round-chip-2')), findsOneWidget);

      // Por defecto la ronda 2 está seleccionada (currentRoundNumber: 2)
      expect(find.byKey(const ValueKey('lol-match-card-match-2')), findsOneWidget);
      expect(find.text('Gen.G'), findsOneWidget);
      expect(find.text('Bo3'), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);

      // Cambiar a "Todas" las rondas
      await tester.tap(find.byKey(const ValueKey('lol-round-chip-all')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lol-match-card-match-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('lol-match-card-match-2')), findsOneWidget);
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

      // Cambiar a la pestaña "Tabla Suiza"
      await tester.tap(find.text('Tabla Suiza'));
      await tester.pumpAndSettle();

      // Cabecera de tabla
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
      expect(find.text('Tabla Suiza'), findsNothing);
    });

    testWidgets('LeagueDetailScreen para Worlds renderiza LolWorldsSwissView con Riverpod provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lolWorldsStageProvider('2026').overrideWith(
              (ref) => Future.value(activeSwissStageData),
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
      expect(find.text('ETAPA SUIZA'), findsOneWidget);
    });
  });
}
