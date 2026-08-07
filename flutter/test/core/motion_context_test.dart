import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/motion_context.dart';

/// The stagger clamp, and the reduced-motion path the journal never had.
///
/// The defect being pinned: `journal_screen.dart` staggered with a raw
/// `index * 50ms` and **no ceiling**, from three call sites, passing the list
/// index. Item 20 waited 950ms, item 40 waited 1,950ms, item 100 waited
/// 4,950ms. In a `ListView.builder` the delay keys off the LIST index rather
/// than when the item was built, so scrolling fast into a long journal showed
/// blank cards fading in seconds later — getting worse the longer someone had
/// been journaling, which is exactly backwards.
void main() {
  Future<BuildContext> contextWith(WidgetTester tester,
      {required bool reduce}) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Builder(builder: (c) {
          captured = c;
          return const SizedBox.shrink();
        }),
      ),
    );
    return captured;
  }

  group('stagger', () {
    testWidgets('is clamped, so a long journal cannot stall', (tester) async {
      final c = await contextWith(tester, reduce: false);

      // Ramps for the first handful, exactly as before.
      expect(c.stagger(0), Duration.zero);
      expect(c.stagger(3), AppMotion.stagger * 3);

      // Then stops. These are the numbers that were broken.
      expect(c.stagger(6), AppMotion.stagger * 6);
      expect(c.stagger(20), AppMotion.stagger * 6);
      expect(c.stagger(40), AppMotion.stagger * 6);
      expect(c.stagger(100), AppMotion.stagger * 6);
    });

    testWidgets('the whole reveal settles inside AppMotion\'s own ceiling',
        (tester) async {
      final c = await contextWith(tester, reduce: false);
      // AppMotion's doc: "a staggered reveal should settle inside ~800-900ms".
      // Worst case is the last delay plus one item duration.
      final worst = c.stagger(999) + AppMotion.item;
      expect(worst.inMilliseconds, lessThanOrEqualTo(900),
          reason: 'was 4,950ms + 300ms at index 100 before the clamp');
    });

    testWidgets('is zero under reduced motion — delay with no movement is '
        'just waiting', (tester) async {
      final c = await contextWith(tester, reduce: true);
      for (final i in [0, 3, 6, 40]) {
        expect(c.stagger(i), Duration.zero, reason: 'index $i');
      }
    });

    testWidgets('a negative index cannot produce a negative delay',
        (tester) async {
      final c = await contextWith(tester, reduce: false);
      expect(c.stagger(-1), Duration.zero);
    });
  });

  group('motion and rise', () {
    testWidgets('pass through untouched when animations are allowed',
        (tester) async {
      final c = await contextWith(tester, reduce: false);
      expect(c.motion(AppMotion.entrance), AppMotion.entrance);
      expect(c.rise(AppMotion.riseLarge), AppMotion.riseLarge);
    });

    testWidgets('collapse under reduced motion — less movement, never less '
        'content', (tester) async {
      final c = await contextWith(tester, reduce: true);
      expect(c.motion(AppMotion.entrance), AppMotion.collapsed);
      // Translation is the part that causes vestibular trouble; the fade stays,
      // so the element still announces itself.
      expect(c.rise(AppMotion.riseLarge), 0);
    });

    testWidgets('collapsed is one frame, not zero', (tester) async {
      // flutter_animate treats a zero-duration effect as a degenerate case in
      // places; 1ms is already imperceptible.
      expect(AppMotion.collapsed, const Duration(milliseconds: 1));
      expect(AppMotion.collapsed, isNot(Duration.zero));
    });
  });

  testWidgets('no MediaQuery ancestor defaults to "animations are fine"',
      (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(Builder(builder: (c) {
      captured = c;
      return const SizedBox.shrink();
    }));
    expect(captured.reduceMotion, isFalse);
    expect(captured.motion(AppMotion.entrance), AppMotion.entrance);
  });
}
