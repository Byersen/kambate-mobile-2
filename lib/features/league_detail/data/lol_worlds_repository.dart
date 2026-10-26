import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../models/lol_worlds_stage_model.dart';
import '../../../services/supabase_service.dart';

class LolWorldsRepository {
  final Dio _dio;

  LolWorldsRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  Future<LolWorldsStageModel> getLolWorldsStage({
    String? seasonSlug,
  }) async {
    final apiUrl = SupabaseService.apiUrl;
    final query = <String, dynamic>{
      if (seasonSlug != null && seasonSlug.isNotEmpty) 'season': seasonSlug,
    };

    try {
      final response = await _dio.get(
        '$apiUrl/scrapers/esports/lol/worlds/stage',
        queryParameters: query,
        options: Options(responseType: ResponseType.json),
      );

      if (response.statusCode == 200 && response.data is Map) {
        return LolWorldsStageModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        try {
          return LolWorldsStageModel.fromJson(
            Map<String, dynamic>.from(e.response!.data as Map),
          );
        } catch (_) {}
      }
      debugPrint('Aviso: ruta primaria de Worlds stage no disponible. Intentando alternativa...');
      try {
        final fallbackRes = await _dio.get(
          '$apiUrl/scrapers/leagues/worlds/stage',
          queryParameters: query,
          options: Options(responseType: ResponseType.json),
        );
        if (fallbackRes.statusCode == 200 && fallbackRes.data is Map) {
          return LolWorldsStageModel.fromJson(
            Map<String, dynamic>.from(fallbackRes.data as Map),
          );
        }
      } catch (fallbackErr) {
        if (fallbackErr is DioException && fallbackErr.response?.data is Map) {
          try {
            return LolWorldsStageModel.fromJson(
              Map<String, dynamic>.from(fallbackErr.response!.data as Map),
            );
          } catch (_) {}
        }
        debugPrint('Aviso: ruta alternativa de Worlds stage también finalizó sin datos');
      }
    }

    return LolWorldsStageModel.empty(
      slug: 'worlds',
      name: 'League of Legends World Championship',
      seasonSlug: seasonSlug,
      coverageStatus: 'PROVIDER_ERROR',
      message: 'No se pudo conectar con el proveedor oficial de League of Legends.',
    );
  }
}
