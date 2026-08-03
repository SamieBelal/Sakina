// P2-5 (ENG-REVIEW Finding 2): pin the reorder in `_saveReflection` so the
// Supabase `insertRow` happens BEFORE the local state mutation. With the new
// length + shape CHECKs from migration 20260526000000, a rejected insert
// throws — but the user must NOT see a "saved" reflection in the UI that
// doesn't exist server-side. The local list should stay clean on reject.
//
// See docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md (P2-5).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

class _RejectingInsertSync extends FakeSupabaseSyncService {
  _RejectingInsertSync({required super.userId});

  @override
  Future<bool> insertRow(String table, Map<String, dynamic> data) async {
    if (table == 'user_reflections') {
      // Simulate the new CHECK constraint rejecting the insert.
      throw Exception(
          'new row for relation "user_reflections" violates check '
          'constraint "user_reflections_text_length_caps"');
    }
    return super.insertRow(table, data);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedNow = DateTime.parse('2026-05-26T12:00:00Z');

  ai.ReflectResponse successResponse() => const ai.ReflectResponse(
        name: 'As-Salam',
        nameArabic: 'السلام',
        reframe: 'Steady ground.',
        story: 'A short story.',
        verses: [
          ReflectVerse(
            arabic: 'بسم الله',
            translation: 'In the name of Allah',
            reference: 'Quran 1:1',
          ),
        ],
        duaArabic: 'دعاء',
        duaTransliteration: 'dua',
        duaTranslation: 'supplication',
        duaSource: 'source',
        relatedNames: [],
        offTopic: false,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(SupabaseSyncService.debugReset);

  test(
      '_saveReflection does NOT update local state when server insert throws',
      () async {
    SupabaseSyncService.debugSetInstance(
      _RejectingInsertSync(userId: 'user-p2-5'),
    );
    // Latch had_trial AFTER the fake sync service is installed so the
    // gating service's underlying prefs write doesn't try to hit a real
    // Supabase instance.
    await GatingService().debugSetHadTrial(true);

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'r-rejected',
      ),
    );
    addTearDown(notifier.dispose);

    expect(notifier.state.savedReflections, isEmpty,
        reason: 'precondition: no reflections cached yet');

    notifier.setUserText('I feel anxious');
    await notifier.submit();

    // The server rejected the insert. _saveReflection rethrows, which the
    // outer _reflect catches and surfaces as an error string. Critical
    // assertion: state.savedReflections stays clean — no phantom row.
    expect(notifier.state.savedReflections, isEmpty,
        reason: 'rejected server insert MUST leave local state clean — '
            'reorder ensures the local mutation happens AFTER the await');

    // Also verify the local SharedPreferences cache wasn't written with a
    // phantom row (would surface on next launch).
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('saved_reflections:user-p2-5'), isNull,
        reason: 'no row should have been persisted locally either');
  });

  test('a saved reflection emits journal_entry_created{reflection}', () async {
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-journal'),
    );
    await GatingService().debugSetHadTrial(true);

    final events = <({String name, Map<String, dynamic> props})>[];
    ReflectNotifier.onAnalyticsEvent =
        (e, p) => events.add((name: e, props: p));
    addTearDown(() => ReflectNotifier.onAnalyticsEvent = null);

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'r-journal',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel anxious');
    await notifier.submit();

    expect(notifier.state.savedReflections, hasLength(1),
        reason: 'precondition: the reflection actually saved');
    final journal = events
        .where((e) => e.name == AnalyticsEvents.journalEntryCreated)
        .toList();
    expect(journal, hasLength(1));
    expect(journal.single.props[AnalyticsEvents.propEntryType],
        AnalyticsEvents.entryTypeReflection);
    expect(journal.single.props[AnalyticsEvents.propAuto], false);
    // Wave H. The muḥāsabah now writes into this same table and fires this same
    // event, so without `source` the two are one undifferentiated number — and
    // a Reflect save and a night are not the same act. Property, not a second
    // event name: forking it would split every historical journal chart at T0.
    expect(journal.single.props[AnalyticsEvents.propSource],
        AnalyticsEvents.journalSourceReflect);

    // And the user's words are not in the payload. `setUserText` put them on
    // state one line before the emit, which is exactly the shape of the two
    // violations `no_free_text_reaches_analytics_test` was written for.
    expect('${journal.single.props}'.contains('anxious'), isFalse);
  });

  // The 5-entry free-tier save cap was removed 2026-08-02 (design §9A). The
  // weekly allowance pool is spent at GENERATION time — `markUsed` runs before
  // `_saveReflection` — so a second ration on KEEPING the reflection only
  // destroyed output the user had already paid for. These cases pin that a
  // free (non-premium) user keeps accumulating well past the old ceiling.
  for (final existing in [5, 9, 49]) {
    test(
        'a free user with $existing saved reflections saves the '
        '${existing + 1}th', () async {
      final seeded = List.generate(
        existing,
        (i) => SavedReflection(
          id: 'r-$i',
          date: fixedNow.toIso8601String(),
          userText: 'text-$i',
          name: 'As-Salam',
          nameArabic: 'السلام',
          reframePreview: 'preview-$i',
        ).toJson(),
      );
      SharedPreferences.setMockInitialValues({
        'saved_reflections:user-uncapped': jsonEncode(seeded),
      });

      SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-uncapped'),
      );
      await GatingService().debugSetHadTrial(true);

      // loadOnInit: true so the seeded cache hydrates into state, exactly as
      // it would for a returning free user with a full journal.
      final notifier = ReflectNotifier(
        dependencies: ReflectDependencies(
          getFollowUpQuestions: (_) async => const [],
          reflect: (_) async => successResponse(),
          now: () => fixedNow,
          createId: () => 'r-next',
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.savedReflections, hasLength(existing),
          reason: 'precondition: the seeded journal hydrated');

      notifier.setUserText('I feel anxious');
      await notifier.submit();

      expect(
        notifier.state.savedReflections,
        hasLength(existing + 1),
        reason: 'no free-tier row cap: the save must land',
      );
      // Reflections are stored newest-first.
      expect(notifier.state.savedReflections.first.id, 'r-next');

      final prefs = await SharedPreferences.getInstance();
      final persisted = jsonDecode(
        prefs.getString('saved_reflections:user-uncapped')!,
      ) as List<dynamic>;
      expect(persisted, hasLength(existing + 1),
          reason: 'the new reflection must survive a relaunch too');
    });
  }
}
