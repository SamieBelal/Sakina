import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Pins the `engageCard` analytics chokepoint (retention audit 2026-06-01).
/// Exactly one engagement event fires per call so Mixpanel counts stay clean:
/// new discovery → card_revealed; owned-card upgrade → tier_up; duplicate → none.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late List<(String, Map<String, dynamic>)> events;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    events = [];
    CardCollectionAnalytics.onAnalyticsEvent =
        (event, props) => events.add((event, props));
  });

  tearDown(() {
    CardCollectionAnalytics.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
  });

  Iterable<(String, Map<String, dynamic>)> of(String name) =>
      events.where((e) => e.$1 == name);

  test(
      'REGRESSION: a throwing analytics hook does NOT propagate out of engageCard',
      () async {
    // The grant is persisted BEFORE the emit. If a throwing hook escaped
    // engageCard, discoverName's catch would set state.error and
    // discoverNameWithBypass would REFUND the bypass while the card is already
    // granted (free card). The emits are wrapped to prevent exactly this.
    CardCollectionAnalytics.onAnalyticsEvent = (_, __) => throw StateError('boom');

    // Must complete normally (no throw).
    final result = await engageCard(7);
    expect(result.isNew, isTrue);

    // And the card is durably granted despite the throwing hook.
    final collection = await getCardCollection();
    expect(collection.discoveredIds, contains(7));
  });

  test('first discovery fires card_revealed{tier:bronze, is_new:true} only',
      () async {
    await engageCard(5);

    final revealed = of(AnalyticsEvents.cardRevealed).toList();
    expect(revealed.length, 1);
    expect(revealed.first.$2['name_id'], 5);
    expect(revealed.first.$2['tier'], 'bronze');
    expect(revealed.first.$2['is_new'], true);
    expect(of(AnalyticsEvents.tierUp), isEmpty,
        reason: 'a fresh discovery is not a tier-up');
  });

  test('re-engagement fires tier_up{bronze→silver} and NOT card_revealed',
      () async {
    await engageCard(5); // bronze
    events.clear();

    await engageCard(5); // silver

    final tierUps = of(AnalyticsEvents.tierUp).toList();
    expect(tierUps.length, 1);
    expect(tierUps.first.$2['name_id'], 5);
    expect(tierUps.first.$2['from_tier'], 'bronze');
    expect(tierUps.first.$2['to_tier'], 'silver');
    expect(of(AnalyticsEvents.cardRevealed), isEmpty);
  });

  test('Gold is the ceiling: a duplicate engage emits nothing', () async {
    await engageCard(5); // bronze
    await engageCard(5); // silver
    await engageCard(5); // gold
    events.clear();

    await engageCard(5); // already gold → duplicate

    expect(events, isEmpty,
        reason: 'engageCard caps at Gold; a duplicate must not emit');
  });

  test('collection_completed fires once, on the discovery that completes the set',
      () async {
    final ids = allCollectibleNames.map((c) => c.id).toSet().toList();
    expect(ids.length, greaterThan(1));

    for (final id in ids.take(ids.length - 1)) {
      await engageCard(id);
    }
    expect(of(AnalyticsEvents.collectionCompleted), isEmpty,
        reason: 'set is not complete until the final new discovery');
    events.clear();

    await engageCard(ids.last);

    final completed = of(AnalyticsEvents.collectionCompleted).toList();
    expect(completed.length, 1);
    expect(completed.first.$2['total'], ids.length);
  });
}
