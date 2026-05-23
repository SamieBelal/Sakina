import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:sakina/widgets/referral_code_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Spy fake — overrides only [validateCode]. Per-test we set
/// [nextResult] (returned by the override) or [nextThrow] (re-thrown so
/// the widget's outer try/catch sees it and emits networkError).
class _FakeReferralService extends ReferralService {
  _FakeReferralService() : super(_StubSupabase());

  bool nextResult = false;
  Object? nextThrow;
  final List<String> calls = [];

  @override
  Future<bool> validateCode(String code) async {
    calls.add(code);
    if (nextThrow != null) throw nextThrow!;
    return nextResult;
  }
}

/// Minimal SupabaseClient stand-in. Never invoked because the fake overrides
/// validateCode end-to-end; we just need a non-null reference to satisfy the
/// ReferralService constructor signature.
class _StubSupabase extends Fake implements SupabaseClient {}

/// Records every (code, state) tuple emitted by ReferralCodeField so tests
/// can assert on emission count + ordering.
class _Recorder {
  final List<(String, ReferralCodeValidationState)> events = [];
  void call(String code, ReferralCodeValidationState state) {
    events.add((code, state));
  }
}

Future<void> _pumpField(
  WidgetTester tester, {
  required _FakeReferralService fake,
  required _Recorder recorder,
  bool autofocus = false,
  String? initialValue,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [referralServiceProvider.overrideWithValue(fake)],
    child: MaterialApp(
      home: Scaffold(
        body: ReferralCodeField(
          onCodeChanged: recorder.call,
          autofocus: autofocus,
          initialValue: initialValue,
        ),
      ),
    ),
  ));
}

void main() {
  group('ReferralCodeField', () {
    testWidgets('short input (<8 chars) emits tooShort after debounce, no RPC',
        (tester) async {
      final fake = _FakeReferralService();
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      await tester.enterText(find.byType(TextField), 'ABC');
      // Below debounce — nothing should have fired yet.
      expect(rec.events, isEmpty);
      // Cross the debounce window.
      await tester.pump(const Duration(milliseconds: 350));

      expect(rec.events.length, 1);
      expect(rec.events.single,
          ('ABC', ReferralCodeValidationState.tooShort));
      expect(fake.calls, isEmpty, reason: 'No RPC fires below 8 chars');
    });

    testWidgets('8-char input triggers validateCode and renders valid chip',
        (tester) async {
      final fake = _FakeReferralService()..nextResult = true;
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      await tester.enterText(find.byType(TextField), 'ABCD2EFG');
      await tester.pump(const Duration(milliseconds: 350));
      // Let the awaited validateCode microtask settle.
      await tester.pumpAndSettle();

      expect(fake.calls, ['ABCD2EFG']);
      // States: validating → valid.
      expect(rec.events.last,
          ('ABCD2EFG', ReferralCodeValidationState.valid));
      expect(find.text('Valid gift code'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets(
        'rapid typing debounces to a single validateCode call (C1 regression pin)',
        (tester) async {
      final fake = _FakeReferralService()..nextResult = true;
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      // Type the first prefix, pump less than the debounce, then immediately
      // type the longer string. The first timer should be cancelled.
      await tester.enterText(find.byType(TextField), 'ABCD2EF');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'ABCD2EFG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Exactly one RPC, with the final value only.
      expect(fake.calls, ['ABCD2EFG']);
    });

    testWidgets(
        'C1 regression pin: 8 chars one-at-a-time over 600ms emits ≤ 2 settled events',
        (tester) async {
      // The whole point of the debounce is to fire onCodeChanged on settled
      // edges, not per keystroke. If a future refactor accidentally moves
      // the callback into onChanged (or removes the debounce), this test
      // catches it: 8 keystrokes would emit 8 events.
      final fake = _FakeReferralService()..nextResult = true;
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      const code = 'ABCD2EFG';
      for (var i = 0; i < code.length; i++) {
        await tester.enterText(find.byType(TextField), code.substring(0, i + 1));
        await tester.pump(const Duration(milliseconds: 75)); // < 300ms debounce
      }
      // Drain trailing debounce + validateCode microtask.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // tooShort transitions are coalesced by _setState (same-state skip),
      // and only the FINAL settled value fires onCodeChanged. Expect at
      // most 2 events: the validating transition + the final valid result.
      // Crucially NOT 8.
      expect(rec.events.length, lessThanOrEqualTo(2),
          reason: 'Debounce + same-state coalescing should suppress per-keystroke fires');
      expect(rec.events.last.$2, ReferralCodeValidationState.valid);
    });

    testWidgets('invalid code renders soft-fail chip (NOT error styling)',
        (tester) async {
      final fake = _FakeReferralService()..nextResult = false;
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      // NOTE: 'WRONGCD2' would contain 'O' which the input formatter strips
      // (charset is A-HJ-NP-Z2-9, no I/O/0/1) — leaving 7 chars, below the
      // 8-char min, so the state would be tooShort not invalid. Use a code
      // that passes the formatter so the test exercises the invalid branch.
      await tester.enterText(find.byType(TextField), 'WRNG2CD8');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text("We didn't find that code"), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);

      // Pin the soft-fail: chip text color is the tertiary muted gray,
      // NOT AppColors.error red. A future "make invalid feel like an error"
      // change would flip the color and this test would catch it.
      final chipText = tester.widget<Text>(
        find.text("We didn't find that code"),
      );
      expect(chipText.style?.color, isNot(AppColors.error));
      expect(chipText.style?.color, AppColors.textTertiaryLight);
    });

    testWidgets('thrown RPC renders networkError chip', (tester) async {
      final fake = _FakeReferralService()..nextThrow = Exception('boom');
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      await tester.enterText(find.byType(TextField), 'NETWRKCD');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't check right now — we'll verify when you sign up."),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(rec.events.last.$2, ReferralCodeValidationState.networkError);
    });

    testWidgets('lowercase input is coerced to uppercase by formatter',
        (tester) async {
      final fake = _FakeReferralService()..nextResult = true;
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      await tester.enterText(find.byType(TextField), 'abcd2efg');
      // Read the controller's text directly via the TextField widget.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'ABCD2EFG');
    });

    testWidgets('clearing the field flips state to empty IMMEDIATELY',
        (tester) async {
      final fake = _FakeReferralService()..nextResult = true;
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      // Get to valid state first.
      await tester.enterText(find.byType(TextField), 'ABCD2EFG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(rec.events.last.$2, ReferralCodeValidationState.valid);

      // Now clear. Should emit empty WITHOUT waiting 300ms.
      await tester.enterText(find.byType(TextField), '');
      // No pump beyond a single frame.
      await tester.pump();
      expect(rec.events.last, ('', ReferralCodeValidationState.empty));
    });

    testWidgets('dispose mid-debounce drops late callbacks', (tester) async {
      final fake = _FakeReferralService()..nextResult = true;
      final rec = _Recorder();
      await _pumpField(tester, fake: fake, recorder: rec);

      await tester.enterText(find.byType(TextField), 'ABCD2EFG');
      // Dispose before the 300ms debounce fires.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox.shrink());

      final countBeforeWait = rec.events.length;
      // Wait well past the debounce window. No late callbacks should fire
      // because the timer was cancelled in dispose().
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(rec.events.length, countBeforeWait);
      expect(fake.calls, isEmpty);
    });
  });
}
