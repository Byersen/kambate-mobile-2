import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../models/ufc_rankings_model.dart';
import '../../../services/supabase_service.dart';

class UfcRankingsRepository {
  final Dio _dio;

  UfcRankingsRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  static const List<String> _officialUfcUrls = [
    'https://www.ufcespanol.com/rankings',
    'https://www.ufc.com/rankings',
  ];

  /// Verifica que el modelo contenga un Top 15 oficial actualizado de UFC
  /// y descarta respuestas congeladas de ESPN (~2021 con solo 9-10 peleadores).
  static bool isOfficialTop15(UfcRankingsModel model) {
    if (!model.hasCoverage || model.categories.isEmpty) return false;
    final hasFullTop15 = model.categories.any((c) => c.ranks.length >= 15);
    if (!hasFullTop15) return false;

    for (final cat in model.categories) {
      if (cat.id == 'heavyweight' &&
          cat.champion?.name.toLowerCase().contains('ngannou') == true) {
        return false;
      }
    }
    return true;
  }

  Future<UfcRankingsModel> getUfcRankings({bool forceRefresh = false}) async {
    final apiUrl = SupabaseService.apiUrl;

    // 1. Fuente oficial primaria: portal oficial de rankings UFC (Top 15 actualizado)
    for (final officialUrl in _officialUfcUrls) {
      try {
        final officialResponse = await _dio.get<String>(
          officialUrl,
          options: Options(responseType: ResponseType.plain),
        );
        if (officialResponse.statusCode == 200 &&
            officialResponse.data != null &&
            officialResponse.data!.isNotEmpty) {
          final parsed = UfcRankingsModel.fromUfcOfficialHtml(officialResponse.data!);
          if (isOfficialTop15(parsed)) {
            return parsed;
          }
        }
      } catch (e) {
        debugPrint('No se pudo obtener HTML directo desde $officialUrl: $e');
      }
    }

    // 2. Consultar backend Kambate solo si entrega un Top 15 oficial actualizado
    for (final path in ['/scrapers/ufc/rankings', '/scrapers/leagues/ufc/rankings']) {
      try {
        final response = await _dio.get(
          '$apiUrl$path',
          options: Options(responseType: ResponseType.json),
        );

        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final model = UfcRankingsModel.fromJson(response.data as Map<String, dynamic>);
          if (isOfficialTop15(model)) {
            return model;
          }
        }
      } catch (e) {
        debugPrint('Fallo al consultar $path: $e');
      }
    }

    // 3. Respaldo oficial Top 15 actualizado (evita mostrar datos congelados de ESPN 2021)
    return UfcRankingsModel.officialTop15Fallback();
  }
}
