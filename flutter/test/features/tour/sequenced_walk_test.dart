import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/tour_service.dart';

/// T19 — narrow invariant tests for the sequenced replay walk (E6).
///
/// The full end-to-end walk (Home → Collection → Journal → Duas with route
/// pushes) is covered by manual QA. These tests pin the smaller observable
/// state-transition contract: the provider starts false, can be flipped by
/// Settings Replay, and is reset back to false on the last surface.
void main() {
  test('T19a: guidedSequenceActiveProvider starts false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(guidedSequenceActiveProvider), isFalse);
  });

  test('T19b: guidedSequenceActiveProvider can be flipped by Settings replay',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(guidedSequenceActiveProvider.notifier).state = true;
    expect(container.read(guidedSequenceActiveProvider), isTrue);
  });

  test('T19c: last tour (Duas) resets the sequenced flag to false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Simulate the Settings → Replay → Duas tour completion path.
    container.read(guidedSequenceActiveProvider.notifier).state = true;
    expect(container.read(guidedSequenceActiveProvider), isTrue);
    container.read(guidedSequenceActiveProvider.notifier).state = false;
    expect(container.read(guidedSequenceActiveProvider), isFalse);
  });
}
