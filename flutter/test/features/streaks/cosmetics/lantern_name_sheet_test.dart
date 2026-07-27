// E3 name-your-lantern: the validator + the client-only persistence seam.
//
// OQ-D2 ruling: there is NO server `lantern_name` column or RPC — the name is a
// user-scoped SharedPreferences value today (DEP-D1 tracks the server field).
// DB-free: the sync service is faked so `scopedKey` never touches Supabase.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_name_sheet.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-1'));
  });

  tearDown(SupabaseSyncService.debugReset);

  test('validates length and blocks blank/over-long/unicode-control names', () {
    expect(validateLanternName('Noor'), isNull);
    expect(validateLanternName(''), isNotNull);
    expect(validateLanternName('   '), isNotNull);
    expect(validateLanternName('x' * 25), isNotNull); // > 20
    expect(validateLanternName('bad\u202Ename'), isNotNull); // bidi override
    expect(validateLanternName('bad\u200Bname'), isNotNull); // zero-width
  });

  test('blocks a basic profanity token', () {
    expect(validateLanternName('shit'), isNotNull);
    expect(validateLanternName('Fuck it'), isNotNull);
  });

  test('short blocked tokens do not false-positive inside real words', () {
    // 'ass' is matched as a whole word only — otherwise "Compassion" and
    // "Damascus" would be rejected, which is worse than the miss it prevents.
    expect(validateLanternName('Compassion'), isNull);
    expect(validateLanternName('Damascus'), isNull);
    expect(validateLanternName('ass'), isNotNull);
  });

  test('round-trips the name through a user-scoped pref key', () async {
    expect(await readLanternName(), isNull);

    await saveLanternName('  Noor  ');
    expect(await readLanternName(), 'Noor');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sakina_lantern_name:user-1'), 'Noor');
    expect(prefs.getString('sakina_lantern_name'), isNull);
  });
}
