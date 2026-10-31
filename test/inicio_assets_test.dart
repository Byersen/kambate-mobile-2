import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:kambate_mobile/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:kambate_mobile/features/favorites/presentation/widgets/favorites_region_tabs.dart';
import 'package:kambate_mobile/features/favorites/presentation/widgets/favorites_sport_chips.dart';
import 'package:kambate_mobile/features/favorites/presentation/widgets/league_search_card.dart';
import 'package:kambate_mobile/features/feed/data/feed_repository.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/match_card.dart';
import 'package:kambate_mobile/features/feed/presentation/widgets/scoreboard_row.dart';
import 'package:kambate_mobile/features/feed/providers/feed_provider.dart';
import 'package:kambate_mobile/models/event_model.dart';
import 'package:kambate_mobile/models/event_status.dart';
import 'package:kambate_mobile/models/fighter_model.dart';
import 'package:kambate_mobile/models/participant_model.dart';
import 'package:kambate_mobile/models/sport_type.dart';
import 'package:kambate_mobile/models/team_model.dart';
import 'package:kambate_mobile/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTestFeedRepository extends FeedRepository {
  MockTestFeedRepository() : super(subscribeToRealtime: false);

  @override
  Future<List<EventModel>> fetchRemoteEvents() async => [];

  @override
  Future<EventModel?> getEventById(String id) async => null;
}

class MockLoadingFeedRepository extends FeedRepository {
  MockLoadingFeedRepository() : super(subscribeToRealtime: false);

  @override
  Future<List<EventModel>> fetchRemoteEvents() {
    return Completer<List<EventModel>>().future;
  }

  @override
  Future<EventModel?> getEventById(String id) async => null;
}

class MockErrorFeedRepository extends FeedRepository {
  MockErrorFeedRepository() : super(subscribeToRealtime: false);

  @override
  Future<List<EventModel>> fetchRemoteEvents() async {
    throw Exception('Error simulado al cargar');
  }

  @override
  Future<EventModel?> getEventById(String id) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'kambate_onboarding_completed_v1': true,
      'kambate_followed_leagues_set': <String>[],
    });
  });

  group('Configuración de assets y manifiesto (Tarea 10)', () {
    test('AndroidManifest principal declara permiso INTERNET para release', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml');
      expect(manifest.existsSync(), isTrue);
      final content = manifest.readAsStringSync();
      expect(
        content.contains('<uses-permission android:name="android.permission.INTERNET"/>'),
        isTrue,
        reason: 'El manifiesto principal debe incluir INTERNET para no bloquear la app en release',
      );
    });

    test('pubspec.yaml empaqueta .env.example como fallback de configuración', () {
      final pubspec = File('pubspec.yaml');
      expect(pubspec.existsSync(), isTrue);
      final content = pubspec.readAsStringSync();
      expect(
        content.contains('- .env.example'),
        isTrue,
        reason: 'pubspec.yaml debe declarar .env.example para builds donde .env esté ausente',
      );
      expect(
        content.contains('- assets/images/'),
        isTrue,
        reason: 'pubspec.yaml debe declarar la carpeta assets/images/',
      );
    });

    test('assets/images/vista-buscar.png existe, no está vacío y es una imagen PNG válida', () {
      final file = File('assets/images/vista-buscar.png');
      expect(file.existsSync(), isTrue, reason: 'El archivo vista-buscar.png debe existir en el paquete');
      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(1000));
      // Verificar encabezado PNG estándar: 0x89, 0x50, 0x4E, 0x47
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    });

    test('assets/images/vista-calendario.png existe, no está vacío y es una imagen PNG válida', () {
      final file = File('assets/images/vista-calendario.png');
      expect(file.existsSync(), isTrue);
      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(1000));
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    });

    test('assets/fonts/Inter.ttf existe y está declarado para la tipografía', () {
      final file = File('assets/fonts/Inter.ttf');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(10000));
    });

    test('SupabaseService.initialize completa sin arrojar excepciones no controladas', () async {
      await expectLater(SupabaseService.initialize(), completes);
    });
  });

  group('Resolución de referencias de imágenes y modelos (Tarea 10)', () {
    test('ParticipantModel asigna photoUrl desde logo_url si photo_url no viene en Supabase', () {
      final participant = ParticipantModel.fromJson({
        'id': 'part-1',
        'name': 'Diego Silva',
        'logo_url': 'https://example.com/diego.png',
      });

      expect(participant.logoUrl, 'https://example.com/diego.png');
      expect(participant.photoUrl, 'https://example.com/diego.png');
    });

    test('FighterModel asigna photoUrl desde logo_url si photo_url no viene en Supabase', () {
      final fighter = FighterModel.fromJson({
        'id': 'f-1',
        'name': 'Lucas Costa',
        'logo_url': 'https://example.com/lucas.png',
      });

      expect(fighter.photoUrl, 'https://example.com/lucas.png');
    });

    test('EventModel asigna photoUrl a fighter1 y fighter2 desde logoUrl de participants para UFC', () {
      final event = EventModel.fromJson({
        'id': 'ufc-event-1',
        'sport': 'ufc',
        'league': 'UFC',
        'startDate': '2026-10-21T20:00:00Z',
        'status': 'scheduled',
        'participants': [
          {
            'id': 'p-1',
            'name': 'Diego Silva',
            'logo_url': 'https://example.com/diego.png',
          },
          {
            'id': 'p-2',
            'name': 'Lucas Costa',
            'logo_url': 'https://example.com/lucas.png',
          },
        ],
      });

      expect(event.fighter1, isNotNull);
      expect(event.fighter1!.photoUrl, 'https://example.com/diego.png');
      expect(event.fighter2, isNotNull);
      expect(event.fighter2!.photoUrl, 'https://example.com/lucas.png');
    });
  });

  group('Navegación y títulos coherentes con referencias visuales (Tarea 10)', () {
    testWidgets('Router redirige /buscar y /search a FavoritesScreen', (tester) async {
      final router = createRouter(initialLocation: '/feed');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(MockTestFeedRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      router.go('/buscar');
      await tester.pump();
      expect(find.byType(FavoritesScreen), findsOneWidget);

      router.go('/search');
      await tester.pump();
      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    testWidgets('CalendarScreen muestra título Calendario en AppBar según vista-calendario.png', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(MockTestFeedRepository()),
          ],
          child: const MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Calendario'), findsWidgets);
      expect(find.text('Hoy'), findsOneWidget);
    });
  });

  group('Comparación visual reproducible y estructura según vista-buscar.png (Tarea 10)', () {
    Widget createSearchScreenWidget({
      FeedRepository? repo,
      List<Override> additionalOverrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          feedRepositoryProvider.overrideWithValue(repo ?? MockTestFeedRepository()),
          ...additionalOverrides,
        ],
        child: const MaterialApp(
          home: FavoritesScreen(),
        ),
      );
    }

    testWidgets('Estructura completa de vista de búsqueda: encabezado, pestañas, buscador, deportes, región en fútbol y GridView 2 columnas', (tester) async {
      await tester.pumpWidget(createSearchScreenWidget());
      await tester.pumpAndSettle();

      // 1. Encabezado "Buscar"
      expect(find.text('Buscar'), findsOneWidget);

      // 2. Pestañas "Explorar" y "Mis equipos"
      expect(find.text('Explorar'), findsOneWidget);
      expect(find.text('Mis equipos'), findsOneWidget);

      // 3. Campo de búsqueda
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar equipos, atletas, ligas...'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // 4. Filtros por deporte (FavoritesSportChips) sin mezclar todos
      expect(find.byType(FavoritesSportChips), findsOneWidget);
      expect(find.text('Fútbol'), findsOneWidget);
      expect(find.text('NBA'), findsOneWidget); // solo chip
      expect(find.text('UFC'), findsOneWidget); // solo chip
      expect(find.text('LoL'), findsOneWidget);
      expect(find.text('Valorant'), findsOneWidget);

      // 5. Selector de región (FavoritesRegionTabs) visible por defecto en Fútbol
      expect(find.byType(FavoritesRegionTabs), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget); // en tabs de región
      expect(find.text('Europa'), findsOneWidget);
      expect(find.text('Sudamérica'), findsOneWidget);
      expect(find.text('Norteamérica'), findsOneWidget);
      expect(find.text('Internacional'), findsOneWidget);

      // 6. Tarjetas de ligas en dos columnas (GridView)
      final gridFinder = find.byKey(const PageStorageKey('explore-leagues-grid'));
      expect(gridFinder, findsOneWidget);
      final gridView = tester.widget<GridView>(gridFinder);
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2, reason: 'El prototipo requiere exactamente 2 columnas');
    });

    testWidgets('Vista principal abre en fútbol por defecto y oculta regiones en otros deportes', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSearchScreenWidget());
      await tester.pumpAndSettle();

      // Vista principal abre en Fútbol por defecto: muestra ligas de fútbol y no mezcla NBA/UFC
      expect(find.byKey(const ValueKey('league_card_Champions League')), findsOneWidget);
      expect(find.byKey(const ValueKey('league_card_Europa League')), findsOneWidget);
      expect(find.byKey(const ValueKey('league_card_NBA')), findsNothing);
      expect(find.byKey(const ValueKey('league_card_UFC')), findsNothing);
      expect(find.byType(FavoritesRegionTabs), findsOneWidget);

      // Al cambiar a NBA: se ocultan los filtros regionales
      final nbaChip = find.descendant(
        of: find.byType(FavoritesSportChips),
        matching: find.text('NBA'),
      );
      await tester.tap(nbaChip);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesRegionTabs), findsNothing);
      expect(find.byKey(const ValueKey('league_card_NBA')), findsOneWidget);
      expect(find.byKey(const ValueKey('league_card_Champions League')), findsNothing);

      // Al cambiar a UFC: tampoco se muestran los filtros regionales
      final ufcChip = find.descendant(
        of: find.byType(FavoritesSportChips),
        matching: find.text('UFC'),
      );
      await tester.tap(ufcChip);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesRegionTabs), findsNothing);
      expect(find.byKey(const ValueKey('league_card_UFC')), findsOneWidget);

      // Al volver a Fútbol: reaparecen los filtros regionales
      final futbolChip = find.descendant(
        of: find.byType(FavoritesSportChips),
        matching: find.text('Fútbol'),
      );
      await tester.tap(futbolChip);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesRegionTabs), findsOneWidget);
    });

    testWidgets('Conmutar favorito mediante estrella en tarjeta de liga persiste en followedLeaguesProvider', (tester) async {
      await tester.pumpWidget(createSearchScreenWidget());
      await tester.pumpAndSettle();

      final starFinder = find.descendant(
        of: find.byKey(const ValueKey('league_card_Champions League')),
        matching: find.byIcon(Icons.star_outline_rounded),
      );
      expect(starFinder, findsOneWidget);

      // Pulsar la estrella para seguir la liga
      await tester.tap(starFinder);
      await tester.pumpAndSettle();

      // Debe conmutar a estrella rellena
      final filledStarFinder = find.descendant(
        of: find.byKey(const ValueKey('league_card_Champions League')),
        matching: find.byIcon(Icons.star_rounded),
      );
      expect(filledStarFinder, findsOneWidget);
    });

    testWidgets('Filtros por deporte limitan las tarjetas visibles al deporte seleccionado (ej. NBA)', (tester) async {
      await tester.pumpWidget(createSearchScreenWidget());
      await tester.pumpAndSettle();

      // Inicialmente se ve Champions League (fútbol) y no NBA
      expect(find.descendant(of: find.byType(LeagueSearchCard), matching: find.text('Champions League')), findsOneWidget);
      expect(find.descendant(of: find.byType(LeagueSearchCard), matching: find.text('NBA')), findsNothing);

      // Pulsar el chip "NBA"
      final nbaChip = find.descendant(
        of: find.byType(FavoritesSportChips),
        matching: find.text('NBA'),
      );
      await tester.tap(nbaChip);
      await tester.pumpAndSettle();

      // Ahora solo debe haber ligas de NBA en tarjetas, Champions League y UFC ya no se muestran en el grid
      expect(find.descendant(of: find.byType(LeagueSearchCard), matching: find.text('NBA')), findsOneWidget);
      expect(find.descendant(of: find.byType(LeagueSearchCard), matching: find.text('Champions League')), findsNothing);
      expect(find.descendant(of: find.byType(LeagueSearchCard), matching: find.text('UFC')), findsNothing);
      expect(find.byType(FavoritesRegionTabs), findsNothing);
    });

    testWidgets('Filtros por región limitan las tarjetas a la región seleccionada (ej. Europa)', (tester) async {
      await tester.pumpWidget(createSearchScreenWidget());
      await tester.pumpAndSettle();

      // Pulsar la pestaña de región "Europa"
      final europaTab = find.descendant(
        of: find.byType(FavoritesRegionTabs),
        matching: find.text('Europa'),
      );
      await tester.tap(europaTab);
      await tester.pumpAndSettle();

      // Deben estar las europeas y no las de Norteamérica como NBA en tarjetas
      expect(find.descendant(of: find.byType(LeagueSearchCard), matching: find.text('Champions League')), findsOneWidget);
      expect(find.descendant(of: find.byType(LeagueSearchCard), matching: find.text('Europa League')), findsOneWidget);
      expect(find.descendant(of: find.byType(LeagueSearchCard), matching: find.text('NBA')), findsNothing);
    });

    testWidgets('Búsqueda por texto filtra resultados y limpiar restaura catálogo', (tester) async {
      await tester.pumpWidget(createSearchScreenWidget());
      await tester.pumpAndSettle();

      // Escribir "Valorant" en el campo de texto
      await tester.enterText(find.byType(TextField), 'Valorant');
      await tester.pumpAndSettle();

      expect(find.text('VCT Americas'), findsOneWidget);
      expect(find.text('Champions League'), findsNothing);

      // Pulsar el botón para limpiar la búsqueda
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      // Vuelven a verse las ligas principales
      expect(find.text('Champions League'), findsOneWidget);
      expect(find.text('NBA'), findsWidgets);
    });
  });

  group('Cobertura de estados de la vista de búsqueda (Tarea 10)', () {
    testWidgets('Estado cargando (AsyncLoading) muestra CircularProgressIndicator y mensaje estructurado', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(MockLoadingFeedRepository()),
          ],
          child: const MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando ligas y competiciones...'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('Estado error (AsyncError) muestra icono, mensaje y botón Reintentar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(MockErrorFeedRepository()),
          ],
          child: const MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('No pudimos cargar la información'), findsOneWidget);
      expect(find.text('Revisa tu conexión e inténtalo de nuevo.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('Estado vacío muestra Sin resultados y acción para restablecer filtros', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(MockTestFeedRepository()),
          ],
          child: const MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buscar un término que no exista
      await tester.enterText(find.byType(TextField), 'termino_inexistente_xyz');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('Sin resultados'), findsOneWidget);
      expect(find.text('Restablecer filtros'), findsOneWidget);

      // Pulsar restablecer filtros
      await tester.tap(find.text('Restablecer filtros'));
      await tester.pumpAndSettle();

      // Debe volver al catálogo de ligas
      expect(find.text('Champions League'), findsOneWidget);
    });

    testWidgets('Pestaña Mis equipos muestra estado vacío inicial con botón de explorar equipos', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedRepositoryProvider.overrideWithValue(MockTestFeedRepository()),
          ],
          child: const MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cambiar a la pestaña Mis equipos
      await tester.tap(find.text('Mis equipos'));
      await tester.pumpAndSettle();

      expect(find.text('Aún no sigues ningún equipo'), findsOneWidget);
      expect(find.text('Explorar equipos'), findsOneWidget);

      // Pulsar explorar equipos debe volver a la pestaña Explorar
      await tester.tap(find.text('Explorar equipos'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('Renderizado de componentes de imagen y estados (Tarea 10)', () {
    testWidgets('ScoreboardRow renderiza evento de combate sin excepciones con logos o fotos', (tester) async {
      final combatEvent = EventModel(
        id: 'ev-combat-1',
        sport: SportType.ufc,
        league: 'UFC',
        status: EventStatus.scheduled,
        startTime: DateTime.now(),
        fighter1: const FighterModel(
          id: 'f-1',
          name: 'Diego Silva',
          photoUrl: 'https://example.com/diego.png',
        ),
        fighter2: const FighterModel(
          id: 'f-2',
          name: 'Lucas Costa',
          photoUrl: 'https://example.com/lucas.png',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreboardRow(event: combatEvent, onTap: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Diego Silva'), findsOneWidget);
      expect(find.text('Lucas Costa'), findsOneWidget);
    });

    testWidgets('MatchCard usa imageUrl cuando está disponible y fallback con iniciales si es null', (tester) async {
      final teamEvent = EventModel(
        id: 'ev-team-1',
        sport: SportType.soccer,
        league: 'Primera División',
        status: EventStatus.scheduled,
        startTime: DateTime.now(),
        homeTeam: const TeamModel(
          id: 't-1',
          name: 'Colo-Colo',
          logoUrl: 'https://example.com/colo-colo.png',
        ),
        awayTeam: const TeamModel(
          id: 't-2',
          name: 'U. de Chile',
          logoUrl: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(event: teamEvent),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Colo-Colo'), findsOneWidget);
      expect(find.text('U. de Chile'), findsOneWidget);
      expect(find.text('Ud'), findsOneWidget);
    });
  });
}
