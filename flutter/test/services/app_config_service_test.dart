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

    test('cache hit (stale) returns cached + would fire refresh', () async {
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
}
