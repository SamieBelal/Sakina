// The weekly recap's cadence marker, and the developer escape hatch for it.
//
// The recap fires at most once per calendar week and writes its marker the
// instant the line renders. Before this reset existed, the only two ways to see
// it a second time were to wait for Monday or to reinstall the app — so the
// highest-ceremony surface in the archive was, in practice, untestable. It
// reached a founder's device with nobody having seen it twice, and the symptom
// on arrival was the *fallback* line rendering in its slot and not responding to
// a tap.
//
// Two things pinned here:
//
//  * the reset clears the marker, and clears the SCOPED one — a reset that
//    wiped the unscoped key would silently do nothing on any signed-in build;
//  * it clears ONLY that, and invents no entries. A week with fewer than
//    `weeklyRecapMinEntries` in the window still has no recap, and a button
//    that implied otherwise would be lying about a gate it does not touch.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/journal/journal_resurfacing.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/dev_tools_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'user-1';
  const scoped = '$weeklyRecapLastWeekPrefsKey:$userId';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: userId),
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  test('clears this week\'s marker, so the recap is due again', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(scoped, '2026-08-03');

    // Precondition: spent. This is the state a founder's device is in the
    // moment after the recap renders once.
    expect(
      weeklyRecapIsDue(
        todayLocalDay: '2026-08-06',
        lastShownWeek: prefs.getString(scoped),
      ),
      isFalse,
    );

    await devResetWeeklyRecapCadence();

    expect(prefs.getString(scoped), isNull);
    expect(
      weeklyRecapIsDue(
        todayLocalDay: '2026-08-06',
        lastShownWeek: prefs.getString(scoped),
      ),
      isTrue,
    );
  });

  test('clears the scoped key, not the bare one', () async {
    final prefs = await SharedPreferences.getInstance();
    // The bare key is what a reset written without `scopedKey` would remove:
    // present here purely so its survival proves the right one was targeted.
    await prefs.setString(weeklyRecapLastWeekPrefsKey, 'bare');
    await prefs.setString(scoped, '2026-08-03');

    await devResetWeeklyRecapCadence();

    expect(prefs.getString(scoped), isNull);
    expect(prefs.getString(weeklyRecapLastWeekPrefsKey), 'bare');
  });

  test('a thin week still has no recap — the reset does not fake data',
      () async {
    await devResetWeeklyRecapCadence();

    // Due, but nothing to show: one entry against a minimum of two.
    expect(
      weeklyRecapIsDue(todayLocalDay: '2026-08-06', lastShownWeek: null),
      isTrue,
    );
    expect(
      resolveWeeklyRecap(
        entries: [
          const SavedReflection(
            id: 'r1',
            date: '2026-08-05T21:00:00.000Z',
            userText: 'anxious about the interview',
            name: 'Al-Wakeel',
            nameArabic: 'الوكيل',
            reframePreview: 'You are not carrying the outcome.',
            source: reflectionSourceMuhasabah,
            entryLocalDay: '2026-08-05',
          ),
        ],
        todayLocalDay: '2026-08-06',
      ),
      isNull,
    );
  });

  test('is idempotent — resetting an already-clear marker is a no-op',
      () async {
    await devResetWeeklyRecapCadence();
    await devResetWeeklyRecapCadence();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(scoped), isNull);
  });
}
