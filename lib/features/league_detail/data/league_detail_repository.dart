import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../models/league_detail_model.dart';
import '../../../services/supabase_service.dart';

class LeagueDetailRepository {
  final Dio _dio;

  LeagueDetailRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  static String resolveLeagueSlug(String leagueName) {
    final l = leagueName.toLowerCase().trim();

    // League of Legends
    if (l.contains('worlds') || l.contains('world championship')) return 'worlds';
    if (l.contains('msi') || l.contains('mid-season invitational')) return 'msi';
    if (l.contains('lck')) return 'lck';
    if (l.contains('lec')) return 'lec';
    if (l.contains('lcs')) return 'lcs';
    if (l.contains('lpl')) return 'lpl';
    if (l.contains('lol') || l.contains('legends')) return 'lol';

    // Valorant
    if (l.contains('valorant champions') || (l.contains('champions') && (l.contains('val') || l.contains('vct')))) {
      return 'valorant-champions';
    }
    if (l.contains('valorant masters') || (l.contains('masters') && (l.contains('val') || l.contains('vct')))) {
      return 'valorant-masters';
    }
    if (l.contains('ascension') && (l.contains('americas') || l.contains('val') || l.contains('vct'))) {
      return 'vct-ascension-americas';
    }
    if (l.contains('vct americas') || (l.contains('americas') && (l.contains('val') || l.contains('vct')))) {
      return 'vct-americas';
    }
    if (l.contains('vct emea') || (l.contains('emea') && (l.contains('val') || l.contains('vct')))) {
      return 'vct-emea';
    }
    if (l.contains('valorant') || l.contains('vct')) return 'valorant';

    if (l.contains('mex') || l.contains('mx')) return 'mex.1';
    if (l.contains('usa') || l.contains('mls') || l.contains('major league')) {
      return 'usa.1';
    }

    if (l.contains('copa libertadores') || l.contains('libertadores')) {
      return 'conmebol.libertadores';
    }
    if (l.contains('sudamericana')) return 'conmebol.sudamericana';

    if (l.contains('champions')) return 'uefa.champions';
    if (l.contains('europa league') || (l.contains('europa') && !l.contains('eurocopa'))) {
      return 'uefa.europa';
    }
    if (l.contains('conference')) return 'uefa.europa.conf';
    if (l.contains('supercopa de europa') || l.contains('super cup')) {
      return 'uefa.super_cup';
    }

    if (l.contains('copa argentina') || l == 'arg.copa') return 'arg.copa';
    if (l.contains('arg') || l.contains('argentin') || l.contains('liga prof')) {
      return 'arg.1';
    }
    if (l.contains('copa do brasil') || l.contains('copa_do_brazil')) {
      return 'bra.copa_do_brazil';
    }
    if (l.contains('bra') || l.contains('brasileir')) return 'bra.1';
    if (l.contains('copa chile') || l.contains('copa_chi')) {
      return 'chi.copa_chi';
    }
    if (l.contains('chi') || l.contains('chile') || l.contains('campeonato itaú')) {
      return 'chi.1';
    }

    if (l.contains('copa del rey') || l.contains('copa_del_rey')) {
      return 'esp.copa_del_rey';
    }
    if (l.contains('esp') || l.contains('spanish') || l.contains('laliga')) {
      return 'esp.1';
    }
    if (l.contains('carabao') || l.contains('league_cup') || l.contains('league cup') || l.contains('efl cup')) {
      return 'eng.league_cup';
    }
    if (l.contains('community shield') || l.contains('charity')) {
      return 'eng.charity';
    }
    if (l.contains('fa cup') || l == 'eng.fa') {
      return 'eng.fa';
    }
    if (l.contains('eng') || l.contains('english') || l.contains('premier')) {
      return 'eng.1';
    }
    if (l.contains('ita') || l.contains('italian') || l.contains('serie a')) {
      return 'ita.1';
    }
    if (l.contains('ger') || l.contains('german') || l.contains('bundesliga')) {
      return 'ger.1';
    }
    if (l.contains('fra') || l.contains('french') || l.contains('ligue 1')) {
      return 'fra.1';
    }
    if (l.contains('ned') || l.contains('dutch') || l.contains('eredivisie')) {
      return 'ned.1';
    }
    if (l.contains('por') || l.contains('portuguese') || l.contains('primeira')) {
      return 'por.1';
    }
    if (l.contains('tur') || l.contains('turkish') || l.contains('super') || l.contains('süper')) {
      return 'tur.1';
    }

    if (l.contains('nba') || l.contains('baloncesto') || l.contains('basketball')) {
      return 'nba';
    }
    if (l.contains('ufc') || l.contains('mma')) return 'ufc';

    return leagueName.toLowerCase().replaceAll(' ', '-');
  }

  Future<LeagueDetailModel> getLeagueDetail({
    required String leagueName,
    String? leagueSlug,
    String? leagueId,
    String? seasonId,
  }) async {
    final slug = leagueSlug ?? resolveLeagueSlug(leagueName);

    // 1. Intentar backend oficial si está configurado y disponible
    try {
      final apiUrl = SupabaseService.apiUrl;
      final response = await _dio.get(
        '$apiUrl/scrapers/leagues/$slug/standings',
        options: Options(responseType: ResponseType.json),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return LeagueDetailModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Backend standings no disponible ($e). Recurriendo al proveedor directo...');
    }

    // 2. Fallback directo al proveedor oficial (ESPN)
    return _fetchDirectFromProvider(
      leagueName: leagueName,
      slug: slug,
      leagueId: leagueId,
      seasonId: seasonId,
    );
  }

  Future<LeagueDetailModel> _fetchDirectFromProvider({
    required String leagueName,
    required String slug,
    String? leagueId,
    String? seasonId,
  }) async {
    final isNba = slug == 'nba';
    final isSoccer = !isNba && (slug.contains('.') || slug.startsWith('esp') || slug.startsWith('eng'));

    if (!isSoccer && !isNba) {
      // UFC, Esports u otras competiciones sin cobertura de tabla
      return LeagueDetailModel.empty(
        leagueSlug: slug,
        leagueName: leagueName,
        leagueId: leagueId,
        seasonId: seasonId,
      );
    }

    final standingsUrl = isNba
        ? 'https://site.api.espn.com/apis/v2/sports/basketball/nba/standings'
        : 'https://site.api.espn.com/apis/v2/sports/soccer/$slug/standings';

    final statsUrl = isNba
        ? 'https://site.api.espn.com/apis/site/v2/sports/basketball/nba/statistics'
        : 'https://site.api.espn.com/apis/site/v2/sports/soccer/$slug/statistics';

    Map<String, dynamic>? standingsData;
    Map<String, dynamic>? statsData;

    try {
      final res = await _dio.get(standingsUrl);
      if (res.statusCode == 200 && res.data is Map) {
        standingsData = Map<String, dynamic>.from(res.data as Map);
      }
    } catch (_) {}

    try {
      final res = await _dio.get(statsUrl);
      if (res.statusCode == 200 && res.data is Map) {
        statsData = Map<String, dynamic>.from(res.data as Map);
      }
    } catch (_) {}

    final groups = <LeagueStandingGroupModel>[];
    final rawChildren = standingsData?['children'] as List<dynamic>? ?? [];

    for (final child in rawChildren) {
      if (child is! Map) continue;
      final entriesList = child['standings']?['entries'] as List<dynamic>? ?? [];
      if (entriesList.isEmpty) continue;

      final entries = <LeagueStandingEntryModel>[];
      for (var i = 0; i < entriesList.length; i++) {
        final entry = entriesList[i];
        if (entry is! Map) continue;

        final team = entry['team'] as Map<dynamic, dynamic>? ?? {};
        final stats = entry['stats'] as List<dynamic>? ?? [];

        int? getVal(String key) {
          final found = stats.firstWhere(
            (s) => s is Map && (s['name'] == key || s['type'] == key),
            orElse: () => null,
          );
          if (found is Map && found['value'] != null) {
            return (found['value'] as num).toInt();
          }
          return null;
        }

        final pos = getVal('rank') ?? (i + 1);
        final logos = team['logos'] as List<dynamic>? ?? [];
        final logo = logos.isNotEmpty && logos[0] is Map ? logos[0]['href']?.toString() : null;
        final note = entry['note']?['description']?.toString();

        entries.add(
          LeagueStandingEntryModel(
            position: pos,
            teamId: team['id']?.toString(),
            participantId: isNba ? 'nba-team-${team['id']}' : 'football-team-${team['id']}',
            teamName: team['displayName']?.toString() ?? team['name']?.toString() ?? 'Equipo',
            teamLogo: logo,
            playedGames: getVal('gamesPlayed') ?? ((getVal('wins') ?? 0) + (getVal('losses') ?? 0)),
            points: getVal('points') ?? getVal('wins') ?? 0,
            won: getVal('wins'),
            drawn: getVal('ties'),
            lost: getVal('losses'),
            goalsFor: getVal('pointsFor'),
            goalsAgainst: getVal('pointsAgainst'),
            goalDifference: getVal('pointDifferential'),
            note: note,
            isPromotion: note != null || pos <= 4,
          ),
        );
      }

      if (entries.isNotEmpty) {
        groups.add(
          LeagueStandingGroupModel(
            name: child['name']?.toString() ?? 'General',
            entries: entries,
          ),
        );
      }
    }

    final topScorers = <LeagueScorerModel>[];
    final statsList = statsData?['stats'] as List<dynamic>? ?? [];
    final goalsCategory = statsList.firstWhere(
      (c) =>
          c is Map &&
          (c['name'] == 'goalsLeaders' || c['name'] == 'goals' || c['name'] == 'pointsLeaders'),
      orElse: () => null,
    );

    if (goalsCategory is Map) {
      final leaders = goalsCategory['leaders'] as List<dynamic>? ?? [];
      for (var i = 0; i < leaders.length && i < 20; i++) {
        final leader = leaders[i];
        if (leader is! Map) continue;

        final athlete = leader['athlete'] as Map<dynamic, dynamic>? ?? {};
        final team = leader['team'] as Map<dynamic, dynamic>? ?? {};
        final athleteStats = leader['statistics'] as List<dynamic>? ?? [];

        int? getLeaderStat(String key) {
          final found = athleteStats.firstWhere(
            (s) => s is Map && (s['name'] == key || s['type'] == key),
            orElse: () => null,
          );
          if (found is Map && found['value'] != null) {
            return (found['value'] as num).toInt();
          }
          return null;
        }

        final athleteLogos = team['logos'] as List<dynamic>? ?? [];
        final teamLogo =
            athleteLogos.isNotEmpty && athleteLogos[0] is Map ? athleteLogos[0]['href']?.toString() : null;

        topScorers.add(
          LeagueScorerModel(
            rank: i + 1,
            athleteId: athlete['id']?.toString(),
            playerName: athlete['displayName']?.toString() ??
                athlete['shortName']?.toString() ??
                'Jugador',
            playerPhoto: athlete['headshot']?['href']?.toString(),
            teamId: team['id']?.toString(),
            teamName: team['displayName']?.toString() ?? team['name']?.toString() ?? '',
            teamLogo: teamLogo,
            participantId: isNba ? 'nba-team-${team['id']}' : 'football-team-${team['id']}',
            goals: (leader['value'] as num?)?.toInt() ?? 0,
            playedGames: getLeaderStat('appearances'),
            assists: getLeaderStat('goalAssists'),
          ),
        );
      }
    }

    final hasStandings = groups.isNotEmpty && groups.any((g) => g.entries.isNotEmpty);
    final hasLeaders = topScorers.isNotEmpty;

    return LeagueDetailModel(
      version: 1,
      leagueId: leagueId,
      leagueSlug: slug,
      leagueName: leagueName,
      seasonId: seasonId,
      hasStandingsCoverage: hasStandings,
      hasLeadersCoverage: hasLeaders,
      groups: groups,
      topScorers: topScorers,
    );
  }
}
