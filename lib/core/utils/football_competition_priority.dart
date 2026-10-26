import '../../models/event_model.dart';
import '../../models/league_model.dart';
import '../../models/sport_type.dart';

/// Utilidad para clasificar y priorizar ligas de fútbol según la jerarquía establecida
/// para la pantalla de Partidos de Kambate.
///
/// Orden requerido:
/// 1. UEFA Champions League
/// 2. UEFA Europa League
/// 3. Premier League
/// 4. LaLiga
/// 5. Serie A (Italia)
/// 6. Bundesliga
/// 7. Liga Francesa (Ligue 1)
/// 8. Liga Chilena (Primera División)
/// 9. Liga Argentina (Liga Profesional)
/// 10. Liga Brasileña (Brasileirão / Série A Brasil)
/// 11. y después las demás
class FootballCompetitionPriority {
  const FootballCompetitionPriority._();

  static int getLeaguePriority(String leagueName, [LeagueModel? model]) {
    final l = leagueName.toLowerCase().trim();
    final slug = model?.slug.toLowerCase().trim() ?? '';
    final country = model?.country?.toLowerCase().trim() ?? '';

    // 1. UEFA Champions League
    if (slug == 'ucl' ||
        slug == 'uefa.champions' ||
        l.contains('champions league') ||
        (l.contains('champions') && !l.contains('championship'))) {
      return 0;
    }

    // 2. UEFA Europa League
    if (slug == 'uel' ||
        slug == 'uefa.europa' ||
        l.contains('europa league') ||
        (l.contains('europa') &&
            !l.contains('eurocopa') &&
            !l.contains('supercopa') &&
            !l.contains('conference'))) {
      return 1;
    }

    // 3. Premier League
    if (slug == 'eng.1' ||
        slug == 'premier-league' ||
        l.contains('premier league') ||
        l == 'premier' ||
        l == 'epl') {
      return 2;
    }

    // 4. LaLiga
    if (slug == 'esp.1' ||
        slug == 'laliga' ||
        l.contains('laliga') ||
        l.contains('la liga') ||
        l.contains('primera división de españa') ||
        l.contains('primera division de espana')) {
      return 3;
    }

    // Detectar liga brasileña para distinguirla de la Serie A italiana
    final isBrazilian = slug == 'bra.1' ||
        slug == 'brasileirao' ||
        l.contains('brasileir') ||
        l.contains('brasileirão') ||
        l.contains('brasileirao') ||
        l.contains('campeonato brasileiro') ||
        (country == 'brasil' || country == 'brazil') ||
        l.contains('liga brasileña') ||
        l.contains('liga brasilera');

    // 5. Serie A (Italia)
    if (!isBrazilian &&
        (slug == 'ita.1' ||
            slug == 'serie-a' ||
            l.contains('serie a') ||
            l.contains('serie-a') ||
            country == 'italia' ||
            country == 'italy')) {
      return 4;
    }

    // 6. Bundesliga
    if (slug == 'ger.1' || slug == 'bundesliga' || l.contains('bundesliga')) {
      return 5;
    }

    // 7. Liga Francesa (Ligue 1)
    if (slug == 'fra.1' ||
        slug == 'ligue-1' ||
        slug == 'ligue1' ||
        l.contains('ligue 1') ||
        l.contains('ligue1') ||
        l.contains('liga francesa') ||
        l.contains('french') ||
        (country == 'francia' || country == 'france')) {
      return 6;
    }

    // 8. Liga Chilena
    if (slug == 'chi.1' ||
        slug == 'primera-chile' ||
        l.contains('chile') ||
        l.contains('chilena') ||
        l.contains('campeonato itaú') ||
        l.contains('campeonato itau') ||
        l.contains('campeonato nacional') ||
        l == 'primera división' ||
        l == 'primera division' ||
        country == 'chile') {
      return 7;
    }

    // 9. Liga Argentina
    if (slug == 'arg.1' ||
        slug == 'liga-argentina' ||
        l.contains('argentin') ||
        l.contains('liga profesional') ||
        country == 'argentina') {
      return 8;
    }

    // 10. Liga Brasileña
    if (isBrazilian) {
      return 9;
    }

    // 11. Las demás
    return 10;
  }

  /// Identificador canónico para agrupar partidos de la misma competición.
  static String getCompetitionKey(EventModel event) {
    if (event.leagueModel != null && event.leagueModel!.slug.isNotEmpty) {
      return event.leagueModel!.slug.toLowerCase().trim();
    }
    return event.league.toLowerCase().trim();
  }

  /// Aplica la prioridad al orden de competiciones y conserva un orden estable por hora
  /// dentro de cada grupo.
  static List<EventModel> sortEvents(
    List<EventModel> events, {
    bool Function(EventModel)? isFollowed,
  }) {
    if (events.isEmpty) return events;

    final followedList = <EventModel>[];
    final regularList = <EventModel>[];

    for (final event in events) {
      if (isFollowed != null && isFollowed(event)) {
        followedList.add(event);
      } else {
        regularList.add(event);
      }
    }

    return [
      ..._sortEventSubset(followedList),
      ..._sortEventSubset(regularList),
    ];
  }

  static List<EventModel> _sortEventSubset(List<EventModel> subset) {
    if (subset.isEmpty) return subset;

    final soccerEvents = <EventModel>[];
    final otherEvents = <EventModel>[];

    for (final event in subset) {
      if (event.sport == SportType.soccer) {
        soccerEvents.add(event);
      } else {
        otherEvents.add(event);
      }
    }

    final competitionGroups = <String, List<EventModel>>{};
    for (final event in soccerEvents) {
      final key = getCompetitionKey(event);
      competitionGroups.putIfAbsent(key, () => <EventModel>[]).add(event);
    }

    for (final matches in competitionGroups.values) {
      matches.sort((a, b) {
        final timeComp = a.startTime.compareTo(b.startTime);
        if (timeComp != 0) return timeComp;
        return a.id.compareTo(b.id);
      });
    }

    final sortedGroupKeys = competitionGroups.keys.toList()
      ..sort((keyA, keyB) {
        final sampleA = competitionGroups[keyA]!.first;
        final sampleB = competitionGroups[keyB]!.first;

        final prioA = getLeaguePriority(sampleA.league, sampleA.leagueModel);
        final prioB = getLeaguePriority(sampleB.league, sampleB.leagueModel);

        if (prioA != prioB) {
          return prioA.compareTo(prioB);
        }

        final firstTimeA = sampleA.startTime;
        final firstTimeB = sampleB.startTime;
        final timeComp = firstTimeA.compareTo(firstTimeB);
        if (timeComp != 0) return timeComp;

        return sampleA.league.toLowerCase().compareTo(sampleB.league.toLowerCase());
      });

    final sortedSoccer = <EventModel>[];
    for (final key in sortedGroupKeys) {
      sortedSoccer.addAll(competitionGroups[key]!);
    }

    otherEvents.sort((a, b) {
      if (a.sport == SportType.lol && b.sport == SportType.lol) {
        final aIsWorlds = a.league.toLowerCase().contains('worlds') ||
            (a.leagueModel?.slug.toLowerCase().contains('worlds') ?? false);
        final bIsWorlds = b.league.toLowerCase().contains('worlds') ||
            (b.leagueModel?.slug.toLowerCase().contains('worlds') ?? false);
        if (aIsWorlds && !bIsWorlds) return -1;
        if (!aIsWorlds && bIsWorlds) return 1;

        int statusOrder(EventModel e) {
          if (e.status == EventStatus.finished) return 0;
          if (e.status == EventStatus.live) return 1;
          return 2;
        }
        final orderA = statusOrder(a);
        final orderB = statusOrder(b);
        if (orderA != orderB) return orderA.compareTo(orderB);
      }
      final timeComp = a.startTime.compareTo(b.startTime);
      if (timeComp != 0) return timeComp;
      return a.id.compareTo(b.id);
    });

    return [...sortedSoccer, ...otherEvents];
  }
}
