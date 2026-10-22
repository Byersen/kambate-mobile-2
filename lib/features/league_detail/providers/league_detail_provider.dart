import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/league_detail_model.dart';
import '../data/league_detail_repository.dart';

class LeagueDetailParams {
  final String leagueName;
  final String? leagueSlug;
  final String? leagueId;
  final String? seasonId;

  const LeagueDetailParams({
    required this.leagueName,
    this.leagueSlug,
    this.leagueId,
    this.seasonId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeagueDetailParams &&
          runtimeType == other.runtimeType &&
          leagueName == other.leagueName &&
          leagueSlug == other.leagueSlug &&
          leagueId == other.leagueId &&
          seasonId == other.seasonId;

  @override
  int get hashCode =>
      leagueName.hashCode ^
      leagueSlug.hashCode ^
      leagueId.hashCode ^
      seasonId.hashCode;
}

final leagueDetailRepositoryProvider = Provider<LeagueDetailRepository>((ref) {
  return LeagueDetailRepository();
});

final leagueDetailProvider =
    FutureProvider.family<LeagueDetailModel, LeagueDetailParams>(
        (ref, params) async {
  final repository = ref.watch(leagueDetailRepositoryProvider);
  return repository.getLeagueDetail(
    leagueName: params.leagueName,
    leagueSlug: params.leagueSlug,
    leagueId: params.leagueId,
    seasonId: params.seasonId,
  );
});
