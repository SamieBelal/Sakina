// The edit control, on the page that owns it (2026-08-06).
//
// `edit_reflection_text_test.dart` pins the write. What can only go wrong HERE
// is the surface, and all four of these are the kind of thing a user notices
// immediately and a provider test never sees:
//
//   * a page pushed with a route argument is a SNAPSHOT. Before the edit
//     existed nothing could make one go stale; now the page has to re-resolve
//     its entry or the save lands and the screen keeps showing the old words.
//   * the sheet must not be able to save an empty entry. Delete asks for
//     confirmation first; a Save button that quietly does the same thing is a
//     delete with no confirmation.
//   * a refused write must leave the typed words in the field. Losing them to a
//     failed round-trip is the one outcome a journaling affordance cannot have.
//   * the user has to be told what an edit does NOT touch, before they discover
//     that the reflection no longer answers what they now say they wrote.
//
// MUTATION: read `widget.reflection` in `build` instead of `_live(ref)` → the
// first test fails, still showing the pre-edit text.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/journal/screens/reflection_detail_page.dart';
import 'package:sakina/features/journal/widgets/edit_entry_sheet.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

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

/// The edit tells the daily loop about itself (`adoptEditedEntry`), because the
/// loop holds its own copy of tonight's row. Stubbed rather than left to build
/// the real notifier, which reaches for the public-catalog registry and every
/// other piece of app startup.
class _StubLoop extends DailyLoopNotifier {
  _StubLoop() : super(skipInitForTests: true) {
    state = const DailyLoopState(loaded: true);
  }

  final adopted = <SavedReflection>[];

  @override
  void adoptEditedEntry(SavedReflection updated) {
    adopted.add(updated);
    super.adoptEditedEntry(updated);
  }
}

class _Spy extends AnalyticsService {
  final tracked = <(String, Map<String, dynamic>?)>[];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

const _reflectionsKey = 'saved_reflections';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService sync;

  final entry = SavedReflection(
    id: 'e1',
    date: DateTime.now().subtract(const Duration(days: 40)).toIso8601String(),
    userText: 'the rent is due and I am short again',
    name: 'Al-Razzaq',
    nameArabic: 'الرزاق',
    reframePreview: 'He is the One who provides.',
    reframe: 'He is the One who provides, and He has not stopped.',
    source: reflectionSourceMuhasabah,
    entryLocalDay: '2026-06-27',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sync = FakeSupabaseSyncService(userId: 'user-edit-ui');
    SupabaseSyncService.debugSetInstance(sync);
  });

  tearDown(SupabaseSyncService.debugReset);

  Future<void> seedCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(_reflectionsKey),
      jsonEncode([entry.toJson()]),
    );
  }

  late _StubLoop loop;

  Future<_Spy> pump(WidgetTester t) async {
    await seedCache();
    final spy = _Spy();
    loop = _StubLoop();
    final notifier = ReflectNotifier(loadOnInit: false)
      ..debugSeedReflections([entry]);

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(spy),
          reflectProvider.overrideWith((_) => notifier),
          dailyLoopProvider.overrideWith((_) => loop),
        ],
        child: MaterialApp(home: ReflectionDetailPage(reflection: entry)),
      ),
    );
    await t.pumpAndSettle();
    return spy;
  }

  Future<void> openSheet(WidgetTester t) async {
    await t.tap(find.byIcon(Icons.edit_outlined));
    await t.pumpAndSettle();
  }

  testWidgets(
      'the edited words replace the old ones on the page itself — a '
      'route argument is a snapshot, and the page has to outlive it',
      (t) async {
    await pump(t);
    expect(find.textContaining('the rent is due'), findsOneWidget);

    await openSheet(t);
    await t.enterText(
        find.byType(TextField), 'the rent is paid, my brother covered it');
    await t.tap(find.text(JournalEditCopy.save));
    await t.pumpAndSettle();

    expect(find.textContaining('the rent is paid'), findsOneWidget);
    expect(find.textContaining('the rent is due'), findsNothing);
  });

  testWidgets(
      'the sheet opens holding what is already there — an edit starts '
      'from the words, never from a blank field', (t) async {
    await pump(t);
    await openSheet(t);

    final field = t.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'the rent is due and I am short again');
  });

  testWidgets('it says what an edit does NOT touch, before the user finds out',
      (t) async {
    await pump(t);
    await openSheet(t);

    expect(find.text(JournalEditCopy.subtitle), findsOneWidget);
  });

  testWidgets(
      'an empty field cannot be saved — delete confirms first, and '
      'this button does not', (t) async {
    await pump(t);
    await openSheet(t);
    await t.enterText(find.byType(TextField), '   ');
    await t.tap(find.text(JournalEditCopy.save));
    await t.pumpAndSettle();

    // Still open, still holding the entry.
    expect(find.byType(EditEntrySheet), findsOneWidget);
  });

  testWidgets('a refused write keeps the typed words in the field and says so',
      (t) async {
    await pump(t);
    SupabaseSyncService.debugSetInstance(_RefusingSync(userId: 'user-edit-ui'));
    await openSheet(t);
    await t.enterText(find.byType(TextField), 'rewritten');
    await t.tap(find.text(JournalEditCopy.save));
    await t.pumpAndSettle();

    expect(find.text(JournalEditCopy.failed), findsOneWidget);
    final field = t.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'rewritten',
        reason: 'losing the words to a failed round-trip is the one outcome a '
            'journaling affordance cannot have');
  });

  testWidgets(
      'the daily loop is told about the edit — it holds its OWN copy '
      'of tonight\'s row, and the notifier broadcast does not reach it',
      (t) async {
    await pump(t);
    await openSheet(t);
    await t.enterText(find.byType(TextField), 'rewritten');
    await t.tap(find.text(JournalEditCopy.save));
    await t.pumpAndSettle();

    expect(loop.adopted, hasLength(1));
    expect(loop.adopted.single.userText, 'rewritten');
  });

  testWidgets('cancel changes nothing', (t) async {
    await pump(t);
    await openSheet(t);
    await t.enterText(find.byType(TextField), 'never meant to save this');
    await t.tap(find.text(JournalEditCopy.cancel));
    await t.pumpAndSettle();

    expect(find.textContaining('the rent is due'), findsOneWidget);
    expect(find.textContaining('never meant to save'), findsNothing);
  });

  group('journal_entry_edited', () {
    testWidgets(
        'carries the source and how old the entry was — "people fix '
        'tonight\'s typo" and "people revisit March" are different features '
        'wearing the same button', (t) async {
      final spy = await pump(t);
      await openSheet(t);
      await t.enterText(find.byType(TextField), 'rewritten');
      await t.tap(find.text(JournalEditCopy.save));
      await t.pumpAndSettle();

      final events = spy.tracked
          .where((e) => e.$1 == AnalyticsEvents.journalEntryEdited)
          .toList();
      expect(events, hasLength(1));
      expect(events.single.$2![AnalyticsEvents.propSource],
          AnalyticsEvents.journalSourceMuhasabah);
      expect(events.single.$2![AnalyticsEvents.propAgeDays], 40);
    });

    testWidgets('never carries the text, before or after', (t) async {
      final spy = await pump(t);
      await openSheet(t);
      await t.enterText(find.byType(TextField), 'something private');
      await t.tap(find.text(JournalEditCopy.save));
      await t.pumpAndSettle();

      for (final (_, props) in spy.tracked) {
        for (final value in (props ?? const {}).values) {
          expect(value.toString(), isNot(contains('private')));
          expect(value.toString(), isNot(contains('rent')));
        }
      }
    });

    testWidgets('saving unchanged words is a successful close, not an edit',
        (t) async {
      final spy = await pump(t);
      await openSheet(t);
      await t.tap(find.text(JournalEditCopy.save));
      await t.pumpAndSettle();

      expect(find.byType(EditEntrySheet), findsNothing,
          reason: 'the sheet closes — nothing failed');
      expect(
        spy.tracked.where((e) => e.$1 == AnalyticsEvents.journalEntryEdited),
        isEmpty,
      );
    });
  });
}
