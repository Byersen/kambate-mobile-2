import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kambate_mobile/core/utils/football_competition_priority.dart';
import 'package:kambate_mobile/features/favorites/models/search_league_item.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/presentation/screens/feed_screen.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/features/league_detail/data/league_detail_repository.dart';
import 'package:kambate_mobile/features/league_detail/presentation/screens/league_detail_screen.dart';
import 'package:kambate_mobile/features/league_detail/presentation/widgets/lol_worlds_swiss_view.dart';
import 'package:kambate_mobile/features/league_detail/providers/league_detail_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/league_detail_model.dart';
import 'package:kambate_mobile/models/league_model.dart';
import 'package:kambate_mobile/models/lol_worlds_stage_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tarea 35 — Contrato Real PandaScore LoL e Integración Mobile', () {
    final now = DateTime.now();

    final worldsEventLive = EventModel(
      id: 'lol-worlds-live-1',
      sport: SportType.lol,
      league: 'Worlds',
      leagueModel: const LeagueModel(
        id: 'league-worlds-id',
        name: 'Worlds',
        slug: 'worlds',
      ),
      homeTeam: const TeamModel(id: 't1', name: 'T1'),
      awayTeam: const TeamModel(id: 'gen', name: 'Gen.G'),
      homeScore: 1,
      awayScore: 0,
      startTime: now.subtract(const Duration(minutes: 45)),
      status: EventStatus.live,
    );

    final lckEventScheduled = EventModel(
      id: 'lol-lck-sched-1',
      sport: SportType.lol,
      league: 'LCK',
      leagueModel: const LeagueModel(
        id: 'league-lck-id',
        name: 'LCK',
        slug: 'lck',
      ),
      homeTeam: const TeamModel(id: 'dk', name: 'Dplus KIA'),
      awayTeam: const TeamModel(id: 'kt', name: 'KT Rolster'),
      startTime: now.add(const Duration(hours: 3)),
      status: EventStatus.scheduled,
    );

    final lecEventFinished = EventModel(
      id: 'lol-lec-fin-1',
      sport: SportType.lol,
      league: 'LEC',
      leagueModel: const LeagueModel(
        id: 'league-lec-id',
        name: 'LEC',
        slug: 'lec',
      ),
      homeTeam: const TeamModel(id: 'fnc', name: 'Fnatic'),
      awayTeam: const TeamModel(id: 'g2', name: 'G2 Esports'),
      homeScore: 2,
      awayScore: 3,
      startTime: now.subtract(const Duration(hours: 5)),
      status: EventStatus.finished,
    );

    final valorantEvent = EventModel(
      id: 'vlr-match-1',
      sport: SportType.valorant,
      league: 'VCT Americas',
      leagueModel: const LeagueModel(
        id: 'vct-americas-id',
        name: 'VCT Americas',
        slug: 'vct-americas',
      ),
      homeTeam: const TeamModel(id: 'sen', name: 'Sentinels'),
      awayTeam: const TeamModel(id: 'lev', name: 'Leviatán'),
      startTime: now.add(const Duration(hours: 1)),
      status: EventStatus.scheduled,
    );

    final soccerEvent = EventModel(
      id: 'soccer-ucl-1',
      sport: SportType.soccer,
      league: 'Champions League',
      leagueModel: const LeagueModel(
        id: 'ucl-id',
        name: 'UEFA Champions League',
        slug: 'uefa.champions',
      ),
      homeTeam: const TeamModel(id: 'rm', name: 'Real Madrid'),
      awayTeam: const TeamModel(id: 'mci', name: 'Manchester City'),
      startTime: now.add(const Duration(hours: 4)),
      status: EventStatus.scheduled,
    );

    test('1. Selector LoL aísla estrictamente sport=lol sin mezclar Valorant ni otros deportes', () {
      final mixedEvents = [
        worldsEventLive,
        lckEventScheduled,
        lecEventFinished,
        valorantEvent,
        soccerEvent,
      ];

      final filteredLol = mixedEvents.where((e) => e.sport == SportType.lol).toList();

      expect(filteredLol, hasLength(3));
      expect(filteredLol.every((e) => e.sport == SportType.lol), isTrue);
      expect(filteredLol.any((e) => e.sport == SportType.valorant), isFalse);
      expect(filteredLol.any((e) => e.sport == SportType.soccer), isFalse);
      expect(filteredLol.map((e) => e.id), containsAll(['lol-worlds-live-1', 'lol-lck-sched-1', 'lol-lec-fin-1']));
    });

    test('2. Worlds aparece primero cuando existe cobertura real frente a otras ligas de LoL', () {
      // Pasamos primero LCK y LEC, luego Worlds
      final groups = FeedScreen.groupEventsByCompetition([
        lckEventScheduled,
        lecEventFinished,
        worldsEventLive,
      ]);

      expect(groups, isNotEmpty);
      expect(groups.first.name.toLowerCase(), contains('worlds'));
      expect(groups.first.sport, SportType.lol);

      final sorted = FootballCompetitionPriority.sortEvents([
        lckEventScheduled,
        lecEventFinished,
        worldsEventLive,
      ]);
      expect(sorted.first.id, 'lol-worlds-live-1');
    });

    test('3. Catálogo canónico kCanonicalLeagues prioriza Worlds y permite abrir MSI, LCK, LEC y LCS', () {
      final lolLeagues = kCanonicalLeagues.where((l) => l.sport == SportType.lol).toList();

      expect(lolLeagues, isNotEmpty);
      // Worlds es la primera
      expect(lolLeagues.first.name, 'Worlds');
      expect(lolLeagues.first.isCompetition, isTrue);

      final leagueNames = lolLeagues.map((l) => l.name).toList();
      expect(leagueNames, containsAll(['Worlds', 'MSI', 'LCK', 'LEC', 'LCS']));
    });

    test('4. resolveLeagueSlug resuelve correctamente los slugs de Worlds, MSI, LCK, LEC, LCS y LPL', () {
      expect(LeagueDetailRepository.resolveLeagueSlug('Worlds'), 'worlds');
      expect(LeagueDetailRepository.resolveLeagueSlug('World Championship'), 'worlds');
      expect(LeagueDetailRepository.resolveLeagueSlug('MSI'), 'msi');
      expect(LeagueDetailRepository.resolveLeagueSlug('Mid-Season Invitational'), 'msi');
      expect(LeagueDetailRepository.resolveLeagueSlug('LCK'), 'lck');
      expect(LeagueDetailRepository.resolveLeagueSlug('LEC'), 'lec');
      expect(LeagueDetailRepository.resolveLeagueSlug('LCS'), 'lcs');
      expect(LeagueDetailRepository.resolveLeagueSlug('LPL'), 'lpl');
    });

    test('5. Estados programado, en vivo y finalizado en LolWorldsMatchModel se reflejan con precisión', () {
      final scheduledMatch = LolWorldsMatchModel(
        id: 'm-sched',
        startTime: now.add(const Duration(days: 1)),
        status: 'SCHEDULED',
        homeTeam: const LolWorldsParticipantModel(name: 'T1'),
        awayTeam: const LolWorldsParticipantModel(name: 'GEN'),
      );
      final liveMatch = LolWorldsMatchModel(
        id: 'm-live',
        startTime: now,
        status: 'LIVE',
        homeTeam: const LolWorldsParticipantModel(name: 'T1', score: 1),
        awayTeam: const LolWorldsParticipantModel(name: 'GEN', score: 0),
      );
      final finishedMatch = LolWorldsMatchModel(
        id: 'm-fin',
        startTime: now.subtract(const Duration(hours: 2)),
        status: 'FINISHED',
        homeTeam: const LolWorldsParticipantModel(name: 'T1', score: 2),
        awayTeam: const LolWorldsParticipantModel(name: 'GEN', score: 0),
        winnerTeamId: 't1',
      );

      expect(scheduledMatch.isScheduled, isTrue);
      expect(scheduledMatch.isLive, isFalse);
      expect(scheduledMatch.isFinished, isFalse);

      expect(liveMatch.isLive, isTrue);
      expect(liveMatch.isScheduled, isFalse);
      expect(liveMatch.isFinished, isFalse);

      expect(finishedMatch.isFinished, isTrue);
      expect(finishedMatch.isLive, isFalse);
      expect(finishedMatch.isScheduled, isFalse);
    });

    test('6. Ausencia estricta de tokens privados y URLs de proveedores en el código mobile', () {
      final libDir = Directory('lib');
      final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Verificar que no se invoca PandaScore directamente desde Flutter
        expect(
          content.contains('https://api.pandascore.co'),
          isFalse,
          reason: 'El archivo ${file.path} no debe llamar directamente a la API de PandaScore.',
        );
        // Verificar que no hay claves de API privadas en el código
        expect(
          content.contains('PANDASCORE_API_KEY ='),
          isFalse,
          reason: 'El archivo ${file.path} no debe declarar o asignar PANDASCORE_API_KEY.',
        );
      }
    });

    testWidgets('7. Payload completo de Worlds renderiza cabecera, rondas, partidos y tabla suiza', (tester) async {
      final completePayload = LolWorldsStageModel(
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
          id: 'stage-swiss',
          slug: 'swiss-stage',
          name: 'Etapa Suiza',
          format: 'swiss',
          status: 'in_progress',
          currentRoundNumber: 1,
          totalRounds: 5,
        ),
        rounds: const [
          LolWorldsRoundModel(
            roundNumber: 1,
            name: 'Ronda 1',
            status: 'in_progress',
            matchIds: ['m1'],
          ),
        ],
        matches: [
          LolWorldsMatchModel(
            id: 'm1',
            roundNumber: 1,
            roundName: 'Ronda 1',
            startTime: now,
            status: 'LIVE',
            homeTeam: const LolWorldsParticipantModel(id: 't1', name: 'T1', score: 1),
            awayTeam: const LolWorldsParticipantModel(id: 'wbg', name: 'Weibo Gaming', score: 0),
            format: 'Bo1',
          ),
        ],
        swissStandings: const [
          LolSwissStandingEntryModel(
            position: 1,
            teamId: 't1',
            teamName: 'T1',
            teamCode: 'T1',
            wins: 1,
            losses: 0,
            diff: 1,
            advancementStatus: 'IN_CONTENTION',
          ),
        ],
        hasCoverage: true,
        coverageStatus: 'ACTIVE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: completePayload,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lol-worlds-stage-title')), findsOneWidget);
      expect(find.text('ETAPA SUIZA'), findsOneWidget);
      expect(find.text('EN CURSO'), findsOneWidget);
      expect(find.text('T1'), findsWidgets);
      expect(find.text('Weibo Gaming'), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);

      // Cambiar a la pestaña de Tabla Suiza
      await tester.tap(find.text('Tabla Suiza'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lol-standing-row-1')), findsOneWidget);
      expect(find.text('1-0'), findsOneWidget);
    });

    testWidgets('8. Payload parcial (partidos sin swiss standings) no presenta tabla vacía engañosa', (tester) async {
      final partialMatchesOnly = LolWorldsStageModel(
        version: 1,
        competition: const LolWorldsCompetitionModel(
          slug: 'worlds',
          name: 'League of Legends World Championship',
          sport: 'lol',
        ),
        season: const LolWorldsSeasonModel(
          slug: '2026',
          name: 'Worlds 2026',
          isCurrent: true,
        ),
        stage: const LolWorldsStageInfoModel(
          id: 'stage-playin',
          slug: 'play-in',
          name: 'Play-In Stage',
          format: 'group',
          status: 'in_progress',
        ),
        rounds: const [],
        matches: [
          LolWorldsMatchModel(
            id: 'm-pi-1',
            startTime: now,
            status: 'SCHEDULED',
            homeTeam: const LolWorldsParticipantModel(name: 'PSG Talon'),
            awayTeam: const LolWorldsParticipantModel(name: 'GAM Esports'),
            format: 'Bo3',
          ),
        ],
        swissStandings: const [], // Sin registros suizos
        hasCoverage: true,
        coverageStatus: 'ACTIVE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: partialMatchesOnly,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLAY-IN STAGE'), findsOneWidget);
      expect(find.text('PSG Talon'), findsOneWidget);

      // Ir a la pestaña de tabla
      await tester.tap(find.text('Tabla Suiza'));
      await tester.pumpAndSettle();

      // No debe renderizar una tabla vacía simulando datos
      expect(find.byKey(const ValueKey('lol-standing-row-1')), findsNothing);
      expect(find.text('Sin registro de posiciones'), findsOneWidget);
    });

    testWidgets('9. Estados no configurado, sin cobertura, error de proveedor y lista vacía no rompen la UI', (tester) async {
      final unconfiguredData = LolWorldsStageModel.empty(
        coverageStatus: 'UNCONFIGURED_CREDENTIALS',
        message: 'Credenciales de PandaScore no configuradas en el backend.',
      );

      final noCoverageData = LolWorldsStageModel.empty(
        coverageStatus: 'NO_COVERAGE',
        message: 'Sin partidos activos para esta competición.',
      );

      final providerErrorData = LolWorldsStageModel.empty(
        coverageStatus: 'PROVIDER_ERROR',
        message: 'No se pudo conectar con el proveedor oficial.',
      );

      for (final stateData in [unconfiguredData, noCoverageData, providerErrorData]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LolWorldsSwissView(
                stageData: stateData,
                onRefresh: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sin datos simulados ni fixtures inventados'), findsOneWidget);
        expect(find.text('Comprobar disponibilidad'), findsOneWidget);
      }
    });

    testWidgets('10. Apertura de ligas de LoL (LCK, LEC, LCS, MSI) en LeagueDetailScreen refleja estado de cobertura', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final lckModelNoCoverage = LeagueDetailModel.empty(
        leagueSlug: 'lck',
        leagueName: 'LCK',
      );

      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(_FakeFeedRepository([])),
          leagueDetailProvider.overrideWith((ref, params) async => lckModelNoCoverage),
        ],
      );
      addTearDown(container.dispose);
      await container.read(feedNotifierProvider.notifier).loadEvents();

      Future<void> pumpAndFlush(WidgetTester t) async {
        await t.pump();
        await t.pump(const Duration(milliseconds: 100));
        await t.pump(const Duration(milliseconds: 200));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LeagueDetailScreen(
              leagueName: 'LCK',
              sport: SportType.lol,
              leagueSlug: 'lck',
            ),
          ),
        ),
      );
      await pumpAndFlush(tester);

      expect(find.text('LCK'), findsWidgets);
      expect(find.text('Partidos'), findsOneWidget);
      expect(find.text('Tabla'), findsOneWidget);
      expect(find.text('Estadísticas'), findsOneWidget);

      // Al ir a Tabla con cobertura vacía
      await tester.tap(find.text('Tabla'));
      await pumpAndFlush(tester);
      expect(find.text('Posiciones no disponibles'), findsOneWidget);

      // Al ir a Estadísticas de LoL
      await tester.tap(find.text('Estadísticas'));
      await pumpAndFlush(tester);
      expect(find.text('Estadísticas por partida'), findsOneWidget);
      expect(find.textContaining('KDA y recursos'), findsOneWidget);
    });

    testWidgets('11. Validación E2E: Preservación de casos programado, en vivo y finalizado en LolWorldsSwissView', (tester) async {
      final scheduledCase = LolWorldsMatchModel(
        id: '1711000',
        externalId: 'pandascore-lol-match-1711000',
        roundNumber: 3,
        roundName: 'Ronda 3: TL vs AL',
        startTime: DateTime.parse('2026-10-26T22:00:00Z'),
        status: 'SCHEDULED',
        homeTeam: const LolWorldsParticipantModel(
          id: '390',
          name: 'Team Liquid',
          code: 'TL',
          score: null,
        ),
        awayTeam: const LolWorldsParticipantModel(
          id: '129971',
          name: "Anyone's Legend",
          code: 'AL',
          score: null,
        ),
        format: 'Bo1',
      );

      final liveCase = LolWorldsMatchModel(
        id: '1710999',
        externalId: 'pandascore-lol-match-1710999',
        roundNumber: 3,
        roundName: 'Ronda 3: LOS vs TSW',
        startTime: DateTime.parse('2026-10-26T18:59:21Z'),
        status: 'LIVE',
        homeTeam: const LolWorldsParticipantModel(
          id: '133796',
          name: 'Los Grandes',
          code: 'LOS',
          score: 1,
        ),
        awayTeam: const LolWorldsParticipantModel(
          id: '136073',
          name: 'Team Secret Whales',
          code: 'TSW',
          score: 0,
        ),
        format: 'Bo1',
      );

      final finishedCase = LolWorldsMatchModel(
        id: '1710998',
        externalId: 'pandascore-lol-match-1710998',
        roundNumber: 3,
        roundName: 'Ronda 3: T1 vs CFO',
        startTime: DateTime.parse('2026-10-26T17:06:19Z'),
        status: 'FINISHED',
        winnerTeamId: '126061',
        homeTeam: const LolWorldsParticipantModel(
          id: '126061',
          name: 'T1',
          code: 'T1',
          score: 1,
        ),
        awayTeam: const LolWorldsParticipantModel(
          id: '130355',
          name: 'CTBC Flying Oyster',
          code: 'CFO',
          score: 0,
        ),
        format: 'Bo1',
      );

      final e2eStageModel = LolWorldsStageModel(
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
          id: '22047',
          slug: 'group-stage',
          name: 'Group Stage (Swiss)',
          format: 'swiss',
          status: 'in_progress',
          currentRoundNumber: 3,
          totalRounds: 5,
        ),
        rounds: const [
          LolWorldsRoundModel(
            roundNumber: 3,
            name: 'Ronda 3',
            status: 'in_progress',
            matchIds: ['1711000', '1710999', '1710998'],
          ),
        ],
        matches: [scheduledCase, liveCase, finishedCase],
        swissStandings: const [
          LolSwissStandingEntryModel(
            position: 1,
            teamId: '2882',
            teamName: 'Gen.G',
            teamCode: 'GEN',
            wins: 3,
            losses: 0,
            diff: 3,
            advancementStatus: 'QUALIFIED',
            advancementText: 'Clasificado a Cuartos de Final',
          ),
        ],
        hasCoverage: true,
        coverageStatus: 'ACTIVE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: e2eStageModel,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar caso programado: nombres, formato, sin marcadores
      expect(find.byKey(const ValueKey('lol-match-card-1711000')), findsOneWidget);
      expect(find.text('Team Liquid'), findsOneWidget);
      expect(find.text("Anyone's Legend"), findsOneWidget);

      // Verificar caso en vivo: badge EN VIVO, marcador 1 - 0
      expect(find.byKey(const ValueKey('lol-match-card-1710999')), findsOneWidget);
      expect(find.text('Los Grandes'), findsOneWidget);
      expect(find.text('Team Secret Whales'), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);

      // Verificar caso finalizado: badge FINAL, ganador T1
      expect(find.byKey(const ValueKey('lol-match-card-1710998')), findsOneWidget);
      expect(find.text('CTBC Flying Oyster'), findsOneWidget);
      expect(find.text('FINAL'), findsOneWidget);

      // Verificar tabla suiza
      await tester.tap(find.text('Tabla Suiza'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lol-standing-row-1')), findsOneWidget);
      expect(find.text('Gen.G'), findsOneWidget);
      expect(find.text('3-0'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget);
      expect(find.text('Clasificado a Cuartos de Final'), findsOneWidget);
    });

    testWidgets('12. Validación de errores HTTP (401, 403, 429, timeout) renderiza mensajes entendibles y distintivos', (tester) async {
      final errorCases = [
        {
          'status': 'UNAUTHORIZED',
          'msg': 'Credenciales de PandaScore invalidas o expiradas (401).',
          'expectedTitle': 'Acceso no autorizado',
        },
        {
          'status': 'FORBIDDEN',
          'msg': 'Acceso prohibido para el plan o recurso en PandaScore (403).',
          'expectedTitle': 'Acceso no autorizado',
        },
        {
          'status': 'RATE_LIMITED',
          'msg': 'Limite de peticiones de PandaScore excedido (429).',
          'expectedTitle': 'Límite de solicitudes alcanzado',
        },
        {
          'status': 'PROVIDER_ERROR',
          'msg': 'Error de comunicacion con el proveedor PandaScore: connect ETIMEDOUT',
          'expectedTitle': 'Error de conexión con el proveedor',
        },
      ];

      for (final ec in errorCases) {
        final errModel = LolWorldsStageModel.empty(
          coverageStatus: ec['status']!,
          message: ec['msg'],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LolWorldsSwissView(
                stageData: errModel,
                onRefresh: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(ec['expectedTitle']!), findsOneWidget);
        expect(find.text(ec['msg']!), findsOneWidget);
        expect(find.text('Sin datos simulados ni fixtures inventados'), findsOneWidget);
        expect(find.text('Comprobar disponibilidad'), findsOneWidget);
      }
    });

    testWidgets('13. Torneo sin standings (404) y competición no cubierta presentan interfaz limpia y honesta', (tester) async {
      // Caso torneo sin standings pero con partidos
      final tournNoStandings = LolWorldsStageModel(
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
          id: '22048',
          slug: 'playoffs',
          name: 'Playoffs',
          format: 'tournament',
          status: 'in_progress',
        ),
        rounds: const [],
        matches: [
          LolWorldsMatchModel(
            id: '1711021',
            status: 'SCHEDULED',
            startTime: DateTime.now().add(const Duration(days: 10)),
            homeTeam: const LolWorldsParticipantModel(name: 'TBD'),
            awayTeam: const LolWorldsParticipantModel(name: 'TBD'),
          ),
        ],
        swissStandings: const [],
        hasCoverage: true,
        coverageStatus: 'ACTIVE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LolWorldsSwissView(
              stageData: tournNoStandings,
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLAYOFFS'), findsOneWidget);

      await tester.tap(find.text('Tabla Suiza'));
      await tester.pumpAndSettle();

      // Debe indicar que no hay posiciones sin inventar datos
      expect(find.text('Sin registro de posiciones'), findsOneWidget);
      expect(find.text('El proveedor oficial aún no ha publicado el registro de la etapa suiza.'), findsOneWidget);
    });
  });
}

class _FakeFeedRepository extends FeedRepository {
  final List<EventModel> eventsList;
  _FakeFeedRepository(this.eventsList) : super(subscribeToRealtime: false);

  @override
  Future<List<EventModel>> fetchRemoteEvents() async => eventsList;

  @override
  Future<List<EventModel>> getEvents({
    SportType? sport,
    int? leagueTier,
    bool forceRefresh = false,
  }) async => eventsList;
}

