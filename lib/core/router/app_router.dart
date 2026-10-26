import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/feed/data/feed_repository.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/match_detail/presentation/screens/match_detail_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../models/event_model.dart';
import '../../models/sport_type.dart';
import '../../features/league_detail/presentation/screens/league_detail_screen.dart';
import '../../features/match_detail/presentation/screens/ufc_fight_detail_screen.dart';
import '../../models/ufc_card_model.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String initialLocation = '/feed'}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/following',
                builder: (context, state) => const FavoritesScreen(),
              ),
              GoRoute(
                path: '/favorites',
                redirect: (context, state) => '/following',
              ),
              GoRoute(
                path: '/buscar',
                redirect: (context, state) => '/following',
              ),
              GoRoute(
                path: '/search',
                redirect: (context, state) => '/following',
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/detail/:id',
        builder: (context, state) {
          final extraEvent = state.extra;
          if (extraEvent is EventModel) {
            return MatchDetailScreen(event: extraEvent);
          }

          final eventId = state.pathParameters['id'] ?? '';
          return FutureBuilder<EventModel?>(
            future: FeedRepository().getEventById(eventId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Scaffold(
                  appBar: AppBar(),
                  body: const Center(child: Text('Evento no encontrado')),
                );
              }
              return MatchDetailScreen(event: snapshot.data!);
            },
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/detail/:id/fight/:fightId',
        builder: (context, state) {
          final eventId = state.pathParameters['id'] ?? '';
          final fightId = state.pathParameters['fightId'] ?? '';
          final extraEvent = state.extra;

          if (extraEvent is EventModel) {
            final card = extraEvent.ufcCard ?? UfcCardModel.fromEvent(extraEvent);
            final fight = card.fightById(fightId) ?? card.fights.firstOrNull;
            if (fight != null) {
              return UfcFightDetailScreen(card: card, fight: fight, event: extraEvent);
            }
          }

          return FutureBuilder<EventModel?>(
            future: FeedRepository().getEventById(eventId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final event = snapshot.data;
              if (event == null) {
                return Scaffold(
                  appBar: AppBar(),
                  body: const Center(child: Text('Evento no encontrado')),
                );
              }
              final card = event.ufcCard ?? UfcCardModel.fromEvent(event);
              final fight = card.fightById(fightId) ?? card.fights.firstOrNull;
              if (fight == null) {
                return Scaffold(
                  appBar: AppBar(),
                  body: const Center(child: Text('Combate no encontrado')),
                );
              }
              return UfcFightDetailScreen(card: card, fight: fight, event: event);
            },
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/league/:name',
        builder: (context, state) {
          final leagueName = state.pathParameters['name'] ?? '';
          final extraSport = state.extra as SportType?;
          final leagueId = state.uri.queryParameters['leagueId'];
          final seasonId = state.uri.queryParameters['seasonId'];
          final slug = state.uri.queryParameters['slug'];
          final decodedName = Uri.decodeComponent(leagueName);
          final lowerName = decodedName.toLowerCase();
          final lowerSlug = slug?.toLowerCase() ?? '';
          final resolvedSport = extraSport ??
              (lowerName.contains('worlds') ||
                      lowerSlug.contains('worlds') ||
                      lowerName.contains('lck') ||
                      lowerName.contains('lec') ||
                      lowerName.contains('lcs')
                  ? SportType.lol
                  : lowerName.contains('nba') || lowerSlug.contains('nba')
                      ? SportType.nba
                      : lowerName.contains('ufc') || lowerSlug.contains('ufc')
                          ? SportType.ufc
                          : (lowerName.contains('vct') ||
                                  lowerName.contains('valorant') ||
                                  lowerSlug.contains('valorant') ||
                                  lowerSlug.contains('vct') ||
                                  lowerName == 'valorant champions' ||
                                  lowerName == 'valorant masters' ||
                                  lowerSlug == 'valorant-champions' ||
                                  lowerSlug == 'valorant-masters')
                              ? SportType.valorant
                              : SportType.soccer);
          return LeagueDetailScreen(
            leagueName: decodedName,
            sport: resolvedSport,
            leagueId: leagueId,
            seasonId: seasonId,
            leagueSlug: slug,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/ufc',
        builder: (context, state) => const LeagueDetailScreen(
          leagueName: 'UFC',
          sport: SportType.ufc,
          leagueSlug: 'ufc',
        ),
      ),
    ],
  );
}

final GoRouter appRouter = createRouter();
