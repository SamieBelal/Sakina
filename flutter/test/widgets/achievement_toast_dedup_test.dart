import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/widgets/achievement_toast.dart';

/// Regression tests for the achievement re-toast guard.
///
/// `checkAndUnlockAchievements` reads the local prefs cache then writes,
/// non-atomically, so two near-simultaneous `checkAchievements()` calls can
/// both report the same achievement as "newly unlocked". The DB
/// `UNIQUE(user_id, achievement_id)` constraint dedupes the row, but the user
/// still saw the popup twice. `showAchievementToast` now suppresses repeats
/// within a session. See investigate report: heyhey@gmail.com, 2026-06-04.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final first = allAchievements.firstWhere((a) => a.id == 'first_name');
  final second = allAchievements.firstWhere((a) => a.id == 'bronze_10');

  setUp(resetAchievementToastSession);
  tearDown(resetAchievementToastSession);

  test('first show of an achievement is enqueued', () {
    expect(showAchievementToast(first), isTrue);
  });

  test('repeat show of the same achievement is suppressed', () {
    expect(showAchievementToast(first), isTrue);
    expect(showAchievementToast(first), isFalse);
    expect(showAchievementToast(first), isFalse);
  });

  test('distinct achievements each show once', () {
    expect(showAchievementToast(first), isTrue);
    expect(showAchievementToast(second), isTrue);
    expect(showAchievementToast(first), isFalse);
    expect(showAchievementToast(second), isFalse);
  });

  test('reset re-enables toasts (account switch sees its own first-time toast)',
      () {
    expect(showAchievementToast(first), isTrue);
    expect(showAchievementToast(first), isFalse);

    resetAchievementToastSession();

    expect(showAchievementToast(first), isTrue,
        reason: 'after sign-out reset, a new account must see first_name again');
  });
}
