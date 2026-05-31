import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-driven feature flags read from `public.app_config (key text PK, value jsonb)`.
///
/// Pattern mirrors `gating_service.dart`'s use of app_config for bypass token
/// cost: read with hardcoded fallback, cache in SharedPreferences for instant
/// reads on next launch.
///
/// Stale-while-revalidate:
/// - `getBool` returns cached value if fresh; if stale, returns cached + fires
///   async refresh.
/// - `primeCache` is called from main.dart in parallel with auth init so the
///   first router decision sees fresh values.
class AppConfigService {
  /// Production constructor — uses the real Supabase client.
  AppConfigService(SupabaseClient supabase) : _supabase = supabase;

  /// Test constructor — leaves the Supabase client null so the cache-hit and
  /// cache-miss paths can be exercised without an initialized Supabase. Any
  /// network refresh attempt becomes a no-op (the try/catch in [_refresh]
  /// swallows the NPE).
  AppConfigService.forTest() : _supabase = null;

  final SupabaseClient? _supabase;

  static const _cacheKey = 'app_config_cache_v1';
  static const _cacheTtl = Duration(hours: 6);

  String _valueKey(String key) => '${_cacheKey}_$key';
  String _timestampKey(String key) => '${_cacheKey}_${key}_at';

  /// Returns the boolean value of [key] from `app_config`.
  /// Returns [fallback] if no cached value exists AND the network fetch fails.
  /// Always fast: reads cache first, refreshes in background if stale.
  Future<bool> getBool(String key, {required bool fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_valueKey(key));
    final cachedAtMs = prefs.getInt(_timestampKey(key)) ?? 0;
    final stale =
        DateTime.now().millisecondsSinceEpoch - cachedAtMs > _cacheTtl.inMilliseconds;

    if (raw != null && !stale) return raw == 'true';

    // Stale or missing: fire refresh in background, return what we have
    unawaited(_refresh(key));
    return raw == null ? fallback : raw == 'true';
  }

  /// Pre-loads [keys] into the SharedPreferences cache. Call from main.dart
  /// in parallel with auth init so the first router decision sees fresh values.
  /// Errors are swallowed — fallback remains effective.
  Future<void> primeCache(List<String> keys) async {
    await Future.wait(keys.map(_refresh));
  }

  Future<void> _refresh(String key) async {
    try {
      final client = _supabase;
      if (client == null) return;
      final row = await client
          .from('app_config')
          .select('value')
          .eq('key', key)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));
      if (row == null) return;
      final v = row['value'];
      final asBool = v is bool ? v : (v?.toString() == 'true');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_valueKey(key), asBool ? 'true' : 'false');
      await prefs.setInt(
        _timestampKey(key),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Swallow — fallback returned by getBool keeps the app booting in a
      // known-good state. Refresh will retry on next call.
    }
  }
}

final appConfigServiceProvider = Provider<AppConfigService>(
  (_) => AppConfigService(Supabase.instance.client),
);
