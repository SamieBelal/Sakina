// Regression for finding 2026-04-26-journal-no-error-toast.
// Verifies that ProviderErrorSnackBarListener (used by journal_screen.dart to
// surface optimistic-rollback errors from reflectProvider and duasProvider)
// renders a SnackBar when state.error transitions to a new non-null value,
// and that it does NOT re-fire on rebuilds with the same error or on null.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/provider_error_listener.dart';

class _FakeState {
  final String? error;
  const _FakeState({this.error});
}

void main() {
  Future<void> pumpListener(
    WidgetTester tester,
    StateProvider<_FakeState> provider,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProviderErrorSnackBarListener<_FakeState>(
              provider: provider,
              errorOf: (s) => s.error,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows SnackBar when error transitions to non-null',
      (tester) async {
    final provider = StateProvider<_FakeState>((_) => const _FakeState());
    await pumpListener(tester, provider);

    expect(find.byType(SnackBar), findsNothing,
        reason: 'no toast on initial null error');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    container.read(provider.notifier).state =
        const _FakeState(error: "Couldn't delete the reflection.");
    await tester.pump();

    expect(find.text("Couldn't delete the reflection."), findsOneWidget);
  });

  testWidgets('does NOT re-fire SnackBar when error stays the same',
      (tester) async {
    final provider = StateProvider<_FakeState>((_) => const _FakeState());
    await pumpListener(tester, provider);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );

    // null → 'first' transitions, fires once.
    container.read(provider.notifier).state =
        const _FakeState(error: 'first error');
    await tester.pump();
    expect(find.text('first error'), findsOneWidget);

    // Re-emit the same error string. Riverpod still notifies, but the guard
    // err == prevErr should suppress a second toast.
    container.read(provider.notifier).state =
        const _FakeState(error: 'first error');
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'identical error must not stack a second toast');
  });

  testWidgets('hides previous SnackBar before showing new one',
      (tester) async {
    final provider = StateProvider<_FakeState>((_) => const _FakeState());
    await pumpListener(tester, provider);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );

    container.read(provider.notifier).state =
        const _FakeState(error: 'first');
    await tester.pump();
    expect(find.text('first'), findsOneWidget);

    container.read(provider.notifier).state =
        const _FakeState(error: 'second');
    await tester.pump();

    expect(find.text('first'), findsNothing,
        reason: 'previous toast must be hidden when new one shows');
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('does not show SnackBar when error transitions to null',
      (tester) async {
    final provider = StateProvider<_FakeState>((_) => const _FakeState());
    await pumpListener(tester, provider);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    container.read(provider.notifier).state =
        const _FakeState(error: 'first');
    await tester.pump();
    expect(find.text('first'), findsOneWidget);

    // Error clears (e.g. provider resets after a successful retry).
    container.read(provider.notifier).state = const _FakeState();
    await tester.pump();

    // Listener guard returns early on null next.error — should NOT enqueue a
    // new snackbar. The original 'first' may still be visible until it
    // auto-dismisses; we just need to confirm no SECOND snackbar piled on.
    expect(find.byType(SnackBar).evaluate().length, lessThanOrEqualTo(1),
        reason: 'null error must not enqueue a fresh snackbar');
  });
}
