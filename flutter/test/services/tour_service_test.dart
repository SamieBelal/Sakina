import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/tour_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shouldShow returns true the first time and false after markSeen',
      () async {
    final svc = TourService();
    expect(await svc.shouldShow('uid1', TourKey.home), isTrue);
    await svc.markSeen('uid1', TourKey.home);
    expect(await svc.shouldShow('uid1', TourKey.home), isFalse);
  });

  test('flags are scoped per user', () async {
    final svc = TourService();
    await svc.markSeen('uid1', TourKey.home);
    expect(await svc.shouldShow('uid2', TourKey.home), isTrue);
  });

  test('resetAll restores all four tours to shouldShow=true', () async {
    final svc = TourService();
    await svc.markSeen('uid1', TourKey.home);
    await svc.markSeen('uid1', TourKey.duas);
    await svc.markSeen('uid1', TourKey.collection);
    await svc.markSeen('uid1', TourKey.journal);
    await svc.resetAll('uid1');
    for (final k in TourKey.values) {
      expect(await svc.shouldShow('uid1', k), isTrue);
    }
  });

  test('version-keyed: legacy v0 flag is ignored', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_seen_uid1_home_v0', true);
    final svc = TourService();
    expect(await svc.shouldShow('uid1', TourKey.home), isTrue);
  });

  test('flags persist across TourService instances (same prefs backing)',
      () async {
    final svc1 = TourService();
    await svc1.markSeen('uid1', TourKey.home);
    final svc2 = TourService();
    expect(await svc2.shouldShow('uid1', TourKey.home), isFalse);
  });
}
