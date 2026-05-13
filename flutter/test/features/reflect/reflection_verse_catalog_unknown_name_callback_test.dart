import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/data/reflection_verse_catalog.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';

void main() {
  group('normalizeApprovedVerses onFallback callback', () {
    test('fires once when Name is not in approved catalog', () {
      var firedCount = 0;
      String? firedWithName;

      final result = normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[],
        onFallback: (name) {
          firedCount++;
          firedWithName = name;
        },
      );

      expect(result.length, 2, reason: 'fallback still returns 2 safe verses');
      expect(firedCount, 1);
      expect(firedWithName, 'Al-FabricatedName');
    });

    test('does NOT fire when Name has approved verses in catalog', () {
      var fired = false;

      // 'Ar-Rahman' is in approvedReflectVersesByName (see catalog file).
      // Pass empty AI verses so the function still has to do the by-name lookup.
      final result = normalizeApprovedVerses(
        'Ar-Rahman',
        const <ReflectVerse>[],
        onFallback: (_) => fired = true,
      );

      expect(fired, isFalse);
      // Also assert the happy path actually returned catalog verses. Guards
      // against a future refactor that silently removes Ar-Rahman from the
      // catalog — without this, the test could still "pass" via an empty
      // result or via the safety-net pair.
      expect(result, isNotEmpty,
          reason: 'Ar-Rahman should return canonical verses');
    });

    test('does NOT fire when AI verses themselves match approved references', () {
      var fired = false;
      // Ash-Sharh 94:5-6 is in the catalog (hardshipEaseVerse). Even with a
      // fabricated Name, an approved verse reference avoids the fallback path.
      const approvedRef = ReflectVerse(
        arabic: 'placeholder',
        translation: 'placeholder',
        reference: 'Ash-Sharh 94:5-6',
      );

      normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[approvedRef],
        onFallback: (_) => fired = true,
      );

      expect(fired, isFalse);
    });

    test('omitted callback parameter is safe (no crash)', () {
      // Existing callers (coverage tests, possible future call sites) should
      // not need to pass the callback. This guards against accidentally making
      // it required.
      final result = normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[],
      );
      expect(result.length, 2);
    });

    test('callback that throws is swallowed — reflect flow never breaks', () {
      // Defensive contract: telemetry must NEVER take down a user's reflect.
      // If a future logger throws (sync), normalizeApprovedVerses must still
      // return the safety-net pair without propagating.
      final result = normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[],
        onFallback: (_) => throw StateError('boom'),
      );
      expect(result.length, 2, reason: 'fallback verses still returned');
    });

    test('async callback that throws is also swallowed', () async {
      // Same defensive contract for async callers. The wrapper attaches
      // catchError to the returned Future so async throws can never escape
      // into the zone and crash the reflect flow.
      final result = normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[],
        onFallback: (_) async {
          await Future<void>.delayed(Duration.zero);
          throw StateError('async boom');
        },
      );
      expect(result.length, 2, reason: 'fallback verses still returned');
      // Drain the microtask queue so the async throw fires; if catchError
      // isn't attached, this would surface as an unhandled exception in the
      // test zone and fail this test.
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
  });
}
