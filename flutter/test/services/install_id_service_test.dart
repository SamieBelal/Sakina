import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/install_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One Ship W2-E3 — the install id.
///
/// It is the join key between the pre-signup reel events (Mixpanel super
/// property) and the eventual subscriber (RevenueCat custom attribute), so the
/// two properties it must hold are: one value per install, and the SAME value
/// everywhere.
class _RecordingAnalyticsService extends AnalyticsService {
  final Map<String, dynamic> deviceSuperProperties = {};
  final Map<String, dynamic> superProperties = {};
  final List<String> removed = [];
  final List<String> tracked = [];

  @override
  void cacheDeviceSuperProperties(Map<String, dynamic> props) =>
      deviceSuperProperties.addAll(props);

  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      superProperties.addAll(props);

  @override
  void removeSuperProperty(String name) => removed.add(name);

  @override
  void track(String name, {Map<String, dynamic>? properties}) =>
      tracked.add(name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final realGenerate = InstallIdService.debugGenerate;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InstallIdService.debugReset();
    InstallIdService.debugGenerate = realGenerate;
  });

  tearDown(InstallIdService.debugReset);

  test('mints a v4 uuid on the first call and persists it', () async {
    final id = await InstallIdService().getOrCreate();

    expect(id, isNotEmpty);
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ),
      ),
      reason: 'must be a real v4 uuid, not a timestamp or a counter',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(installIdPrefsKey), id);
  });

  test('is stable across calls within a session', () async {
    final first = await InstallIdService().getOrCreate();
    final second = await InstallIdService().getOrCreate();
    final third = await InstallIdService().getOrCreate();

    expect(second, first);
    expect(third, first);
  });

  test('is stable across a relaunch (re-read from prefs, not re-minted)',
      () async {
    final first = await InstallIdService().getOrCreate();

    InstallIdService.debugReset(); // simulates a fresh process
    final afterRelaunch = await InstallIdService().getOrCreate();

    expect(afterRelaunch, first);
  });

  test('concurrent first calls share one id', () async {
    // Boot calls this from the analytics bootstrap AND the purchase-service
    // init. Two overlapping mints would hand Mixpanel and RevenueCat different
    // ids for the same install, which is exactly the join this key exists for.
    final results = await Future.wait([
      InstallIdService().getOrCreate(),
      InstallIdService().getOrCreate(),
      InstallIdService().getOrCreate(),
    ]);

    expect(results.toSet(), hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(installIdPrefsKey), results.first);
  });

  test('the prefs key is UNSCOPED so it survives a sign-out', () {
    // Scoping it to a user would mint a new id per account, and the pre-signup
    // events — which have no user yet — could never be joined to anything.
    expect(installIdPrefsKey, 'install_id');
    expect(installIdPrefsKey, isNot(contains('user')));
  });

  test('the property name is a CUSTOM attribute, not RevenueCat\'s reserved '
      'mixpanel distinct-id slot', () {
    // `\$mixpanelDistinctId` asserts the subscriber IS a Mixpanel distinct id,
    // which stops being true the moment identify() runs under Simplified ID
    // Merge. The install id never changes, so it is its own attribute.
    expect(installIdPropertyName, 'install_id');
    expect(installIdPropertyName, isNot(startsWith(r'$')));
  });

  group('boot registration', () {
    Future<_RecordingAnalyticsService> bootstrap({String? installId}) async {
      final analytics = _RecordingAnalyticsService();
      await registerBootstrapAnalytics(
        analytics: analytics,
        prefs: await SharedPreferences.getInstance(),
        platform: 'iOS',
        appVersion: '1.2.0+4',
        flagOnboardingTrim: true,
        flagHardPaywall: false,
        flagGuidedTour: true,
        isPremium: false,
        installId: installId,
      );
      return analytics;
    }

    test('registers install_id as a DEVICE super property', () async {
      final id = await InstallIdService().getOrCreate();
      final analytics = await bootstrap(installId: id);

      expect(analytics.deviceSuperProperties[installIdPropertyName], id);
    });

    test('device-scoped, so the sign-out reset re-applies it', () async {
      // If it went through `setSuperProperties` instead, signing out would
      // drop it and the next session's pre-signup events would be unjoinable.
      final id = await InstallIdService().getOrCreate();
      final analytics = await bootstrap(installId: id);

      expect(analytics.superProperties.containsKey(installIdPropertyName),
          isFalse);
    });

    test('a failed read omits the property rather than registering null',
        () async {
      // A null super property looks like a real value in a Mixpanel breakdown.
      final analytics = await bootstrap(installId: null);

      expect(analytics.deviceSuperProperties.containsKey(installIdPropertyName),
          isFalse);
    });

    test('an empty id is omitted too', () async {
      final analytics = await bootstrap(installId: '');

      expect(analytics.deviceSuperProperties.containsKey(installIdPropertyName),
          isFalse);
    });
  });
}
