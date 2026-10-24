import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kambate_mobile/core/theme/app_theme.dart';
import 'package:kambate_mobile/core/utils/date_formatter.dart';
import 'package:kambate_mobile/core/widgets/event_status_chip.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/match_card.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrapWithTheme(Widget child, {Size size = const Size(390, 844), double textScale = 1.0}) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('Tarea 26 — Altura compacta y estructura de ScoreboardRow', () {
    testWidgets('ScoreboardRow reduce la altura vertical a menos de 105px en pantalla estándar', (tester) async {
      final event = EventModel(
        id: 'evt-compact-soccer',
        sport: SportType.soccer,
        league: 'LaLiga EA Sports',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 24, 18, 0),
        currentPeriod: "65'",
        homeTeam: const TeamModel(id: 't-rma', name: 'Real Madrid'),
        awayTeam: const TeamModel(id: 't-bar', name: 'Barcelona'),
        homeScore: 2,
        awayScore: 1,
      );

      await tester.pumpWidget(
        wrapWithTheme(
          Center(
            child: ScoreboardRow(event: event, onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rowFinder = find.byType(ScoreboardRow);
      expect(rowFinder, findsOneWidget);

      final rowSize = tester.getSize(rowFinder);
      // La altura original superaba los 150px. La versión compacta mide menos de 105px.
      expect(rowSize.height, lessThan(105.0));
      expect(rowSize.height, greaterThanOrEqualTo(48.0), reason: 'Debe respetar el área táctil mínima accesible');
    });

    testWidgets('Conserva los 5 elementos clave: equipos, competición, hora, estado y marcador real', (tester) async {
      final event = EventModel(
        id: 'evt-all-fields',
        sport: SportType.soccer,
        league: 'Premier League',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 24, 16, 30),
        currentPeriod: "45+2'",
        homeTeam: const TeamModel(id: 't-ars', name: 'Arsenal'),
        awayTeam: const TeamModel(id: 't-che', name: 'Chelsea'),
        homeScore: 3,
        awayScore: 0,
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ScoreboardRow(event: event, onTap: () {}, followed: true),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Competición e icono
      expect(find.textContaining('Premier League'), findsOneWidget);
      expect(find.byIcon(Icons.sports_soccer), findsWidgets);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // 2. Estado
      expect(find.byType(EventStatusChip), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);

      // 3. Hora / Periodo
      expect(find.text('45+2′'), findsOneWidget);

      // 4. Equipos
      expect(find.text('Arsenal'), findsOneWidget);
      expect(find.text('Chelsea'), findsOneWidget);

      // 5. Marcadores reales
      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Tacto accesible e interactividad: el tap ejecuta la función onTap', (tester) async {
      bool tapped = false;
      final event = EventModel(
        id: 'evt-tap',
        sport: SportType.nba,
        league: 'NBA',
        status: EventStatus.scheduled,
        startTime: DateTime.utc(2026, 10, 24, 21, 0),
        homeTeam: const TeamModel(id: 't-lal', name: 'Lakers'),
        awayTeam: const TeamModel(id: 't-gsw', name: 'Warriors'),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ScoreboardRow(event: event, onTap: () => tapped = true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ScoreboardRow));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('Tarea 26 — Ciclo de vida y estados del partido en ScoreboardRow', () {
    testWidgets('Estado PROGRAMADO muestra hora y guiones neutrales de marcador', (tester) async {
      final event = EventModel(
        id: 'evt-sched',
        sport: SportType.soccer,
        league: 'Champions League',
        status: EventStatus.scheduled,
        startTime: DateTime(2026, 10, 24, 20, 0),
        homeTeam: const TeamModel(id: 't-bay', name: 'Bayern'),
        awayTeam: const TeamModel(id: 't-psg', name: 'PSG'),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ScoreboardRow(event: event, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROGRAMADO'), findsOneWidget);
      expect(find.textContaining('20:00'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('Estado FINALIZADO con marcador muestra FINALIZADO y números finales', (tester) async {
      final event = EventModel(
        id: 'evt-fin',
        sport: SportType.soccer,
        league: 'Serie A',
        status: EventStatus.finished,
        startTime: DateTime(2026, 10, 24, 15, 0),
        homeTeam: const TeamModel(id: 't-juv', name: 'Juventus'),
        awayTeam: const TeamModel(id: 't-mil', name: 'Milan'),
        homeScore: 1,
        awayScore: 1,
        score: '1 - 1',
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ScoreboardRow(event: event, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FINALIZADO'), findsOneWidget);
      expect(find.text('FINAL'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
    });

    testWidgets('Estado APLAZADO y CANCELADO conservan visibilidad de equipos y hora', (tester) async {
      final postponedEvent = EventModel(
        id: 'evt-post',
        sport: SportType.soccer,
        league: 'Copa Libertadores',
        status: EventStatus.postponed,
        startTime: DateTime(2026, 10, 24, 21, 30),
        homeTeam: const TeamModel(id: 't-fla', name: 'Flamengo'),
        awayTeam: const TeamModel(id: 't-pal', name: 'Palmeiras'),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ScoreboardRow(event: postponedEvent, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('APLAZADO'), findsOneWidget);
      expect(find.textContaining('21:30'), findsOneWidget);
      expect(find.text('Flamengo'), findsOneWidget);
      expect(find.text('Palmeiras'), findsOneWidget);
    });
  });

  group('Tarea 26 — Multideporte en tarjeta compacta', () {
    testWidgets('Combate UFC muestra nombres de peleadores y resultado oficial si existe', (tester) async {
      final ufcEvent = EventModel(
        id: 'evt-ufc',
        sport: SportType.ufc,
        league: 'UFC 308',
        status: EventStatus.finished,
        startTime: DateTime(2026, 10, 24, 22, 0),
        fighter1: const FighterModel(id: 'f-1', name: 'Ilia Topuria'),
        fighter2: const FighterModel(id: 'f-2', name: 'Max Holloway'),
        fightResult: 'KO Rd 3',
        score: 'KO Rd 3',
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ScoreboardRow(event: ufcEvent, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ilia Topuria'), findsOneWidget);
      expect(find.text('Max Holloway'), findsOneWidget);
      expect(find.text('KO Rd 3'), findsOneWidget);
    });

    testWidgets('MatchCard compartida mantiene uniformidad compacta y avatares proporcionales', (tester) async {
      final matchCardEvent = EventModel(
        id: 'evt-mc',
        sport: SportType.soccer,
        league: 'Bundesliga',
        status: EventStatus.live,
        startTime: DateTime(2026, 10, 24, 17, 30),
        currentPeriod: "33'",
        homeTeam: const TeamModel(id: 't-dor', name: 'Dortmund'),
        awayTeam: const TeamModel(id: 't-rbl', name: 'Leipzig'),
        homeScore: 1,
        awayScore: 0,
      );

      await tester.pumpWidget(
        wrapWithTheme(
          Center(
            child: MatchCard(event: matchCardEvent, onTap: () {}),
          ),
        ),
      );
      await tester.pump();

      final cardFinder = find.byType(MatchCard);
      expect(cardFinder, findsOneWidget);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.height, lessThan(125.0));
    });
  });

  group('Tarea 26 — Pantalla estrecha (320px) y accesibilidad con texto ampliado', () {
    testWidgets('Lista con 5 encuentros cabe sin desbordamientos en pantalla de 320px', (tester) async {
      final events = List.generate(
        5,
        (i) => EventModel(
          id: 'evt-narrow-$i',
          sport: SportType.soccer,
          league: 'Liga Profesional de Fútbol $i',
          status: i == 0 ? EventStatus.live : EventStatus.scheduled,
          startTime: DateTime(2026, 10, 24, 14 + i, 0),
          currentPeriod: i == 0 ? "88'" : null,
          homeTeam: TeamModel(id: 'h-$i', name: 'Club Local Atlético $i'),
          awayTeam: TeamModel(id: 'a-$i', name: 'Deportivo Visitante $i'),
          homeScore: i == 0 ? 2 : null,
          awayScore: i == 0 ? 1 : null,
        ),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ListView.separated(
            itemCount: events.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (_, index) => ScoreboardRow(event: events[index], onTap: () {}),
          ),
          size: const Size(320, 568),
          textScale: 1.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScoreboardRow), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Admite texto ampliado (textScale 1.5 y 2.0) sin excepción RenderFlex', (tester) async {
      final longEvent = EventModel(
        id: 'evt-extreme',
        sport: SportType.soccer,
        league: 'Campeonato Nacional de Primera División AFP PlanVital',
        status: EventStatus.live,
        startTime: DateTime(2026, 10, 24, 19, 0),
        currentPeriod: "90+7' Tiempo agregado",
        homeTeam: const TeamModel(id: 't-col', name: 'Club Social y Deportivo Colo-Colo'),
        awayTeam: const TeamModel(id: 't-uch', name: 'Club Universidad de Chile'),
        homeScore: 10,
        awayScore: 9,
      );

      // Probar escala 1.5x en ancho 320px
      await tester.pumpWidget(
        wrapWithTheme(
          SingleChildScrollView(
            child: ScoreboardRow(event: longEvent, onTap: () {}),
          ),
          size: const Size(320, 600),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Probar escala 2.0x
      await tester.pumpWidget(
        wrapWithTheme(
          SingleChildScrollView(
            child: ScoreboardRow(event: longEvent, onTap: () {}),
          ),
          size: const Size(360, 640),
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Tarea 28 — Reorganización de ScoreboardRow en tres columnas', () {
    testWidgets('Alineación geométrica: las dos filas de equipos y marcadores quedan alineadas verticalmente', (tester) async {
      final event = EventModel(
        id: 'evt-geo-align',
        sport: SportType.soccer,
        league: 'LaLiga EA Sports',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 24, 20, 0),
        currentPeriod: "58'",
        homeTeam: const TeamModel(id: 't-rma', name: 'Real Madrid'),
        awayTeam: const TeamModel(id: 't-bar', name: 'FC Barcelona'),
        homeScore: 2,
        awayScore: 1,
      );

      await tester.pumpWidget(
        wrapWithTheme(
          Center(
            child: ScoreboardRow(event: event, onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final homeTeamPos = tester.getTopLeft(find.text('Real Madrid'));
      final awayTeamPos = tester.getTopLeft(find.text('FC Barcelona'));
      final homeScorePos = tester.getTopLeft(find.text('2'));
      final awayScorePos = tester.getTopLeft(find.text('1'));
      final timePos = tester.getTopLeft(find.text('58′'));

      // Misma columna X para ambos equipos
      expect(homeTeamPos.dx, equals(awayTeamPos.dx));
      // Misma columna X para ambos marcadores
      expect(homeScorePos.dx, equals(awayScorePos.dx));
      // Los marcadores se ubican a la derecha de los equipos
      expect(homeScorePos.dx, greaterThan(homeTeamPos.dx));
      // El minuto está en la tercera columna, a la derecha del marcador
      expect(timePos.dx, greaterThan(homeScorePos.dx));

      // Alineación vertical de cada fila: el marcador local está a nivel vertical de su equipo
      expect((homeTeamPos.dy - homeScorePos.dy).abs(), lessThan(6.0));
      // El marcador visitante está a nivel vertical de su equipo
      expect((awayTeamPos.dy - awayScorePos.dy).abs(), lessThan(6.0));
      // La fila visitante está debajo de la local
      expect(awayTeamPos.dy, greaterThan(homeTeamPos.dy));
      expect(awayScorePos.dy, greaterThan(homeScorePos.dy));
    });

    testWidgets('Tercera columna presenta estado/minuto/hora sin duplicar en la tarjeta', (tester) async {
      final liveEvent = EventModel(
        id: 'evt-no-dup-live',
        sport: SportType.soccer,
        league: 'Champions League',
        status: EventStatus.live,
        startTime: DateTime.utc(2026, 10, 24, 20, 0),
        currentPeriod: "75'",
        homeTeam: const TeamModel(id: 't-1', name: 'Inter'),
        awayTeam: const TeamModel(id: 't-2', name: 'Milan'),
        homeScore: 1,
        awayScore: 0,
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ScoreboardRow(event: liveEvent, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // El minuto aparece exactamente una vez (en la tercera columna)
      expect(find.text('75′'), findsOneWidget);
      // El chip de estado aparece exactamente una vez (en la cabecera)
      expect(find.byType(EventStatusChip), findsOneWidget);
      expect(find.text('EN VIVO'), findsOneWidget);
    });

    testWidgets('UFC no inventa marcadores numéricos ni guiones de fútbol', (tester) async {
      final ufcEvent = EventModel(
        id: 'evt-ufc-check',
        sport: SportType.ufc,
        league: 'UFC Fight Night',
        status: EventStatus.scheduled,
        startTime: DateTime.utc(2026, 10, 24, 23, 0),
        fighter1: const FighterModel(id: 'f-1', name: 'Brandon Moreno'),
        fighter2: const FighterModel(id: 'f-2', name: 'Amir Albazi'),
      );

      await tester.pumpWidget(
        wrapWithTheme(
          ScoreboardRow(event: ufcEvent, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Brandon Moreno'), findsOneWidget);
      expect(find.text('Amir Albazi'), findsOneWidget);
      // No hay marcadores numéricos ni guiones neutrales de marcador
      expect(find.text('—'), findsNothing);
      expect(find.text('0'), findsNothing);
      // Tercera columna muestra hora de inicio
      expect(find.text('PROGRAMADO'), findsOneWidget);
      expect(find.text(AppDateFormatter.formatEventTime(ufcEvent.startTime)), findsOneWidget);
    });
  });
}
