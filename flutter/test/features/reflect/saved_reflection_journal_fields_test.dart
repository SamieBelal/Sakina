// The journal-entry fields (Wave B): `source`, `entryLocalDay`, `thread`, `azm`.
//
// THE BUG CLASS THIS PINS: `SavedReflection` is serialised THREE ways — the
// prefs blob (toJson/fromJson), the Supabase row (toSupabaseRow/
// fromSupabaseRow) and, in between, `copyWithBeats`, which rebuilds the whole
// object. A field added to one and forgotten in another loses data silently:
// every muḥāsabah row carries beat_data, so a `copyWithBeats` that dropped
// `source` would turn every parsed night back into an ordinary Reflect entry.
//
// It also pins the hydration path end-to-end: a row as `sync_all_user_data()`
// returns it → the local cache → back out as a `SavedReflection`.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SavedReflection tonight() => const SavedReflection(
        id: 'm1',
        date: '2026-08-02T21:40:00.000Z',
        userText: 'I snapped at my brother and I have been sitting with it.',
        name: 'Al-Halim',
        nameArabic: 'الحليم',
        reframePreview: 'Forbearance is not indifference...',
        source: reflectionSourceMuhasabah,
        entryLocalDay: '2026-08-02',
        azm: 'Tomorrow I apologise before Maghrib.',
        thread: [
          ReflectionThreadEntry(
              at: '2026-08-02T22:10:00.000Z', text: 'one more thing'),
        ],
      ).copyWithBeats(
        reframeKey: 'He did not answer your anger with His',
        reframeBody: 'Al-Halim withholds, and gives you the room to return.',
        storyTitle: 'The Bedouin in the Masjid',
        storyBeats: const ['The companions rose.', 'The Prophet ﷺ did not.'],
        storySource: 'Bukhari 220',
        takeaway: 'Forbearance is a choice made in the moment it costs most.',
      );

  test('a muhasabah entry keeps its journal fields through copyWithBeats', () {
    // copyWithBeats runs on EVERY parse of a row that carries beat_data — which
    // is every muḥāsabah row. Dropping a field here would be invisible until
    // the journal showed the night as an ordinary reflection.
    final entry = tonight();
    expect(entry.isMuhasabah, isTrue);
    expect(entry.entryLocalDay, '2026-08-02');
    expect(entry.azm, 'Tomorrow I apologise before Maghrib.');
    expect(entry.thread.single.text, 'one more thing');
  });

  test('local JSON round-trip preserves the journal fields', () {
    final restored = SavedReflection.fromJson(tonight().toJson());
    expect(restored.source, reflectionSourceMuhasabah);
    expect(restored.entryLocalDay, '2026-08-02');
    expect(restored.azm, 'Tomorrow I apologise before Maghrib.');
    expect(restored.thread, hasLength(1));
    expect(restored.thread.single.at, '2026-08-02T22:10:00.000Z');
    // And the beats are still there — the two features share one object.
    expect(restored.storyTitle, 'The Bedouin in the Masjid');
  });

  test('Supabase row round-trip preserves the journal fields', () {
    final row = tonight().toSupabaseRow('user-1');
    expect(row['source'], reflectionSourceMuhasabah);
    expect(row['entry_local_day'], '2026-08-02');
    expect(row['azm'], 'Tomorrow I apologise before Maghrib.');
    expect(row['thread'], [
      {'at': '2026-08-02T22:10:00.000Z', 'text': 'one more thing'},
    ]);

    final restored = SavedReflection.fromSupabaseRow(row);
    expect(restored.source, reflectionSourceMuhasabah);
    expect(restored.entryLocalDay, '2026-08-02');
    expect(restored.thread.single.text, 'one more thing');
  });

  test('a legacy row parses as a reflect entry with no local day', () {
    // Rows written before the migration come back with `source` from the column
    // default; a payload from a server that has not run the migration at all
    // has no key. Both must land on 'reflect' — that is what makes "no backfill
    // needed" true.
    final legacy = SavedReflection.fromSupabaseRow({
      'id': 'r0',
      'saved_at': '2026-06-01T10:00:00.000Z',
      'user_text': 'u',
      'name': 'Al-Lateef',
      'name_arabic': 'اللطيف',
      'reframe_preview': 'p',
    });
    expect(legacy.source, reflectionSourceReflect);
    expect(legacy.isMuhasabah, isFalse);
    expect(legacy.entryLocalDay, isNull);
    expect(legacy.thread, isEmpty);
    expect(legacy.azm, '');
  });

  test('a legacy prefs blob parses as a reflect entry', () {
    final legacy = SavedReflection.fromJson({
      'id': 'r0',
      'date': '2026-06-01T10:00:00.000Z',
      'userText': 'u',
      'name': 'Al-Lateef',
      'nameArabic': 'اللطيف',
      'reframePreview': 'p',
    });
    expect(legacy.source, reflectionSourceReflect);
    expect(legacy.entryLocalDay, isNull);
  });

  test('an ordinary Reflect save carries no local day', () {
    // A Reflect entry is not a night: it is unlimited per day and must never be
    // caught by `uniq_muhasabah_per_local_day`, which only holds where the day
    // is non-null and the source is muhasabah.
    final row = buildSavedReflection(
      userText: 'I feel unseen',
      response: null,
      id: 'r1',
      date: '2026-08-02T09:00:00.000Z',
      name: 'Al-Lateef',
    ).toSupabaseRow('user-1');
    expect(row['source'], reflectionSourceReflect);
    expect(row['entry_local_day'], isNull);
    expect(row['thread'], isEmpty);
    expect(row['azm'], isNull, reason: 'an empty resolve is no resolve');
  });

  test('the row shape stays inside the server caps', () {
    final row = SavedReflection(
      id: 'm2',
      date: 'd',
      userText: 'u',
      name: 'n',
      nameArabic: 'a',
      reframePreview: 'p',
      source: reflectionSourceMuhasabah,
      entryLocalDay: '2026-08-02',
      azm: 'z' * 900,
      thread: List.generate(
        40,
        (i) => ReflectionThreadEntry(at: 'a' * 100, text: 'x' * 4000),
      ),
    ).toSupabaseRow('user-1');

    expect((row['azm'] as String).length, 500,
        reason: 'azm is capped at 500 by the server CHECK');
    final thread = row['thread'] as List;
    expect(thread, hasLength(20),
        reason: 'the server rejects more than 20 appends');
    expect((thread.first as Map)['text'].toString().length, 2048,
        reason: 'an append is capped exactly like user_text');
    expect((thread.first as Map)['at'].toString().length, 64);
    // The whitelist is the server's, not ours: any key beyond {at, text} is a
    // rejected insert, which drops the WHOLE entry.
    expect((thread.first as Map).keys.toSet(), {'at', 'text'});
  });

  test('a malformed thread element is dropped, not thrown on', () {
    // One bad element from a corrupted cache must not wipe the journal.
    final parsed = SavedReflection.fromSupabaseRow({
      'id': 'm3',
      'saved_at': 'd',
      'source': reflectionSourceMuhasabah,
      'thread': [
        'a bare string',
        {'text': 42},
        {'at': 7, 'text': 'kept, with the bad at coerced away'},
        null,
      ],
    });
    expect(parsed.thread, hasLength(1));
    expect(parsed.thread.single.at, '');
    expect(parsed.thread.single.text, 'kept, with the bad at coerced away');
  });

  test('a date-shaped entry_local_day is never widened into an instant', () {
    final parsed = SavedReflection.fromSupabaseRow({
      'id': 'm4',
      'saved_at': 'd',
      'source': reflectionSourceMuhasabah,
      'entry_local_day': '2026-08-02T00:00:00+00:00',
    });
    expect(parsed.entryLocalDay, '2026-08-02');
  });

  group('sync hydration', () {
    late FakeSupabaseSyncService fakeSync;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeSync = FakeSupabaseSyncService(userId: 'user-A');
      SupabaseSyncService.debugSetInstance(fakeSync);
    });

    tearDown(SupabaseSyncService.debugReset);

    test('a muhasabah row survives sync_all_user_data and rehydrates',
        () async {
      // The rows exactly as the RPC's `reflections` union now returns them.
      await hydrateReflectionCacheFromRows([
        {
          'id': 'm1',
          'saved_at': '2026-08-02T21:40:00.000Z',
          'user_text': 'I snapped at my brother.',
          'name': 'Al-Halim',
          'name_arabic': 'الحليم',
          'reframe_preview': 'p',
          'source': 'muhasabah',
          'entry_local_day': '2026-08-02',
          'thread': [
            {'at': '2026-08-02T22:10:00.000Z', 'text': 'one more thing'},
          ],
          'azm': 'Tomorrow I apologise before Maghrib.',
        },
        {
          'id': 'r0',
          'saved_at': '2026-06-01T10:00:00.000Z',
          'user_text': 'u',
          'name': 'Al-Lateef',
          'name_arabic': 'اللطيف',
          'reframe_preview': 'p',
          'source': 'reflect',
          'entry_local_day': null,
          'thread': [],
          'azm': null,
        },
      ]);

      final prefs = await SharedPreferences.getInstance();
      final cached = (jsonDecode(prefs.getString(
                  fakeSync.scopedKey('saved_reflections'))!) as List)
          .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(cached, hasLength(2));
      final night = cached.firstWhere((r) => r.isMuhasabah);
      expect(night.entryLocalDay, '2026-08-02');
      expect(night.thread.single.text, 'one more thing');
      expect(night.azm, 'Tomorrow I apologise before Maghrib.');
      expect(cached.where((r) => r.isMuhasabah), hasLength(1));
    });

    test('a live ReflectNotifier adopts an out-of-band muhasabah entry',
        () async {
      // The staleness hazard: the night is written from the daily loop, which
      // has no view of this notifier's list. Without adoption, the notifier's
      // NEXT persist (any ordinary Reflect save or delete later in the same
      // session) writes its own stale list over the cache and drops tonight's
      // entry from the journal until a full sync rehydrates it.
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);

      final night = tonight();
      expect(await saveMuhasabahReflection(night), isTrue);

      expect(notifier.state.savedReflections.single.id, night.id);

      // And the cache still has it after the notifier persists its own list.
      await notifier.deleteReflection('does-not-exist');
      final prefs = await SharedPreferences.getInstance();
      final cached =
          jsonDecode(prefs.getString(fakeSync.scopedKey('saved_reflections'))!)
              as List;
      expect(cached, hasLength(1));
      expect((cached.single as Map)['source'], reflectionSourceMuhasabah);
    });

    test('saving the same night twice writes one row and one cache entry',
        () async {
      final night = tonight();
      expect(await saveMuhasabahReflection(night), isTrue);
      expect(
        await saveMuhasabahReflection(buildSavedReflection(
          userText: 'a different thing entirely',
          response: null,
          name: 'Al-Halim',
          source: reflectionSourceMuhasabah,
          entryLocalDay: '2026-08-02',
        )),
        isFalse,
        reason: 'one muḥāsabah per local day — a replay is a no-op',
      );

      expect(fakeSync.insertCalls.where((c) => c['table'] == 'user_reflections'),
          hasLength(1));
      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString(fakeSync.scopedKey('saved_reflections'))!)
            as List,
        hasLength(1),
      );
    });

    test('seeding back to the server preserves the journal fields', () async {
      // The reverse leg: a device whose cache is ahead of the server pushes its
      // rows up. If `toSupabaseRow` and `fromJson` disagree, the night is
      // uploaded as a Reflect entry and the day is lost.
      final entry = tonight();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        fakeSync.scopedKey('saved_reflections'),
        jsonEncode([entry.toJson()]),
      );

      await seedReflectionsToSupabaseFromLocalCache();

      final rows = fakeSync.batchUpsertCalls.isNotEmpty
          ? fakeSync.batchUpsertCalls.single['rows'] as List
          : fakeSync.batchInsertCalls.single['rows'] as List;
      final row = rows.single as Map<String, dynamic>;
      expect(row['source'], reflectionSourceMuhasabah);
      expect(row['entry_local_day'], '2026-08-02');
      expect(row['azm'], 'Tomorrow I apologise before Maghrib.');
      expect((row['thread'] as List).single, {
        'at': '2026-08-02T22:10:00.000Z',
        'text': 'one more thing',
      });
    });
  });
}
