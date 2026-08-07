// The local reflection cache stops growing without bound (Wave D, D5).
//
// The cache is ONE JSON string under a single SharedPreferences key: every save
// re-encodes and rewrites the whole list, and every launch decodes it before the
// Journal can paint. That was survivable while a free user could hold five
// entries for life. Wave A removed that cap and Wave B started writing a row
// every night, so the blob now grows by ~365 entries a year with the cost
// landing on app start.
//
// The property that matters most here is not the truncation, it is the SORT.
// Truncating an unsorted list throws away whatever happens to be at the end —
// and for `hydrateReflectionCacheFromRows` that is whatever order PostgREST
// returned, which could as easily be this week as last year.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });

  tearDown(SupabaseSyncService.debugReset);

  SavedReflection at(DateTime day, {String? id}) => SavedReflection(
        id: id ?? day.toIso8601String(),
        date: day.toIso8601String(),
        userText: 'entry for ${day.toIso8601String()}',
        name: 'Al-Halim',
        nameArabic: 'الحليم',
        reframePreview: '',
      );

  test('a list under the cap is returned untouched, same instance', () {
    final small = [for (var i = 0; i < 10; i++) at(DateTime.utc(2026, 1, i + 1))];
    expect(identical(capReflections(small), small), isTrue,
        reason: 'the common case must not pay for a copy or a sort');
  });

  test('an over-cap list keeps the NEWEST entries, not an arbitrary slice', () {
    // Oldest first — the worst input order for a naive `take`.
    final many = [
      for (var i = 0; i < maxCachedReflections + 40; i++)
        at(DateTime.utc(2024, 1, 1).add(Duration(days: i)))
    ];

    final capped = capReflections(many);

    expect(capped, hasLength(maxCachedReflections));
    // The newest entry in the input survives; the oldest does not.
    expect(capped.first.date, many.last.date);
    expect(capped.map((r) => r.id), isNot(contains(many.first.id)));
    // And the survivors are exactly the newest N.
    final expected =
        many.reversed.take(maxCachedReflections).map((r) => r.id).toList();
    expect(capped.map((r) => r.id).toList(), expected);
  });

  test('a row with an unparseable date sorts last rather than throwing', () {
    final many = <SavedReflection>[
      const SavedReflection(
        id: 'corrupt',
        date: 'not-a-date',
        userText: 'x',
        name: '',
        nameArabic: '',
        reframePreview: '',
      ),
      for (var i = 0; i < maxCachedReflections; i++)
        at(DateTime.utc(2026, 1, 1).add(Duration(days: i))),
    ];

    final capped = capReflections(many);
    expect(capped, hasLength(maxCachedReflections));
    expect(capped.map((r) => r.id), isNot(contains('corrupt')),
        reason: 'a corrupt row must not be able to evict a good one');
  });

  test('hydrating from the server writes at most the cap, newest first',
      () async {
    final rows = [
      for (var i = 0; i < maxCachedReflections + 25; i++)
        {
          'id': 'row-$i',
          'saved_at':
              DateTime.utc(2024, 1, 1).add(Duration(days: i)).toIso8601String(),
          'user_text': 'x',
          'name': 'Al-Halim',
          'name_arabic': 'الحليم',
          'reframe_preview': '',
        }
    ];

    await hydrateReflectionCacheFromRows(rows);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      SupabaseSyncService.instance.scopedKey('saved_reflections'),
    );
    final decoded = (jsonDecode(raw!) as List).cast<Map<String, dynamic>>();

    expect(decoded, hasLength(maxCachedReflections));
    expect(decoded.first['id'], 'row-${rows.length - 1}',
        reason: 'the newest server row must be the first cached one');
  });
}
