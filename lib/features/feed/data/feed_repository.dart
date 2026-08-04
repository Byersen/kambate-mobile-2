import 'package:flutter/foundation.dart';
import '../../../models/event_model.dart';
import '../../../models/sport_type.dart';
import '../../../services/supabase_service.dart';
import 'mock_events.dart';

class FeedRepository {
  Future<List<EventModel>> getEvents({SportType? sport}) async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        var query = client.from('events').select();

        if (sport != null && sport != SportType.all) {
          query = query.eq('sport', sport.id);
        }

        final response = await query.order('start_time', ascending: true);
        final List<dynamic> data = response as List<dynamic>;

        if (data.isNotEmpty) {
          return data
              .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('FeedRepository Supabase query error: $e. Falling back to local mock data.');
    }

    // Fallback to local mock events for development / offline
    if (sport == null || sport == SportType.all) {
      return List<EventModel>.from(kMockEvents);
    }

    return kMockEvents.where((e) => e.sport == sport).toList();
  }

  Future<EventModel?> getEventById(String id) async {
    try {
      final client = SupabaseService.client;
      if (client != null) {
        final response = await client
            .from('events')
            .select()
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          return EventModel.fromJson(response);
        }
      }
    } catch (e) {
      debugPrint('FeedRepository getEventById error: $e');
    }

    try {
      return kMockEvents.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
