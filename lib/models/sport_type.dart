import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum SportType {
  all(
    id: 'all',
    displayName: 'Todos',
    icon: Icons.sports_outlined,
    color: AppColors.primary,
  ),
  soccer(
    id: 'soccer',
    displayName: 'Fútbol',
    icon: Icons.sports_soccer,
    color: AppColors.soccer,
  ),
  nba(
    id: 'nba',
    displayName: 'NBA',
    icon: Icons.sports_basketball,
    color: AppColors.basketball,
  ),
  ufc(
    id: 'ufc',
    displayName: 'UFC / MMA',
    icon: Icons.sports_mma,
    color: AppColors.ufc,
  ),
  lol(
    id: 'lol',
    displayName: 'LoL',
    icon: Icons.sports_esports,
    color: AppColors.lol,
  ),
  valorant(
    id: 'valorant',
    displayName: 'Valorant',
    icon: Icons.track_changes,
    color: AppColors.valorant,
  );

  final String id;
  final String displayName;
  final IconData icon;
  final Color color;

  const SportType({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.color,
  });

  static SportType fromString(String? value) {
    if (value == null) return SportType.all;
    switch (value.toLowerCase()) {
      case 'soccer':
      case 'football':
      case 'futbol':
      case 'fútbol':
        return SportType.soccer;
      case 'nba':
      case 'basketball':
      case 'basquetbol':
        return SportType.nba;
      case 'ufc':
      case 'mma':
        return SportType.ufc;
      case 'lol':
      case 'league of legends':
      case 'league_of_legends':
        return SportType.lol;
      case 'valorant':
        return SportType.valorant;
      default:
        return SportType.all;
    }
  }
}
