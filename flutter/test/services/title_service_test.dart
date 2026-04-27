import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/title_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  // ---------------------------------------------------------------------------
  // getUnlockedTitles — pure derivation from level + longestStreak
  // ---------------------------------------------------------------------------

  group('getUnlockedTitles derivation', () {
    test('level 1, streak 0 returns only Seeker', () {
      final titles = getUnlockedTitles(currentLevel: 1, longestStreak: 0);
      expect(titles, ['Seeker']);
    });

    test('level 5, streak 0 returns every level title with level ≤ 5', () {
      final titles = getUnlockedTitles(currentLevel: 5, longestStreak: 0);
      final expected = xpLevels
          .where((l) => l.level <= 5 && l.unlocksTitle)
          .map((l) => l.title)
          .toList();
      expect(titles, expected);
    });

    test('level 1, streak 7 includes Consistent', () {
      final titles = getUnlockedTitles(currentLevel: 1, longestStreak: 7);
      expect(titles, containsAll(['Seeker', 'Consistent']));
      expect(titles, isNot(contains('Unwavering')));
    });

    test(
        'REGRESSION: level 1, streak 30 includes Unwavering '
        '(initializeUnlockedTitles used to miss streak titles)', () {
      final titles = getUnlockedTitles(currentLevel: 1, longestStreak: 30);
      expect(titles, containsAll(['Seeker', 'Consistent', 'Unwavering']));
      expect(titles, isNot(contains('Steadfast Soul')));
    });

    test('level 1, streak 90 includes Steadfast Soul', () {
      final titles = getUnlockedTitles(currentLevel: 1, longestStreak: 90);
      expect(
          titles,
          containsAll(
              ['Seeker', 'Consistent', 'Unwavering', 'Steadfast Soul']));
      expect(titles, isNot(contains('Guardian of Light')));
    });

    test('level 1, streak 365 includes Guardian of Light', () {
      final titles = getUnlockedTitles(currentLevel: 1, longestStreak: 365);
      expect(
          titles,
          containsAll([
            'Seeker',
            'Consistent',
            'Unwavering',
            'Steadfast Soul',
            'Guardian of Light',
          ]));
    });

    test('level 50, streak 365 includes every unlockable title', () {
      final titles = getUnlockedTitles(currentLevel: 50, longestStreak: 365);
      final expectedLevelTitles = xpLevels
          .where((l) => l.level <= 50 && l.unlocksTitle)
          .map((l) => l.title);
      final expectedStreakTitles = streakMilestones
          .where((m) => m.days <= 365 && m.titleUnlock != null)
          .map((m) => m.titleUnlock!);
      expect(titles, containsAll(expectedLevelTitles));
      expect(titles, containsAll(expectedStreakTitles));
    });
  });

  // ---------------------------------------------------------------------------
  // selectTitle / setAutoTitle — local write + remote push + dirty flag
  // ---------------------------------------------------------------------------

  group('selectTitle push behavior', () {
    test('offline (no userId): writes locally, no upsert, no dirty flag',
        () async {
      fakeSync.userId = null;

      await selectTitle('Unwavering');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sakina_selected_title'), 'Unwavering');
      expect(prefs.getBool('sakina_title_auto_mode'), false);
      expect(prefs.getBool('sakina_title_prefs_dirty'), isNull);
      expect(fakeSync.rawUpsertCalls, isEmpty);
    });

    test('online happy path: writes locally, upserts, clears dirty', () async {
      await selectTitle('Unwavering');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sakina_selected_title:user-1'), 'Unwavering');
      expect(prefs.getBool('sakina_title_auto_mode:user-1'), false);
      expect(fakeSync.rawUpsertCalls, hasLength(1));
      final call = fakeSync.rawUpsertCalls.single;
      expect(call['table'], 'user_profiles');
      expect(call['data'], {
        'id': 'user-1',
        'selected_title': 'Unwavering',
        'is_auto_title': false,
      });
      expect(prefs.getBool('sakina_title_prefs_dirty:user-1'), isNull);
    });

    test('online failure path: writes locally, dirty flag remains set',
        () async {
      fakeSync.nextUpsertShouldFail = true;

      await selectTitle('Unwavering');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sakina_selected_title:user-1'), 'Unwavering');
      expect(prefs.getBool('sakina_title_prefs_dirty:user-1'), true);
    });
  });

  group('setAutoTitle push behavior', () {
    test('clears selection, writes auto, upserts null selected_title',
        () async {
      // Seed a manual selection first.
      await selectTitle('Consistent');
      fakeSync.rawUpsertCalls.clear();

      await setAutoTitle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sakina_title_auto_mode:user-1'), true);
      expect(prefs.getString('sakina_selected_title:user-1'), isNull);
      expect(fakeSync.rawUpsertCalls, hasLength(1));
      final call = fakeSync.rawUpsertCalls.single;
      expect(call['data'], {
        'id': 'user-1',
        'selected_title': null,
        'is_auto_title': true,
      });
    });
  });

  // ---------------------------------------------------------------------------
  // getDisplayTitle — reads scoped local prefs, auto fallback
  // ---------------------------------------------------------------------------

  group('getDisplayTitle', () {
    test('auto mode returns current level title', () async {
      await setAutoTitle();
      final display = await getDisplayTitle(3);
      final expected = xpLevels.firstWhere((l) => l.level == 3);
      expect(display.title, expected.title);
      expect(display.titleArabic, expected.titleArabic);
      expect(display.isAuto, true);
    });

    test('manual mode returns selected title', () async {
      await selectTitle('Unwavering');
      final display = await getDisplayTitle(3);
      expect(display.title, 'Unwavering');
      expect(display.isAuto, false);
    });

    test('manual mode with no selection falls back to auto', () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate a corrupted state: auto=false but no selected key.
      await prefs.setBool('sakina_title_auto_mode:user-1', false);
      final display = await getDisplayTitle(2);
      expect(display.isAuto, true);
      final expected = xpLevels.firstWhere((l) => l.level == 2);
      expect(display.title, expected.title);
    });

    test(
        'manual selection survives a level read past every unlocked level '
        '(case 3: new auto title would unlock but manual stays sticky)',
        () async {
      // User picks 'Seeker' manually at level 1.
      await selectTitle('Seeker');

      // Level reads at every higher level still return 'Seeker' — never
      // promote to whatever level title would unlock at that rank.
      for (final level in [2, 5, 10, 25, 50]) {
        final display = await getDisplayTitle(level);
        expect(display.title, 'Seeker',
            reason:
                'Manual selection must override auto-promotion at level $level');
        expect(display.isAuto, false);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // prepareTitlePrefsCacheForHydration — legacy migration
  // ---------------------------------------------------------------------------

  group('prepareTitlePrefsCacheForHydration', () {
    test('migrates legacy unscoped string + bool keys to scoped form',
        () async {
      SharedPreferences.setMockInitialValues({
        'sakina_selected_title': 'Consistent',
        'sakina_title_auto_mode': false,
      });

      await prepareTitlePrefsCacheForHydration();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sakina_selected_title:user-1'), 'Consistent');
      expect(prefs.getBool('sakina_title_auto_mode:user-1'), false);
      expect(prefs.getString('sakina_selected_title'), isNull);
      expect(prefs.getBool('sakina_title_auto_mode'), isNull);
    });

    test('retires legacy sakina_unlocked_titles key', () async {
      SharedPreferences.setMockInitialValues({
        'sakina_unlocked_titles': '["Seeker","Consistent"]',
      });

      await prepareTitlePrefsCacheForHydration();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sakina_unlocked_titles'), isNull);
    });

    test('no-op when only scoped values exist', () async {
      SharedPreferences.setMockInitialValues({
        'sakina_selected_title:user-1': 'Unwavering',
        'sakina_title_auto_mode:user-1': false,
      });

      await prepareTitlePrefsCacheForHydration();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sakina_selected_title:user-1'), 'Unwavering');
      expect(prefs.getBool('sakina_title_auto_mode:user-1'), false);
    });
  });

  // ---------------------------------------------------------------------------
  // hydrateTitlePrefsCache — reconcile dirty state, then overwrite
  // ---------------------------------------------------------------------------

  group('hydrateTitlePrefsCache', () {
    test('no dirty flag: server values overwrite scoped prefs', () async {
      await hydrateTitlePrefsCache(
        selectedTitle: 'Unwavering',
        isAutoTitle: false,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sakina_selected_title:user-1'), 'Unwavering');
      expect(prefs.getBool('sakina_title_auto_mode:user-1'), false);
      expect(fakeSync.rawUpsertCalls, isEmpty);
    });

    test('no dirty flag, null selected_title: clears selection, sets auto',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sakina_selected_title:user-1', 'StaleValue');
      await prefs.setBool('sakina_title_auto_mode:user-1', false);

      await hydrateTitlePrefsCache(selectedTitle: null, isAutoTitle: true);

      expect(prefs.getString('sakina_selected_title:user-1'), isNull);
      expect(prefs.getBool('sakina_title_auto_mode:user-1'), true);
    });

    test(
        'dirty flag set: pushes local first, clears dirty, then overwrites '
        'with remote values', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sakina_selected_title:user-1', 'Guardian of Light');
      await prefs.setBool('sakina_title_auto_mode:user-1', false);
      await prefs.setBool('sakina_title_prefs_dirty:user-1', true);

      await hydrateTitlePrefsCache(selectedTitle: null, isAutoTitle: true);

      // Push was attempted with LOCAL values.
      expect(fakeSync.rawUpsertCalls, hasLength(1));
      final call = fakeSync.rawUpsertCalls.single;
      expect(call['data'], {
        'id': 'user-1',
        'selected_title': 'Guardian of Light',
        'is_auto_title': false,
      });
      // Dirty flag cleared after successful push.
      expect(prefs.getBool('sakina_title_prefs_dirty:user-1'), isNull);
      // Remote values now authoritative — overwrite applied.
      expect(prefs.getString('sakina_selected_title:user-1'), isNull);
      expect(prefs.getBool('sakina_title_auto_mode:user-1'), true);
    });

    test(
        'dirty flag set, push fails: dirty stays set, local values unchanged',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sakina_selected_title:user-1', 'Guardian of Light');
      await prefs.setBool('sakina_title_auto_mode:user-1', false);
      await prefs.setBool('sakina_title_prefs_dirty:user-1', true);

      fakeSync.nextUpsertShouldFail = true;

      await hydrateTitlePrefsCache(selectedTitle: null, isAutoTitle: true);

      expect(prefs.getBool('sakina_title_prefs_dirty:user-1'), true);
      // Local values NOT overwritten.
      expect(prefs.getString('sakina_selected_title:user-1'), 'Guardian of Light');
      expect(prefs.getBool('sakina_title_auto_mode:user-1'), false);
    });
  });

  // ---------------------------------------------------------------------------
  // CRITICAL: shared-device regression — scoped keys isolate users
  // ---------------------------------------------------------------------------

  group('shared device scoping regression', () {
    test(
        'user A picks a title, user B signs in, user B does NOT see '
        "user A's title", () async {
      // User A picks a title.
      fakeSync.userId = 'user-A';
      await selectTitle('Guardian of Light');

      final prefs = await SharedPreferences.getInstance();
      expect(
          prefs.getString('sakina_selected_title:user-A'), 'Guardian of Light');
      // Unscoped key must be empty.
      expect(prefs.getString('sakina_selected_title'), isNull);

      // User B signs in on the same device.
      fakeSync.userId = 'user-B';

      final display = await getDisplayTitle(1);
      // Auto mode is the default for a brand-new user — user B sees THEIR
      // level-1 title (Seeker), not 'Guardian of Light'.
      expect(display.isAuto, true);
      expect(display.title, 'Seeker');
      expect(display.title, isNot('Guardian of Light'));
    });
  });
}
