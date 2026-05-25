import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:sakina/widgets/referral_code_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// End-to-end pin for the previously-dead networkError branch in
/// [ReferralCodeField].
///
/// Before the 2026-05-25 polish PR, `ReferralService.validateCode` caught
/// every RPC failure and returned `false`, which meant the field always
/// resolved to `invalid` — the field's own `catch (_) → networkError`
/// branch was unreachable dead code.
///
/// The polish PR flips `validateCode` to **rethrow** on RPC failure so the
/// field can distinguish "server said no" (invalid) from "we couldn't reach
/// the server" (networkError) and render different copy in each case.
///
/// This test pins the integration end-to-end:
///   * A fake [SupabaseClient] whose `.rpc()` throws.
///   * The REAL (un-overridden) [ReferralService.validateCode] is exercised.
///   * The throw must bubble up through validateCode → into the field's
///     `_settle` catch block → flip state to `networkError` → render the
///     "Couldn't check right now…" chip.
///
/// If a future regression re-introduces a swallow inside `validateCode`,
/// or removes the field's catch, this test fails and the dead-code revival
/// is reverted silently no more.
void main() {
  group('ReferralCodeField · networkError (end-to-end pin)', () {
    test(
      'validateCode rethrows when the underlying supabase rpc throws '
      '(direct service-layer pin)',
      () async {
        // Direct unit-test of the rethrow contract. If a future refactor
        // re-wraps validateCode in a try/return-false, this fails before
        // the widget test even runs — giving a clean, targeted signal.
        final svc = ReferralService(_ThrowingSupabase());
        expect(
          () => svc.validateCode('NETWRKCD'),
          throwsA(isA<Exception>()),
        );
      },
    );

    testWidgets(
      'end-to-end: thrown rpc bubbles through real validateCode and renders '
      'networkError chip',
      (tester) async {
        final realService = ReferralService(_ThrowingSupabase());
        final rec = <(String, ReferralCodeValidationState)>[];

        await tester.pumpWidget(ProviderScope(
          overrides: [
            // Override with the REAL service wrapping a throwing supabase —
            // no validateCode override on the service itself. This proves
            // the chain end-to-end.
            referralServiceProvider.overrideWithValue(realService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReferralCodeField(
                onCodeChanged: (code, state) => rec.add((code, state)),
              ),
            ),
          ),
        ));

        // Type an 8-char code that survives the [A-HJ-NP-Z2-9] formatter.
        await tester.enterText(find.byType(TextField), 'NETWRKCD');
        // Cross the 300ms debounce.
        await tester.pump(const Duration(milliseconds: 350));
        // Let the awaited validateCode microtask (the throw) settle.
        await tester.pumpAndSettle();

        // Chip copy from ReferralCodeField._buildChip() networkError case.
        expect(
          find.text("Couldn't check right now — we'll verify when you sign up."),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

        // And the callback observed the networkError settled state.
        expect(rec.last.$2, ReferralCodeValidationState.networkError);
      },
    );
  });
}

/// Minimal [SupabaseClient] stand-in that throws synchronously from `rpc()`.
/// Because `validateCode` does `await _supabase.rpc(...)`, a synchronous
/// throw from `rpc()` propagates through the await just like a Future
/// rejection — both surfaces hit the same catch in `_settle`.
///
/// We deliberately do NOT subclass or override [ReferralService.validateCode]
/// — this test's whole point is to prove the rethrow chain through the real
/// service code.
class _ThrowingSupabase extends Fake implements SupabaseClient {
  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    dynamic get = false,
  }) {
    throw Exception('boom from fake supabase.rpc($fn)');
  }
}
