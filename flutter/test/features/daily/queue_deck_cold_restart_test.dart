import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Pins that a D1 deck reveal survives the app being killed mid-flow.
///
/// `_loadTodayState` restores `checkinDone`, so `discoverName` never re-runs
/// after a cold restart — which meant `revealDeck` (in-memory) came back null and
/// the user resumed on the AI reflection. That is the one reveal the W3 plan
/// promises has no OpenAI dependency (§4), on the most important comeback day in
/// the funnel, and the restart is entirely ordinary: a phone call, a swipe-away,
/// iOS reclaiming memory between the card landing and "Ameen".
///
/// **How "no AI call" is asserted** (technique inherited from
/// `queue_deck_reveal_test.dart`): `reflectWithOpenAI` has no injection seam, but
/// it writes to `reflect_classifier_log` in debug builds *before* it can return,
/// so an insert on that table is a faithful witness that the AI seam was
/// entered. Absence of the row is absence of the call.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Al-Wakeel — queue position 2 of the `anxiety` pair, and one of the 14
  /// approved decks. Real shipped content on purpose: a fixture would paper over
  /// the wave's actual claim.
  const deckedNameId = 35;
  const deckedDeckId = 'al-wakeel@1';

  final stories = NameStoriesService(
    loadAsset: (_) async =>
        File(NameStoriesService.assetPath).readAsStringSync(),
  );

  late FakeSupabaseSyncService fakeSync;

  /// The persisted blob as `_persistTodayState` writes it, at the exact moment
  /// the reveal has landed and the deck has not been tapped through yet.
  Map<String, Object> midFlowBlob({
    required String revealSource,
    int? revealNameId = deckedNameId,
  }) {
    final key =
        FakeSupabaseSyncService(userId: 'user-A').scopedKey('daily_loop_2026-08-04');
    return {
      key: jsonEncode({
        'checkinDone': true,
        'deeperDone': false,
        'questDone': false,
        'currentStep': 0,
        'checkinAnswers': const <String>[],
        'checkinName': 'Al-Wakeel',
        'reflectStep': 0,
        'revealSource': revealSource,
        'revealQueuePosition': 2,
        'revealNameId': revealNameId,
      }),
    };
  }

  bool aiCallHappened() =>
      fakeSync.insertCalls.any((c) => c['table'] == 'reflect_classifier_log');

  void install(Map<String, Object> prefs) {
    SharedPreferences.setMockInitialValues(prefs);
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugDailyLoopClock = () => DateTime.utc(2026, 8, 4, 3, 0);
  }

  tearDown(() {
    SupabaseSyncService.debugReset();
    debugDailyLoopClock = () => DateTime.now().toUtc();
  });

  /// Constructs the notifier and lets `_initialize` (and the awaited
  /// `_loadTodayState` inside it) settle.
  Future<DailyLoopNotifier> restart() async {
    final notifier = DailyLoopNotifier(storiesService: stories);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return notifier;
  }

  test('a queue reveal resumes on the authored deck, with no AI call', () async {
    install(midFlowBlob(revealSource: revealSourceQueue));

    final notifier = await restart();

    expect(notifier.state.revealDeck, isNotNull,
        reason: 'the deck is re-resolved from the bundle on restore');
    expect(notifier.state.revealDeck!.deckId, deckedDeckId);
    expect(notifier.state.revealSource, revealSourceQueue);
    expect(notifier.state.revealQueuePosition, 2);
    expect(aiCallHappened(), isFalse,
        reason: 'a restored deck reveal must still spend no OpenAI call — that '
            'is the guarantee the persistence exists to keep');
  });

  test('a gacha reveal resumes exactly as it does today', () async {
    // Same Name — one that HAS a deck — but reached by the ordinary pull. The
    // deck must not leak into the legacy path on restore any more than it does
    // on the live reveal.
    install(midFlowBlob(revealSource: revealSourceGacha));

    final notifier = await restart();

    expect(notifier.state.revealDeck, isNull);
    expect(notifier.state.revealSource, revealSourceGacha);
    expect(aiCallHappened(), isTrue,
        reason: 'the legacy path still prefetches the reflection');
  });

  test('a blob written before this change degrades to the AI reflection',
      () async {
    // Forward-compatibility: a user mid-flow across the release upgrade has a
    // blob with no reveal keys at all. It must resume, not throw.
    install(midFlowBlob(revealSource: revealSourceGacha, revealNameId: null));

    final notifier = await restart();

    expect(notifier.state.revealDeck, isNull);
    expect(notifier.state.checkinDone, isTrue,
        reason: 'the rest of the restore is unaffected');
  });
}
