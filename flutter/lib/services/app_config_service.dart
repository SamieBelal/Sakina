import 'dart:async';
import 'dart:convert';
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

  /// Cache-only service: answers from SharedPreferences, never refreshes.
  /// The production twin of [forTest], handed out by [resolve] when Supabase
  /// is not initialized (a build booted with empty env keys, or a read that
  /// races `Supabase.initialize`). Reading last-known config is strictly
  /// better than crashing or hardcoding.
  AppConfigService._cacheOnly() : _supabase = null;

  final SupabaseClient? _supabase;

  /// Memoized production instance for [resolve].
  static AppConfigService? _shared;

  /// Riverpod-free accessor for plain singletons that cannot reach
  /// [appConfigServiceProvider] — `GatingService` is one. Resolves to the real
  /// service once Supabase is initialized (and memoizes it); before that,
  /// returns a cache-only service so the caller still sees any value already
  /// in SharedPreferences and falls back cleanly when there is none.
  ///
  /// Never memoizes the cache-only path — a gate check that happens to run
  /// before `Supabase.initialize` must not permanently blind the app to
  /// config refreshes.
  static AppConfigService resolve() {
    final existing = _shared;
    if (existing != null) return existing;
    try {
      return _shared = AppConfigService(Supabase.instance.client);
    } catch (_) {
      return AppConfigService._cacheOnly();
    }
  }

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

  /// True when [key] has ANY cached value, fresh or stale.
  ///
  /// The one thing [getBool] cannot tell a caller apart: a cached `false` and a
  /// cache MISS both come back as `false` when the fallback is `false` (and a
  /// miss comes back as `true` when it isn't). A caller that must not act on a
  /// fallback — a kill switch on first install — checks this first and awaits
  /// [primeCache] before reading.
  Future<bool> hasCachedValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_valueKey(key)) != null;
  }

  /// Returns the string value of [key] from `app_config`.
  /// Returns [fallback] if no cached value exists AND the network fetch fails,
  /// or if the stored jsonb value is not a string. Mirrors [getBool] exactly:
  /// same cache-key scheme, same 6h stale-while-revalidate TTL, same
  /// [primeCache] participation — reads cache first, refreshes in background if
  /// stale.
  Future<String?> getString(String key, {String? fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_valueKey(key));
    final cachedAtMs = prefs.getInt(_timestampKey(key)) ?? 0;
    final stale =
        DateTime.now().millisecondsSinceEpoch - cachedAtMs > _cacheTtl.inMilliseconds;

    if (raw != null && !stale) return _asString(raw) ?? fallback;

    // Stale or missing: fire refresh in background, return what we have.
    unawaited(_refresh(key));
    if (raw == null) return fallback;
    return _asString(raw) ?? fallback;
  }

  /// Interprets a cached raw value as a string. `_refresh` stores values
  /// JSON-encoded so type survives the cache (`"soft"` for a string, `true` for
  /// a bool). Returns the decoded string for a JSON string; `null` when the
  /// stored jsonb value is NOT a string (bool / number / object) so the caller
  /// falls back. Legacy plain (non-JSON) cache entries are treated as the string
  /// itself for forward-compat.
  String? _asString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is String ? decoded : null;
    } catch (_) {
      // Not valid JSON → a legacy plain string entry; use it verbatim.
      return raw;
    }
  }

  /// Returns the integer value of [key] from `app_config`.
  /// Returns [fallback] if no cached value exists AND the network fetch fails,
  /// or if the stored jsonb value is not a number. Mirrors [getBool] /
  /// [getString] exactly: same cache-key scheme, same 6h stale-while-revalidate
  /// TTL, same [primeCache] participation — reads cache first, refreshes in the
  /// background if stale, and NEVER blocks on the network.
  ///
  /// A stale cached value beats the fallback on purpose: an offline launch must
  /// see the last-known dial, not a constant the server moved off months ago.
  Future<int> getInt(String key, {required int fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_valueKey(key));
    final cachedAtMs = prefs.getInt(_timestampKey(key)) ?? 0;
    final stale =
        DateTime.now().millisecondsSinceEpoch - cachedAtMs > _cacheTtl.inMilliseconds;

    if (raw != null && !stale) return _asInt(raw) ?? fallback;

    // Stale or missing: fire refresh in background, return what we have.
    unawaited(_refresh(key));
    if (raw == null) return fallback;
    return _asInt(raw) ?? fallback;
  }

  /// Interprets a cached raw value as an int. `_refresh` stores values
  /// JSON-encoded, so a jsonb number `3` round-trips as the string `'3'`.
  /// Returns null — so the caller falls back — when the stored value is not a
  /// number (bool / object / non-numeric string). A quoted numeric string
  /// (`'"3"'`) is accepted so a dial seeded as text still reads.
  int? _asInt(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is num) return decoded.toInt();
      if (decoded is String) return int.tryParse(decoded.trim());
      return null;
    } catch (_) {
      // Not valid JSON → a legacy plain entry; accept it if it parses.
      return int.tryParse(raw.trim());
    }
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
      // Persist JSON-encoded so the jsonb type survives the cache: a bool stores
      // as `true`/`false` (back-compat with getBool's `raw == 'true'` read), a
      // string stores quoted as `"soft"`. getString decodes and only returns a
      // value for genuine JSON strings, falling back for non-string jsonb.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_valueKey(key), jsonEncode(v));
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
