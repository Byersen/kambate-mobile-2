import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/sport_type.dart';

class SearchLeagueItem {
  final String name;
  final String subtitle;
  final SportType sport;
  final String region;
  final IconData? icon;
  final Color? color;

  const SearchLeagueItem({
    required this.name,
    required this.subtitle,
    required this.sport,
    required this.region,
    this.icon,
    this.color,
  });
}

/// Canonical leagues catalogue according to the official Kambate prototype (assets/images/vista-buscar.png)
/// and the supported multipsort architecture.
const List<SearchLeagueItem> kCanonicalLeagues = [
  SearchLeagueItem(
    name: 'Champions League',
    subtitle: '🇪🇺 UEFA',
    sport: SportType.soccer,
    region: 'Europa',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'NBA',
    subtitle: '🇺🇸 Estados Unidos',
    sport: SportType.nba,
    region: 'Norteamérica',
    icon: Icons.sports_basketball,
    color: AppColors.basketball,
  ),
  SearchLeagueItem(
    name: 'UFC',
    subtitle: 'Artes marciales mixtas',
    sport: SportType.ufc,
    region: 'Internacional',
    icon: Icons.sports_mma,
    color: AppColors.ufc,
  ),
  SearchLeagueItem(
    name: 'LCK',
    subtitle: 'League of Legends',
    sport: SportType.lol,
    region: 'Internacional',
    icon: Icons.sports_esports,
    color: AppColors.lol,
  ),
  SearchLeagueItem(
    name: 'VCT Americas',
    subtitle: 'Valorant',
    sport: SportType.valorant,
    region: 'Norteamérica',
    icon: Icons.track_changes,
    color: AppColors.valorant,
  ),
  SearchLeagueItem(
    name: 'Europa League',
    subtitle: '🇪🇺 UEFA',
    sport: SportType.soccer,
    region: 'Europa',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Premier League',
    subtitle: '🏴󠁧󠁢󠁥󠁮󠁧󠁿 Inglaterra',
    sport: SportType.soccer,
    region: 'Europa',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'LaLiga',
    subtitle: '🇪🇸 España',
    sport: SportType.soccer,
    region: 'Europa',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Serie A',
    subtitle: '🇮🇹 Italia',
    sport: SportType.soccer,
    region: 'Europa',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Bundesliga',
    subtitle: '🇩🇪 Alemania',
    sport: SportType.soccer,
    region: 'Europa',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Ligue 1',
    subtitle: '🇫🇷 Francia',
    sport: SportType.soccer,
    region: 'Europa',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Conference League',
    subtitle: '🇪🇺 UEFA',
    sport: SportType.soccer,
    region: 'Europa',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Copa Libertadores',
    subtitle: '🌎 CONMEBOL',
    sport: SportType.soccer,
    region: 'Sudamérica',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Copa Sudamericana',
    subtitle: '🌎 CONMEBOL',
    sport: SportType.soccer,
    region: 'Sudamérica',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Primera División',
    subtitle: '🇨🇱 Chile',
    sport: SportType.soccer,
    region: 'Sudamérica',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Liga Profesional',
    subtitle: '🇦🇷 Argentina',
    sport: SportType.soccer,
    region: 'Sudamérica',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Brasileirão',
    subtitle: '🇧🇷 Brasil',
    sport: SportType.soccer,
    region: 'Sudamérica',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'MLS',
    subtitle: '🇺🇸 Estados Unidos',
    sport: SportType.soccer,
    region: 'Norteamérica',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'Liga MX',
    subtitle: '🇲🇽 México',
    sport: SportType.soccer,
    region: 'Norteamérica',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  SearchLeagueItem(
    name: 'LEC',
    subtitle: 'League of Legends',
    sport: SportType.lol,
    region: 'Europa',
    icon: Icons.sports_esports,
    color: AppColors.lol,
  ),
  SearchLeagueItem(
    name: 'LCS',
    subtitle: 'League of Legends',
    sport: SportType.lol,
    region: 'Norteamérica',
    icon: Icons.sports_esports,
    color: AppColors.lol,
  ),
  SearchLeagueItem(
    name: 'VCT EMEA',
    subtitle: 'Valorant',
    sport: SportType.valorant,
    region: 'Europa',
    icon: Icons.track_changes,
    color: AppColors.valorant,
  ),
];
