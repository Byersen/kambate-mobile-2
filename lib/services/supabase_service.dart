import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  static const String _defaultRailwayUrl =
      'https://kambate-backend-production.up.railway.app';

  static String get apiUrl {
    final configured = dotenv.env['API_URL'] ?? _defaultRailwayUrl;
    if (!kIsWeb && configured.contains('localhost')) {
      return _defaultRailwayUrl;
    }
    if (kIsWeb && configured.contains('localhost')) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return configured.replaceAll('localhost', host);
      }
    }
    return configured;
  }

  static Future<void> initialize() async {
    try {
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {
        try {
          await dotenv.load(fileName: '.env.example');
        } catch (_) {}
      }
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isNotEmpty &&
          supabaseAnonKey.isNotEmpty &&
          !supabaseUrl.contains('your-project-ref')) {
        await Supabase.initialize(
          url: supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey,
        );
        _isInitialized = true;
        debugPrint('Supabase successfully initialized');
      } else {
        debugPrint(
          'Supabase credentials are placeholder or empty. Skipping Supabase.initialize for offline/dev mode.',
        );
      }
    } catch (e) {
      debugPrint('Warning: Could not initialize Supabase ($e)');
    }
  }
}
