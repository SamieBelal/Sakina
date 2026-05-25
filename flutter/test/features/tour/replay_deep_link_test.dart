import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/tour_service.dart';

/// T20 — replay deep-link semantics.
///
/// The full SettingsScreen widget pump requires Supabase init + GoRouter +
/// notification service stubs, which makes a real `autoAction: 'replay_tour'`
/// end-to-end test brittle (and slow). The smaller observable contract worth
/// pinning is: when the replay action fires, [TourService.resetAll] removes
/// every tour's seen flag so the next Home tour render will surface again.
///
/// What's NOT tested here (covered by manual QA):
///   - The widget actually receives `autoAction: 'replay_tour'` from the
///     router's query-param parsing. Exercised by hand via `flutter run`
///     with `sakina://settings?action=replay_tour`.
///   - `context.go('/')` runs after resetAll. Trivial one-liner; pumping a
///     full GoRouter to assert it loses more time than it saves.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('T20: TourService.resetAll wipes all four tour seen flags', () async {
    const userId = 'test-user-id';
    final svc = TourService();
    // Pre-seed all four tours as "seen".
    for (final k in TourKey.values) {
      await svc.markSeen(userId, k);
      expect(await svc.shouldShow(userId, k), isFalse,
          reason: 'precondition: $k must be marked seen');
    }
    // Replay invocation.
    await svc.resetAll(userId);
    // Every tour should re-surface for this user.
    for (final k in TourKey.values) {
      expect(await svc.shouldShow(userId, k), isTrue,
          reason: 'resetAll must re-eligible $k');
    }
  });

  test('T20b: resetAll only affects the targeted user', () async {
    const userA = 'user-a';
    const userB = 'user-b';
    final svc = TourService();
    await svc.markSeen(userA, TourKey.home);
    await svc.markSeen(userB, TourKey.home);
    await svc.resetAll(userA);
    expect(await svc.shouldShow(userA, TourKey.home), isTrue);
    expect(await svc.shouldShow(userB, TourKey.home), isFalse,
        reason: 'replay must not nuke other users\' seen flags');
  });
}
