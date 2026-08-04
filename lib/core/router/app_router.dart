import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/feed/data/feed_repository.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/match_detail/presentation/screens/match_detail_screen.dart';
import '../../models/event_model.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/feed',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Feed
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/feed',
              builder: (context, state) => const FeedScreen(),
            ),
          ],
        ),
        // Tab 2: Favorites
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
        // Tab 3: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
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
