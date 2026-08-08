import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/feed/data/feed_repository.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/match_detail/presentation/screens/match_detail_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../models/event_model.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String initialLocation = '/feed'}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      // Onboarding Screen Route (Outside MainShell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main App Shell (3 Tabs: Partidos, Siguiendo, Calendario)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Partidos (Feed)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          // Tab 2: Siguiendo (Equipos & Favoritos)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/following',
                builder: (context, state) => const FavoritesScreen(),
              ),
              // Legacy alias for compatibility
              GoRoute(
                path: '/favorites',
                redirect: (context, state) => '/following',
              ),
            ],
          ),
          // Tab 3: Calendario (Agenda Mensual)
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

      // Match Detail Route
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
    ],
  );
}

final GoRouter appRouter = createRouter();
