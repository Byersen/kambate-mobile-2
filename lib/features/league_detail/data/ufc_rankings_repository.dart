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

  Future<UfcRankingsModel> getUfcRankings({bool forceRefresh = false}) async {
    final apiUrl = SupabaseService.apiUrl;

    // 1. Intentar endpoint oficial en backend Kambate
    try {
      final response = await _dio.get(
        '$apiUrl/scrapers/ufc/rankings',
        options: Options(responseType: ResponseType.json),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = UfcRankingsModel.fromJson(response.data as Map<String, dynamic>);
        if (model.categories.isNotEmpty) return model;
      }
    } catch (e) {
      debugPrint('Fallo al consultar /scrapers/ufc/rankings: $e. Intentando ruta alternativa...');
      try {
        final altResponse = await _dio.get(
          '$apiUrl/scrapers/leagues/ufc/rankings',
          options: Options(responseType: ResponseType.json),
        );
        if (altResponse.statusCode == 200 && altResponse.data is Map<String, dynamic>) {
          final model = UfcRankingsModel.fromJson(altResponse.data as Map<String, dynamic>);
          if (model.categories.isNotEmpty) return model;
        }
      } catch (altErr) {
        debugPrint('Ruta alternativa también falló: $altErr');
      }
    }

    // 2. Resiliencia: Fallback directo a la API pública oficial de ESPN
    try {
      final espnResponse = await _dio.get(
        'https://site.api.espn.com/apis/site/v2/sports/mma/ufc/rankings',
        options: Options(responseType: ResponseType.json),
      );

      if (espnResponse.statusCode == 200 && espnResponse.data is Map<String, dynamic>) {
        final parsed = UfcRankingsModel.fromEspnRaw(espnResponse.data as Map<String, dynamic>);
        if (parsed.categories.isNotEmpty) return parsed;
      }
    } catch (espnErr) {
      debugPrint('Consulta directa a ESPN también falló: $espnErr');
    }

    // 3. Estado seguro sin cobertura si ninguna fuente estuvo disponible
    return UfcRankingsModel.empty(
      hasCoverage: false,
      message: 'No se pudo conectar con el proveedor oficial de UFC.',
    );
  }
}
