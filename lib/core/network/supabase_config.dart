import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Client Manager for GROWTH OS
class SupabaseConfig {
  static const String defaultUrl = 'https://demo-growthos.supabase.co';
  static const String defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  static bool get isConfigured {
    try {
      return Supabase.instance.client != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> initialize({String? url, String? anonKey}) async {
    try {
      await Supabase.initialize(
        url: url ?? defaultUrl,
        anonKey: anonKey ?? defaultAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      debugPrint('[SupabaseConfig] Initialized successfully');
    } catch (e) {
      debugPrint('[SupabaseConfig Warning] Using offline local mode: $e');
    }
  }

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw Exception('Supabase client not initialized. Offline mode will be used.');
    }
  }

  static User? get currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isAuthenticated {
    return currentUser != null;
  }
}
