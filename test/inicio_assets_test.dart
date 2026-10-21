import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kambate_mobile/core/router/app_router.dart';
import 'package:kambate_mobile/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:kambate_mobile/features/favorites/presentation/screens/favorites_screen.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'kambate_onboarding_completed_v1': true,
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

    testWidgets('FavoritesScreen muestra título Buscar en AppBar según vista-buscar.png', (tester) async {
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
      await tester.pump();

      expect(find.text('Buscar'), findsWidgets);
      expect(find.text('Explorar'), findsOneWidget);
      expect(find.text('Mis equipos'), findsOneWidget);
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
