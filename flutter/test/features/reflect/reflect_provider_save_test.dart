// P2-5 (ENG-REVIEW Finding 2): pin the reorder in `_saveReflection` so the
// Supabase `insertRow` happens BEFORE the local state mutation. With the new
// length + shape CHECKs from migration 20260526000000, a rejected insert
// throws — but the user must NOT see a "saved" reflection in the UI that
// doesn't exist server-side. The local list should stay clean on reject.
//
// See docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md (P2-5).

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
  });
}
