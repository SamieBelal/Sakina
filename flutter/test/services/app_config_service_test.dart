import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/app_config_service.dart';

void main() {
  // NOTE: tests use SharedPreferences mock. The Supabase paths are tested
  // indirectly via setting prefs to simulate cached values. Network paths
  // (the Supabase call inside _refresh) are not directly invoked because
  // there is no Supabase client initialized in unit tests — instead we
  // verify the cache-hit and missing-cache behaviors.

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('cache hit (fresh) returns cached value', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_config_cache_v1_test_key', 'false');
    await prefs.setInt(
      'app_config_cache_v1_test_key_at',
      DateTime.now().millisecondsSinceEpoch,
    );

    // Pass a dummy Supabase client — won't be hit on a cache-fresh path.
    // We bypass it by constructing the service but relying on cache-hit logic.
    final svc = AppConfigService.forTest();
    final result = await svc.getBool('test_key', fallback: true);
    expect(result, isFalse, reason: 'Cache hit must return cached value, not fallback');
  });

  test('cache miss returns fallback', () async {
    final svc = AppConfigService.forTest();
    final result = await svc.getBool('test_key', fallback: true);
    expect(result, isTrue);
  });

  test('cache hit (stale) returns cached + would fire refresh', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_config_cache_v1_test_key', 'false');
    // 7 hours ago — past 6h TTL
    await prefs.setInt(
      'app_config_cache_v1_test_key_at',
      DateTime.now().millisecondsSinceEpoch - const Duration(hours: 7).inMilliseconds,
    );
    final svc = AppConfigService.forTest();
    final result = await svc.getBool('test_key', fallback: true);
    // Returns stale value, not fallback — important so an offline launch
    // sees the last-known config, not the hardcoded default.
    expect(result, isFalse);
  });

  test('cache fallback when entirely missing and offline', () async {
    final svc = AppConfigService.forTest();
    expect(await svc.getBool('never_seen', fallback: false), isFalse);
    expect(await svc.getBool('never_seen', fallback: true), isTrue);
  });

  group('getString', () {
    test('cache hit (fresh) returns cached string value', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config_cache_v1_post_tour_paywall_mode', 'soft');
      await prefs.setInt(
        'app_config_cache_v1_post_tour_paywall_mode_at',
        DateTime.now().millisecondsSinceEpoch,
      );
      final svc = AppConfigService.forTest();
      final result =
          await svc.getString('post_tour_paywall_mode', fallback: 'off');
      expect(result, 'soft',
          reason: 'Cache hit must return cached value, not fallback');
    });

    test('cache miss returns fallback', () async {
      final svc = AppConfigService.forTest();
      final result =
          await svc.getString('post_tour_paywall_mode', fallback: 'off');
      expect(result, 'off');
    });

    test('cache miss returns null fallback when none provided', () async {
      final svc = AppConfigService.forTest();
      final result = await svc.getString('post_tour_paywall_mode');
      expect(result, isNull);
    });

    test('cache hit (JSON-encoded string, the real refresh format) decodes',
        () async {
      final prefs = await SharedPreferences.getInstance();
      // _refresh stores jsonEncode('soft') == '"soft"'.
      await prefs.setString(
          'app_config_cache_v1_post_tour_paywall_mode', '"soft"');
      await prefs.setInt(
        'app_config_cache_v1_post_tour_paywall_mode_at',
        DateTime.now().millisecondsSinceEpoch,
      );
      final svc = AppConfigService.forTest();
      final result =
          await svc.getString('post_tour_paywall_mode', fallback: 'off');
      expect(result, 'soft', reason: 'JSON-encoded string must decode back');
    });

    test('non-string jsonb (bool) returns fallback', () async {
      final prefs = await SharedPreferences.getInstance();
      // A bool-valued flag cached by getBool/_refresh: jsonEncode(true)=='true'.
      await prefs.setString('app_config_cache_v1_post_tour_paywall_mode', 'true');
      await prefs.setInt(
        'app_config_cache_v1_post_tour_paywall_mode_at',
        DateTime.now().millisecondsSinceEpoch,
      );
      final svc = AppConfigService.forTest();
      final result =
          await svc.getString('post_tour_paywall_mode', fallback: 'off');
      expect(result, 'off',
          reason: 'A non-string jsonb value must fall back, not return "true"');
    });

    test('cache hit (stale) returns cached + would fire refresh (getString)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'app_config_cache_v1_post_tour_paywall_mode', '"hard"');
      // 7 hours ago — past the 6h TTL.
      await prefs.setInt(
        'app_config_cache_v1_post_tour_paywall_mode_at',
        DateTime.now().millisecondsSinceEpoch -
            const Duration(hours: 7).inMilliseconds,
      );
      final svc = AppConfigService.forTest();
      final result =
          await svc.getString('post_tour_paywall_mode', fallback: 'off');
      // Returns stale value, not fallback — an offline launch sees last-known
      // config, not the hardcoded default.
      expect(result, 'hard');
    });
  });

  group('getInt', () {
    // The free-tier warmup dials (W5 D.1) read through here. `_refresh` stores
    // a jsonb number JSON-encoded, so `3` round-trips as the string '3'.
    Future<void> cache(String key, String raw, {Duration age = Duration.zero}) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config_cache_v1_$key', raw);
      await prefs.setInt(
        'app_config_cache_v1_${key}_at',
        DateTime.now().millisecondsSinceEpoch - age.inMilliseconds,
      );
    }

    test('cache hit (fresh) returns the cached number', () async {
      await cache('warmup_reflect_size', '3');
      final svc = AppConfigService.forTest();
      expect(await svc.getInt('warmup_reflect_size', fallback: 10), 3);
    });

    test('cache miss returns fallback', () async {
      final svc = AppConfigService.forTest();
      expect(await svc.getInt('warmup_reflect_size', fallback: 10), 10);
    });

    test('cache hit (stale) returns cached, not fallback', () async {
      await cache('warmup_reflect_size', '3', age: const Duration(hours: 7));
      final svc = AppConfigService.forTest();
      expect(await svc.getInt('warmup_reflect_size', fallback: 10), 3,
          reason: 'an offline launch must see the last-known dial');
    });

    test('non-numeric jsonb (bool / object / word) returns fallback', () async {
      final svc = AppConfigService.forTest();
      await cache('k_bool', 'true');
      expect(await svc.getInt('k_bool', fallback: 10), 10);
      await cache('k_obj', '{"a":1}');
      expect(await svc.getInt('k_obj', fallback: 10), 10);
      await cache('k_word', '"lots"');
      expect(await svc.getInt('k_word', fallback: 10), 10);
    });

    test('a quoted numeric string still parses (dial seeded as text)',
        () async {
      await cache('warmup_reflect_size', '"3"');
      final svc = AppConfigService.forTest();
      expect(await svc.getInt('warmup_reflect_size', fallback: 10), 3);
    });

    test('a legacy plain (non-JSON) cache entry still parses', () async {
      await cache('warmup_reflect_size', '3 ');
      final svc = AppConfigService.forTest();
      expect(await svc.getInt('warmup_reflect_size', fallback: 10), 3);
    });

    test('zero is honoured, not treated as absent', () async {
      await cache('warmup_reflect_size', '0');
      final svc = AppConfigService.forTest();
      expect(await svc.getInt('warmup_reflect_size', fallback: 10), 0);
    });
  });

  group('resolve()', () {
    test('without an initialized Supabase, answers from cache and falls back '
        'instead of throwing', () async {
      await SharedPreferences.getInstance().then((prefs) async {
        await prefs.setString('app_config_cache_v1_warmup_reflect_size', '3');
        await prefs.setInt(
          'app_config_cache_v1_warmup_reflect_size_at',
          DateTime.now().millisecondsSinceEpoch,
        );
      });
      final svc = AppConfigService.resolve();
      expect(await svc.getInt('warmup_reflect_size', fallback: 10), 3);
      expect(await svc.getInt('never_seen', fallback: 10), 10);
    });
  });
}
