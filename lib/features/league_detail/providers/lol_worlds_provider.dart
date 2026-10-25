import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/lol_worlds_stage_model.dart';
import '../data/lol_worlds_repository.dart';

final lolWorldsRepositoryProvider = Provider<LolWorldsRepository>((ref) {
  return LolWorldsRepository();
});

final lolWorldsStageProvider =
    FutureProvider.family<LolWorldsStageModel, String?>((ref, seasonSlug) async {
  final repository = ref.watch(lolWorldsRepositoryProvider);
  return repository.getLolWorldsStage(seasonSlug: seasonSlug);
});
