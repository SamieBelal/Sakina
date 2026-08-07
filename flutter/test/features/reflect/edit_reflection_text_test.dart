// Editing a past entry (2026-08-06).
//
// The journal shipped with two things you could do to a saved entry: delete it,
// or append to it until the local day rolled over. There was no way to fix a
// typo, and no way to touch a night from March at all.
//
// `editReflectionText` is the third, and it is deliberately the narrowest thing
// that answers the complaint. Two properties keep it safe, and both are pinned
// here:
//
//   * **it rewrites the user's words and NOTHING else.** The Name, the reframe,
//     the story, the verses and the duʿā are what the app said back on the night
//     in question. An edit must not rewrite history it did not author, even when
//     the two stop reading as a matched pair.
//   * **it does not re-open the night.** Like every other write in that section
//     of `reflect_provider.dart` it is a pure text write against a row that
//     already exists — no reveal, no streak, no reward ladder, no allowance.
//     That is also why an edit is allowed on an entry of ANY age while an append
//     stops at the rollover: an append is a new line the night did not have; a
//     correction is not.
//
// MUTATION: let it write through `copyWith(name: ...)` as well → the
// "nothing else moves" group fails and names the field.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Refuses every upsert, the way the real service does on a CHECK violation,
/// an RLS refusal or a transient 5xx — `upsertRawRow` returns false rather than
/// throwing.
class _RefusingSync extends FakeSupabaseSyncService {
  _RefusingSync({required super.userId});
  @override
  Future<bool> upsertRawRow(
    String table,
    Map<String, dynamic> data, {
    String? onConflict,
  }) async =>
      false;
}

const _reflectionsKey = 'saved_reflections';

SavedReflection _entry({
  String id = 'e1',
  String userText = 'the rent is due and I am short again',
  String source = reflectionSourceReflect,
  String? entryLocalDay,
}) =>
    SavedReflection(
      id: id,
      date: '2026-03-14T21:00:00Z',
      userText: userText,
      name: 'Al-Razzaq',
      nameArabic: 'الرزاق',
      reframePreview: 'He is the One who provides.',
      reframe: 'He is the One who provides, and He has not stopped.',
      story: 'The companions had nothing, and were fed.',
      duaArabic: 'اللهم ارزقني',
      duaTransliteration: 'Allahumma urzuqni',
      duaTranslation: 'O Allah, provide for me.',
      duaSource: 'Tirmidhi 3563',
      takeaway: 'Provision arrives from where you did not look.',
      source: source,
      entryLocalDay: entryLocalDay,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService sync;

  Future<void> seed(List<SavedReflection> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      sync.scopedKey(_reflectionsKey),
      jsonEncode(entries.map((r) => r.toJson()).toList()),
    );
  }

  Future<List<SavedReflection>> readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(sync.scopedKey(_reflectionsKey));
    if (json == null) return const [];
    return (jsonDecode(json) as List)
        .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sync = FakeSupabaseSyncService(userId: 'user-edit');
    SupabaseSyncService.debugSetInstance(sync);
  });

  tearDown(SupabaseSyncService.debugReset);

  group('the write', () {
    test('replaces the user\'s words in the cache', () async {
      await seed([_entry()]);

      final updated = await editReflectionText(
        id: 'e1',
        text: 'the rent is paid — my brother covered it',
      );

      expect(updated, isNotNull);
      expect(updated!.userText, 'the rent is paid — my brother covered it');
      final cached = await readCache();
      expect(
          cached.single.userText, 'the rent is paid — my brother covered it');
    });

    test('trims, because a trailing newline from the keyboard is not an edit',
        () async {
      await seed([_entry()]);
      final updated =
          await editReflectionText(id: 'e1', text: '  rewritten  \n');
      expect(updated!.userText, 'rewritten');
    });

    test('leaves every OTHER entry alone', () async {
      await seed([_entry(id: 'a'), _entry(id: 'b', userText: 'untouched')]);

      await editReflectionText(id: 'a', text: 'changed');

      final cached = await readCache();
      expect(cached.firstWhere((r) => r.id == 'a').userText, 'changed');
      expect(cached.firstWhere((r) => r.id == 'b').userText, 'untouched');
      expect(cached, hasLength(2),
          reason: 'an edit is not a delete and not an insert');
    });

    test(
        'an edit lands on a night from months ago — age is not a gate here, '
        'and that is the whole difference from an append', () async {
      await seed([
        _entry(
          source: reflectionSourceMuhasabah,
          entryLocalDay: '2026-03-14',
        ),
      ]);

      final updated = await editReflectionText(id: 'e1', text: 'what I meant');

      expect(updated, isNotNull);
      expect(updated!.entryLocalDay, '2026-03-14',
          reason: 'the night it belongs to must not move');
    });
  });

  group('nothing else moves', () {
    test(
        'the Name, the reframe, the story and the duʿā survive an edit '
        'unchanged — they are what the app said, not what the user wrote',
        () async {
      final before = _entry();
      await seed([before]);

      final after = await editReflectionText(id: 'e1', text: 'rewritten');

      expect(after!.name, before.name);
      expect(after.nameArabic, before.nameArabic);
      expect(after.reframe, before.reframe);
      expect(after.reframePreview, before.reframePreview);
      expect(after.story, before.story);
      expect(after.takeaway, before.takeaway);
      expect(after.duaArabic, before.duaArabic);
      expect(after.duaTranslation, before.duaTranslation);
      expect(after.duaSource, before.duaSource);
      expect(after.date, before.date,
          reason: 'the entry keeps the night it was written on');
      expect(after.source, before.source);
    });

    test('the thread and the azm are untouched — an edit is not an append',
        () async {
      final before = _entry(source: reflectionSourceMuhasabah).copyWith(
        thread: const [ReflectionThreadEntry(at: '', text: 'a later line')],
        azm: 'call him tomorrow',
      );
      await seed([before]);

      final after = await editReflectionText(id: 'e1', text: 'rewritten');

      expect(after!.thread.single.text, 'a later line');
      expect(after.azm, 'call him tomorrow');
    });
  });

  group('the refusals', () {
    test(
        'blank text is refused — an entry cannot be edited into having no '
        'words, which is what delete is for', () async {
      await seed([_entry()]);

      expect(await editReflectionText(id: 'e1', text: '   '), isNull);
      expect((await readCache()).single.userText,
          'the rent is due and I am short again');
    });

    test('an id that is not in the cache is refused rather than inserted',
        () async {
      await seed([_entry(id: 'e1')]);

      expect(await editReflectionText(id: 'nope', text: 'hello'), isNull);
      expect(await readCache(), hasLength(1));
    });

    test(
        'unchanged text is a no-op that still reports success — pressing save '
        'on words nobody altered is a successful close, not a failure',
        () async {
      const same = 'the rent is due and I am short again';
      await seed([_entry(userText: same)]);

      final result = await editReflectionText(id: 'e1', text: same);

      expect(result, isNotNull);
      expect(result!.userText, same);
    });

    test(
        'a server refusal leaves the cache exactly as it was — the edit is '
        'never shown locally and then lost on the next sync', () async {
      await seed([_entry()]);
      SupabaseSyncService.debugSetInstance(_RefusingSync(userId: 'user-edit'));

      expect(await editReflectionText(id: 'e1', text: 'rewritten'), isNull);
      expect((await readCache()).single.userText,
          'the rent is due and I am short again');
    });
  });

  group('clamping', () {
    test(
        'over-long text is truncated to what the server accepts, and the '
        'cache stores the truncated value — what stays on screen is exactly '
        'what was stored', () async {
      await seed([_entry()]);

      final long = 'x' * 5000;
      final updated = await editReflectionText(id: 'e1', text: long);

      expect(updated!.userText.length, lessThan(long.length));
      expect((await readCache()).single.userText, updated.userText,
          reason: 'local state and the blob must see the same truncation');
    });
  });

  group('signed out', () {
    test('the local cache IS the journal, so the edit still lands', () async {
      SupabaseSyncService.debugSetInstance(
          FakeSupabaseSyncService(userId: null));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        supabaseSyncService.scopedKey(_reflectionsKey),
        jsonEncode([_entry().toJson()]),
      );

      final updated = await editReflectionText(id: 'e1', text: 'rewritten');

      expect(updated, isNotNull);
      expect(updated!.userText, 'rewritten');
    });
  });
}
