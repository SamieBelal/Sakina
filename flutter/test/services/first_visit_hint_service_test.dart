import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/first_visit_hint_service.dart';

/// F3 — the four binding guardrails on first-visit hints, plus once-ever and
/// per-user scoping. These are the rules that stop a hint mechanic becoming a
/// hint *system*; if one of these tests is deleted, the mechanic has changed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = FirstVisitHintService.instance;

  /// Puts us past guardrail 3 (no hints in the first session) so the other
  /// rules can be exercised in isolation.
  void seedEstablishedUser(
      {int shownCount = 0, Map<String, Object> extra = const {}}) {
    SharedPreferences.setMockInitialValues({
      firstVisitHintSessionOrdinalBaseKey: 4,
      firstVisitHintShownCountBaseKey: shownCount,
      ...extra,
    });
  }

  setUp(() {
    FirstVisitHintService.debugResetSession();
    FirstVisitHintService.debugUserIdResolver = () => null;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    FirstVisitHintService.debugUserIdResolver = () => null;
  });

  group('once ever', () {
    test('a claimed hint never comes back, even in a later session', () async {
      seedEstablishedUser();

      expect(await service.claim(FirstVisitHintId.reflect), isTrue);

      FirstVisitHintService.debugResetSession(); // next app launch
      expect(await service.claim(FirstVisitHintId.reflect), isFalse);

      FirstVisitHintService.debugResetSession();
      expect(await service.claim(FirstVisitHintId.reflect), isFalse);
    });

    test('claiming one hint does not spend another', () async {
      seedEstablishedUser();

      expect(await service.claim(FirstVisitHintId.reflect), isTrue);
      FirstVisitHintService.debugResetSession();
      expect(await service.claim(FirstVisitHintId.companion), isTrue);
    });
  });

  group('guardrail: max one hint per session', () {
    test('a second surface in the same session gets nothing', () async {
      seedEstablishedUser();

      expect(await service.claim(FirstVisitHintId.reflect), isTrue);
      expect(await service.claim(FirstVisitHintId.companion), isFalse);
      expect(await service.claim(FirstVisitHintId.noor), isFalse);
    });

    test('a hint refused by the session latch is NOT spent', () async {
      seedEstablishedUser();

      await service.claim(FirstVisitHintId.reflect);
      expect(await service.claim(FirstVisitHintId.companion), isFalse);

      FirstVisitHintService.debugResetSession();
      expect(await service.claim(FirstVisitHintId.companion), isTrue);
    });

    test('concurrent claims cannot both win the session', () async {
      seedEstablishedUser();

      final results = await Future.wait([
        service.claim(FirstVisitHintId.reflect),
        service.claim(FirstVisitHintId.companion),
        service.claim(FirstVisitHintId.noor),
      ]);

      expect(results.where((won) => won), hasLength(1));
    });
  });

  group('guardrail: nothing in the first session', () {
    test('a brand-new user gets no hint on their first arrival', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await service.claim(FirstVisitHintId.reflect), isFalse);
      expect(await service.claim(FirstVisitHintId.companion), isFalse);
    });

    test('the suppressed hint is still available next session', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await service.claim(FirstVisitHintId.reflect), isFalse);

      FirstVisitHintService.debugResetSession();
      expect(await service.claim(FirstVisitHintId.reflect), isTrue);
    });

    test('the session ordinal advances once per session, not per claim',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await service.claim(FirstVisitHintId.reflect);
      await service.claim(FirstVisitHintId.companion);
      await service.claim(FirstVisitHintId.noor);
      expect(prefs.getInt(firstVisitHintSessionOrdinalBaseKey), 1);

      FirstVisitHintService.debugResetSession();
      await service.claim(FirstVisitHintId.reflect);
      expect(prefs.getInt(firstVisitHintSessionOrdinalBaseKey), 2);
    });

    test('signing in mid-session starts that user at their own session 1',
        () async {
      seedEstablishedUser(); // established *anonymous* history

      expect(await service.claim(FirstVisitHintId.reflect), isTrue);

      FirstVisitHintService.debugResetSession();
      FirstVisitHintService.debugUserIdResolver = () => 'user-a';
      expect(await service.claim(FirstVisitHintId.companion), isFalse);
    });
  });

  group('guardrail: lifetime cap', () {
    test('nothing is offered once the budget is spent', () async {
      seedEstablishedUser(shownCount: firstVisitHintLifetimeCap);

      expect(await service.claim(FirstVisitHintId.reflect), isFalse);
      FirstVisitHintService.debugResetSession();
      expect(await service.claim(FirstVisitHintId.companion), isFalse);
    });

    test('the cap binds across sessions after real claims', () async {
      seedEstablishedUser();

      for (final hint in FirstVisitHintId.values) {
        expect(await service.claim(hint), isTrue, reason: hint.name);
        FirstVisitHintService.debugResetSession();
      }

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(firstVisitHintShownCountBaseKey),
          firstVisitHintLifetimeCap);

      // A fourth surface shipping later inherits the exhausted budget rather
      // than adding a fourth interruption. Simulated by clearing one hint's
      // own flag: only the cap can be refusing it now.
      await prefs.remove(FirstVisitHintId.reflect.baseKey);
      expect(await service.claim(FirstVisitHintId.reflect), isFalse);
    });
  });

  group('per-user scoping', () {
    test('one user spending a hint does not spend it for another', () async {
      seedEstablishedUser(extra: {
        '$firstVisitHintSessionOrdinalBaseKey:user-a': 4,
        '$firstVisitHintSessionOrdinalBaseKey:user-b': 4,
      });

      FirstVisitHintService.debugUserIdResolver = () => 'user-a';
      expect(await service.claim(FirstVisitHintId.reflect), isTrue);

      FirstVisitHintService.debugResetSession();
      FirstVisitHintService.debugUserIdResolver = () => 'user-b';
      expect(await service.claim(FirstVisitHintId.reflect), isTrue);
    });

    test('scoped keys carry the :<uid> suffix sign-out clears', () async {
      seedEstablishedUser(
          extra: {'$firstVisitHintSessionOrdinalBaseKey:user-a': 4});
      FirstVisitHintService.debugUserIdResolver = () => 'user-a';

      await service.claim(FirstVisitHintId.noor);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${FirstVisitHintId.noor.baseKey}:user-a'), isTrue);
      expect(prefs.getBool(FirstVisitHintId.noor.baseKey), isNull);
    });
  });

  group('copy', () {
    test('every hint reads as a short, calm aside', () {
      for (final hint in FirstVisitHintId.values) {
        final words = hint.message
            .split(RegExp(r'\s+'))
            .where((t) => RegExp(r'[A-Za-z]').hasMatch(t));
        expect(words.length, lessThanOrEqualTo(14), reason: hint.name);
        expect(hint.message, isNot(contains('!')), reason: hint.name);
        // Latin script only: an Arabic glyph here would need its own widget
        // and text direction (CLAUDE.md critical rule).
        expect(RegExp(r'[؀-ۿ]').hasMatch(hint.message), isFalse,
            reason: hint.name);
      }
    });

    test('the three hint keys are distinct', () {
      final keys = FirstVisitHintId.values.map((h) => h.baseKey).toSet();
      expect(keys, hasLength(FirstVisitHintId.values.length));
    });
  });
}
