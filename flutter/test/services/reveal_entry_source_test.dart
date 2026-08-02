import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/reveal_entry_source.dart';

/// Pins `lib/services/reveal_entry_source.dart` (W6 Wave B / W3 §9): the
/// process-global `(source, timestamp)` stamp that lets `second_name_unsealed`
/// attribute a reveal to the widget or a push, within a ~10-minute TTL.
///
/// **MUTATION THAT MUST FAIL THIS TEST:** make [consumeRevealEntrySource]
/// non-clearing (drop the `_source = null; _stampedAtUtc = null;` reset). A
/// stale widget stamp would then attribute a later, genuinely organic unseal
/// to the widget — inflating exactly the surface a founder would then
/// over-invest in. Verified by hand: with the clear removed, the second
/// 'no stamp left' test below fails (`consumeRevealEntrySource()` still
/// returns `'widget'` instead of `'organic'`).
void main() {
  setUp(debugResetRevealEntrySource);
  tearDown(debugResetRevealEntrySource);

  test('an unstamped read is organic', () {
    expect(consumeRevealEntrySource(), AnalyticsEvents.revealSourceOrganic);
  });

  test('a fresh stamp is returned as-is', () {
    debugRevealEntrySourceClock = () => DateTime.utc(2026, 8, 4, 12, 0);
    stampRevealEntrySource(AnalyticsEvents.revealSourceWidget);
    debugRevealEntrySourceClock = () => DateTime.utc(2026, 8, 4, 12, 5);

    expect(consumeRevealEntrySource(), AnalyticsEvents.revealSourceWidget);
  });

  test('a stamp older than the TTL degrades to organic', () {
    debugRevealEntrySourceClock = () => DateTime.utc(2026, 8, 4, 12, 0);
    stampRevealEntrySource(AnalyticsEvents.revealSourcePush);
    // 10 minutes 1 second later — just past the TTL.
    debugRevealEntrySourceClock =
        () => DateTime.utc(2026, 8, 4, 12, 10, 1);

    expect(consumeRevealEntrySource(), AnalyticsEvents.revealSourceOrganic);
  });

  test('a stamp exactly at the TTL boundary is still honoured', () {
    debugRevealEntrySourceClock = () => DateTime.utc(2026, 8, 4, 12, 0);
    stampRevealEntrySource(AnalyticsEvents.revealSourceWidget);
    debugRevealEntrySourceClock = () => DateTime.utc(2026, 8, 4, 12, 10);

    expect(consumeRevealEntrySource(), AnalyticsEvents.revealSourceWidget);
  });

  test('the read CLEARS the stamp — a second read is organic', () {
    debugRevealEntrySourceClock = () => DateTime.utc(2026, 8, 4, 12, 0);
    stampRevealEntrySource(AnalyticsEvents.revealSourceWidget);

    expect(consumeRevealEntrySource(), AnalyticsEvents.revealSourceWidget);
    // A later, genuinely organic reveal must not inherit the first's stamp.
    expect(consumeRevealEntrySource(), AnalyticsEvents.revealSourceOrganic);
  });

  test('a later stamp overwrites an earlier, unconsumed one', () {
    debugRevealEntrySourceClock = () => DateTime.utc(2026, 8, 4, 12, 0);
    stampRevealEntrySource(AnalyticsEvents.revealSourceWidget);
    stampRevealEntrySource(AnalyticsEvents.revealSourcePush);

    expect(consumeRevealEntrySource(), AnalyticsEvents.revealSourcePush);
  });
}
