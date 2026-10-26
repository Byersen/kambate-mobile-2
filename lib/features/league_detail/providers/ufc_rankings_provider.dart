import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ufc_rankings_model.dart';
import '../data/ufc_rankings_repository.dart';

final ufcRankingsRepositoryProvider = Provider<UfcRankingsRepository>((ref) {
  return UfcRankingsRepository();
});

/// Proveedor de datos para los rankings oficiales de UFC.
final ufcRankingsProvider = FutureProvider<UfcRankingsModel>((ref) async {
  final repository = ref.watch(ufcRankingsRepositoryProvider);
  return repository.getUfcRankings();
});

/// Categoría seleccionada actualmente en la vista de Rankings de UFC (null = primera categoría por defecto).
final selectedUfcRankingCategoryIdProvider = StateProvider<String?>((ref) => null);
