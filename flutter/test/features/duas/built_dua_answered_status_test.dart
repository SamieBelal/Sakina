// Wave E, E3 — the answered-duʿā status transition.
//
// This is the only WRITE Wave E adds, and it writes to a table with a server
// CHECK that constrains two columns together
// (`user_built_duas_answered_at_agrees`: status='answered' iff answered_at is
// not null). A client that moves one and not the other produces a row the
// server refuses — with no exception, because `upsertRawRow` swallows and
// returns false — so the local row and the server row diverge silently and the
// next sync reverts the mark with no explanation.
//
// Every test here is about that pair staying in step, or about what happens
// when the write is refused anyway.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService sync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sync = FakeSupabaseSyncService(userId: 'u1');
    SupabaseSyncService.debugSetInstance(sync);
  });

  tearDown(SupabaseSyncService.debugReset);

  final markedAt = DateTime.utc(2026, 8, 2, 20, 30);

  DuasNotifier notifier({List<SavedBuiltDua> duas = const []}) {
    final n = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => throw UnimplementedError(),
        buildDua: (_) async => throw UnimplementedError(),
        now: () => markedAt,
        createId: () => 'generated',
      ),
    );
    n.state = n.state.copyWith(savedBuiltDuas: duas);
    return n;
  }

  SavedBuiltDua dua({
    String id = 'd1',
    String status = builtDuaStatusOpen,
    String? answeredAt,
  }) =>
      SavedBuiltDua(
        id: id,
        savedAt: '2026-04-02T10:00:00.000Z',
        need: 'A job that lets me pray on time.',
        arabic: 'ا',
        transliteration: 't',
        translation: 'tr',
        status: status,
        answeredAt: answeredAt,
      );

  group('marking a duʿā answered', () {
    test('moves status AND answered_at together, locally and on the wire',
        () async {
      final n = notifier(duas: [dua()]);

      expect(await n.setBuiltDuaAnswered('d1', answered: true), isTrue);

      final local = n.state.savedBuiltDuas.single;
      expect(local.status, builtDuaStatusAnswered);
      expect(local.isAnswered, isTrue);
      expect(local.answeredAt, markedAt.toIso8601String());

      // The row the server actually sees. Both columns, or the CHECK refuses it.
      expect(sync.rawUpsertCalls, hasLength(1));
      final row = sync.rawUpsertCalls.single['data'] as Map<String, dynamic>;
      expect(sync.rawUpsertCalls.single['table'], 'user_built_duas');
      expect(sync.rawUpsertCalls.single['onConflict'], 'id');
      expect(row['status'], builtDuaStatusAnswered);
      expect(row['answered_at'], markedAt.toIso8601String());
      expect(row['user_id'], 'u1');
    });

    test('survives the round trip through the prefs cache', () async {
      final n = notifier(duas: [dua()]);
      await n.setBuiltDuaAnswered('d1', answered: true);

      // A cold start reads the blob back. Both fields have to be in `toJson`
      // and both parsers, or the mark evaporates on the next launch.
      final reloaded = DuasNotifier(loadOnInit: false);
      await reloaded.loadSavedDuas();
      expect(reloaded.state.savedBuiltDuas.single.status,
          builtDuaStatusAnswered);
      expect(reloaded.state.savedBuiltDuas.single.answeredAt,
          markedAt.toIso8601String());
    });

    test('the undo clears answered_at rather than leaving it stale', () async {
      // The server CHECK is an IFF. An "open" row still carrying a timestamp is
      // refused, so an undo that only flipped `status` would fail the write and
      // roll itself straight back — the button would do nothing, twice.
      final n = notifier(
        duas: [
          dua(
              status: builtDuaStatusAnswered,
              answeredAt: '2026-07-01T10:00:00.000Z')
        ],
      );

      expect(await n.setBuiltDuaAnswered('d1', answered: false), isTrue);
      expect(n.state.savedBuiltDuas.single.status, builtDuaStatusOpen);
      expect(n.state.savedBuiltDuas.single.answeredAt, isNull);

      final row = sync.rawUpsertCalls.single['data'] as Map<String, dynamic>;
      expect(row['status'], builtDuaStatusOpen);
      expect(row['answered_at'], isNull);
    });

    test('is idempotent — marking an answered duʿā answered writes nothing',
        () async {
      final n = notifier(
        duas: [
          dua(
              status: builtDuaStatusAnswered,
              answeredAt: '2026-07-01T10:00:00.000Z')
        ],
      );

      expect(await n.setBuiltDuaAnswered('d1', answered: true), isTrue);
      expect(sync.rawUpsertCalls, isEmpty);
      expect(n.state.savedBuiltDuas.single.answeredAt,
          '2026-07-01T10:00:00.000Z',
          reason: 'a re-mark must not restamp the moment — the timestamp is '
              'when they first said so');
    });

    test('an unknown id is refused, not silently accepted', () async {
      final n = notifier(duas: [dua()]);
      expect(await n.setBuiltDuaAnswered('nope', answered: true), isFalse);
      expect(sync.rawUpsertCalls, isEmpty);
    });

    test('a refused server write rolls the mark back and says so', () async {
      final n = notifier(duas: [dua()]);
      sync.nextUpsertShouldFail = true;

      expect(await n.setBuiltDuaAnswered('d1', answered: true), isFalse);
      expect(n.state.savedBuiltDuas.single.status, builtDuaStatusOpen,
          reason: 'without the rollback the local row diverges and the next '
              'batch sync reverts the mark with no explanation');
      expect(n.state.savedBuiltDuas.single.answeredAt, isNull);
      expect(n.state.error, isNotNull);

      // And the prefs cache was put back too, not just the in-memory state.
      final reloaded = DuasNotifier(loadOnInit: false);
      await reloaded.loadSavedDuas();
      expect(reloaded.state.savedBuiltDuas.single.status, builtDuaStatusOpen);
    });

    test('a signed-out user still marks it locally', () async {
      sync.userId = null;
      final n = notifier(duas: [dua()]);
      expect(await n.setBuiltDuaAnswered('d1', answered: true), isTrue);
      expect(n.state.savedBuiltDuas.single.isAnswered, isTrue);
      expect(sync.rawUpsertCalls, isEmpty);
    });

    test('marking one duʿā leaves its neighbours alone', () async {
      final n = notifier(duas: [dua(id: 'a'), dua(id: 'b'), dua(id: 'c')]);
      await n.setBuiltDuaAnswered('b', answered: true);
      expect(n.state.savedBuiltDuas.map((d) => d.isAnswered),
          [false, true, false]);
      expect(n.state.savedBuiltDuas.map((d) => d.id), ['a', 'b', 'c'],
          reason: 'order is the feed order; a mark must not reshuffle it');
    });

    test('marking answered writes no economy and no analytics', () async {
      // A user recording that Allah answered them is not a metric. The moment
      // it earns something it stops being that and starts being a thing to farm.
      final events = <String>[];
      DuasNotifier.onAnalyticsEvent = (event, _) => events.add(event);
      addTearDown(() => DuasNotifier.onAnalyticsEvent = null);

      final n = notifier(duas: [dua()]);
      await n.setBuiltDuaAnswered('d1', answered: true);

      expect(events, isEmpty);
      expect(sync.rpcCalls, isEmpty,
          reason: 'no sync_all_user_data, no award, no counter');
      expect(sync.rawUpsertCalls.single['table'], 'user_built_duas',
          reason: 'the only write is the duʿā row itself');
    });
  });

  group('"Not yet"', () {
    test('snoozes locally, changes nothing about the duʿā, and expires',
        () async {
      final n = notifier(duas: [dua()]);

      await n.snoozeAnsweredDuaPrompt('d1');

      expect(n.state.savedBuiltDuas.single.status, builtDuaStatusOpen,
          reason: 'a dismissal is a fact about this moment, not about the duʿā');
      expect(sync.rawUpsertCalls, isEmpty);
      expect(sync.insertCalls, isEmpty);

      final until = n.state.answeredPromptSnoozedUntil['d1']!;
      expect(until, markedAt.add(answeredDuaSnoozeDuration));

      // And the prompt honours it.
      expect(
        selectAnsweredDuaPrompt(
          duas: n.state.savedBuiltDuas,
          now: markedAt,
          snoozedUntil: n.state.answeredPromptSnoozedUntil,
        ),
        isNull,
      );
    });

    test('survives a restart, and expired entries are pruned on read',
        () async {
      final n = notifier(duas: [dua(id: 'live'), dua(id: 'dead')]);
      await n.snoozeAnsweredDuaPrompt('live');
      // A snooze that has already run out.
      await n.snoozeAnsweredDuaPrompt(
        'dead',
        now: markedAt.subtract(const Duration(days: 400)),
      );

      final reloaded = DuasNotifier(
        loadOnInit: false,
        dependencies: DuasDependencies(
          findDuas: (_) async => throw UnimplementedError(),
          buildDua: (_) async => throw UnimplementedError(),
          now: () => markedAt,
          createId: () => 'generated',
        ),
      );
      await reloaded.loadSavedDuas();

      expect(reloaded.state.answeredPromptSnoozedUntil.keys, ['live'],
          reason: 'an expired snooze is already inert; keeping it would grow '
              'the blob by one key per dismissal forever');
    });
  });

  group('the row shape', () {
    test('a pre-Wave-E cache blob reads back as an open duʿā', () {
      final legacy = SavedBuiltDua.fromJson(const {
        'id': 'd1',
        'savedAt': '2026-04-02T10:00:00.000Z',
        'need': 'n',
        'arabic': 'a',
        'transliteration': 't',
        'translation': 'tr',
      });
      expect(legacy.status, builtDuaStatusOpen);
      expect(legacy.answeredAt, isNull);
      expect(legacy.isAnswered, isFalse);
    });

    test('a server row from before the migration reads back as open', () {
      final legacy = SavedBuiltDua.fromSupabaseRow(const {
        'id': 'd1',
        'saved_at': '2026-04-02T10:00:00.000Z',
        'need': 'n',
        'arabic': 'a',
        'transliteration': 't',
        'translation': 'tr',
      });
      expect(legacy.status, builtDuaStatusOpen);
      expect(legacy.answeredAt, isNull);
    });

    test('sync_all_user_data\'s two new keys round-trip', () {
      // The shape the Wave E migration adds to the `built_duas` union.
      final fromSync = SavedBuiltDua.fromSupabaseRow(const {
        'id': 'd1',
        'saved_at': '2026-04-02T10:00:00.000Z',
        'need': 'n',
        'arabic': 'a',
        'transliteration': 't',
        'translation': 'tr',
        'status': 'answered',
        'answered_at': '2026-08-02T20:30:00.000Z',
      });
      expect(fromSync.isAnswered, isTrue);
      expect(fromSync.answeredAt, '2026-08-02T20:30:00.000Z');
      expect(SavedBuiltDua.fromJson(fromSync.toJson()).answeredAt,
          fromSync.answeredAt);
    });
  });
}
