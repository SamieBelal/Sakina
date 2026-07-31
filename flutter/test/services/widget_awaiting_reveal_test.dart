// W4 Wave 6 — the widget stops advertising a Name it will not deliver.
//
// The bug: `composeWidgetSyncState` sent `getTodaysName()` — a day-of-year
// rotation — with `personalized: false` until check-in, while the actual reveal
// comes from the queue planner (cohort users) or `pickNextCard` (everyone
// else). Those have never agreed. It was harmless while the reveal was a blind
// gacha nobody had been promised anything about; it is a broken promise now
// that the reveal is the answer to a question the user was asked.
//
// The iOS extension made it worse in a way that is easy to miss: it only reads
// the payload's Name when `mode == "personalized"`, and otherwise recomputes
// its own rotation from a bundled catalog. So the Dart-side Name was dead data
// AND the widget still showed a rotation. Fixing this in Dart alone changes
// nothing a user sees — the Swift half is in `ios/SakinaWidget/SakinaWidget.swift`
// (`awaiting` in `resolve(at:phase:)` and `AwaitingHero`).
//
// The contract pinned here: pre-reveal, no Name is claimed anywhere in the
// payload — not in the display fields, not in the anchor, not in the name key.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/widget_data_service.dart';
import 'package:sakina/services/widget_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHomeWidgetClient implements HomeWidgetClient {
  final List<MapEntry<String, String?>> saved = [];
  int updates = 0;

  @override
  Future<void> setAppGroupId(String id) async {}

  @override
  Future<void> saveWidgetData(String key, String? value) async =>
      saved.add(MapEntry(key, value));

  @override
  Future<void> updateWidget({required String name}) async => updates++;

  Map<String, dynamic> get lastPayload =>
      jsonDecode(saved.last.value!) as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final alMalik = allahNames.firstWhere((n) => n.transliteration == 'Al-Malik');
  final alWadud = allahNames.firstWhere((n) => n.transliteration == 'Al-Wadud');

  WidgetDataService build(_FakeHomeWidgetClient client) => WidgetDataService(
        client: client,
        clock: () => DateTime(2026, 7, 30, 9),
        locationService: LocationService(
          checkPermission: () async => LocationPermission.always,
          prefs: SharedPreferences.getInstance,
        ),
      );

  CheckInRecord record(String date, String name) => CheckInRecord(
        date: date,
        q1: 'discover',
        q2: '',
        q3: '',
        q4: '',
        nameReturned: name,
        nameArabic: '',
      );

  group('composeWidgetSyncState withholds the Name until it is real', () {
    test('no check-in today → NO Name, not a rotation', () {
      final s = composeWidgetSyncState(
        history: const [],
        todaysName: alMalik,
        now: DateTime(2026, 7, 30, 9),
        lastReflectedLocalDay: null,
      );

      expect(s.name, isNull,
          reason: 'the day-of-year rotation has never been the Name the user '
              'actually receives — advertising it promises something the '
              'reveal will not honour');
      expect(s.awaitingReveal, isTrue);
      expect(s.personalized, isFalse);
      expect(s.checkedInToday, isFalse);
    });

    test('checked in today → the Name actually received', () {
      final s = composeWidgetSyncState(
        history: [record('2026-07-30', 'Al-Wadud')],
        todaysName: alMalik,
        now: DateTime(2026, 7, 30, 9),
        lastReflectedLocalDay: '2026-07-30',
      );

      expect(s.name?.transliteration, 'Al-Wadud');
      expect(s.awaitingReveal, isFalse);
      expect(s.personalized, isTrue);
      expect(s.checkedInToday, isTrue);
    });

    test('yesterday\'s check-in does not carry into today', () {
      final s = composeWidgetSyncState(
        history: [record('2026-07-29', 'Al-Wadud')],
        todaysName: alMalik,
        now: DateTime(2026, 7, 30, 9),
        lastReflectedLocalDay: '2026-07-29',
      );

      expect(s.name, isNull,
          reason: 'a new local day is a new unanswered question');
      expect(s.awaitingReveal, isTrue);
    });
  });

  group('the payload carries no Name it cannot honour', () {
    test('a null Name emits mode:awaiting with every Name field blank',
        () async {
      final client = _FakeHomeWidgetClient();
      await build(client).syncWidget(
        name: null,
        anchor: '',
        streak: 4,
        checkedInToday: false,
        personalized: false,
      );

      final json = client.lastPayload;
      expect(json['mode'], 'awaiting');
      // Each of these is a separate assertion on purpose: a Name left in ANY
      // of them is a Name some future reader will render.
      expect(json['name_key'], '');
      expect(json['name'], '');
      expect(json['name_english'], '');
      expect(json['arabic'], '');
      expect(json['transliteration'], '');
      expect(json['anchor'], '',
          reason: 'the anchor is that Name\'s teaching line — carrying one '
              'would smuggle the claim back in through the copy');
      // The half the widget still legitimately shows.
      expect(json['streak'], 4);
      expect(json['checked_in_today'], false);
    });

    test('the payload still carries the streak and skin while awaiting',
        () async {
      final client = _FakeHomeWidgetClient();
      await build(client).syncWidget(
        name: null,
        anchor: '',
        streak: 11,
        checkedInToday: false,
        personalized: false,
        lanternSkinId: 'default',
      );

      final json = client.lastPayload;
      expect(json['streak'], 11,
          reason: 'plan §8: lantern + streak stay, only the Name is withheld');
      expect(json['lantern_skin'], isNotEmpty);
    });

    test('a revealed Name still emits mode:personalized with the real Name',
        () async {
      final client = _FakeHomeWidgetClient();
      await build(client).syncWidget(
        name: alWadud,
        anchor: 'He loves you before you turn.',
        streak: 5,
        checkedInToday: true,
        personalized: true,
      );

      final json = client.lastPayload;
      expect(json['mode'], 'personalized');
      expect(json['transliteration'], 'Al-Wadud');
      expect(json['anchor'], 'He loves you before you turn.');
      expect(json['checked_in_today'], true);
    });

    test('a non-null Name with personalized:false still emits the legacy mode',
        () async {
      // Back-compat: `daily` is no longer emitted by composeWidgetSyncState,
      // but the extension still understands it and the seam must not silently
      // reinterpret a caller that passes a Name.
      final client = _FakeHomeWidgetClient();
      await build(client).syncWidget(
        name: alMalik,
        anchor: 'anchor',
        streak: 0,
        checkedInToday: false,
        personalized: false,
      );

      expect(client.lastPayload['mode'], 'daily');
    });
  });

  group('the reveal re-pushes the widget (source pin)', () {
    // A source pin rather than a behavioural one: `syncHomeWidget` is a
    // top-level function reaching a platform channel through a process-global
    // `widgetDataService`, so there is no seam to observe from a notifier test
    // without inventing one for the test's benefit. What matters is cheap to
    // state and easy to break: the push exists, and it happens after the two
    // writes the payload is composed from.
    late String source;

    setUpAll(() {
      source =
          File('lib/features/daily/providers/daily_loop_provider.dart')
              .readAsStringSync();
    });

    test('discoverName pushes the widget once the Name exists', () {
      expect(source.contains('syncHomeWidget()'), isTrue,
          reason: 'without this the widget keeps inviting the user to a '
              'muḥāsabah they already finished, until the next full sync');
    });

    test('the push lands after the check-in row and the streak mark', () {
      // `composeWidgetSyncState` flips to personalized off a history row dated
      // today, and the streak comes from the mark. Pushing before either would
      // publish a half-built payload — still awaiting, or a stale streak.
      //
      // Scoped to discoverName's own body: `_markStreakAndHandleMilestones` has
      // a definition and a second call site in the dormant `answerCheckin`, and
      // a whole-file indexOf finds the definition first.
      final bodyStart = source.indexOf('Future<void> discoverName(');
      final bodyEnd = source.indexOf('Future<void> _runDiscoverName(');
      expect(bodyStart, greaterThan(0));
      expect(bodyEnd, greaterThan(bodyStart));
      final body = source.substring(bodyStart, bodyEnd);

      final history = body.indexOf('saveCheckinRecord(CheckInRecord(');
      final streak = body.indexOf('await _markStreakAndHandleMilestones();');
      final push = body.indexOf('syncHomeWidget()');

      expect(history, greaterThan(0));
      expect(streak, greaterThan(history));
      expect(push, greaterThan(streak),
          reason: 'the payload is composed from the history row and the '
              'streak, so both must already be written');
    });

    test('the push is fire-and-forget so it cannot delay the reveal', () {
      expect(source.contains('unawaited(syncHomeWidget())'), isTrue,
          reason: 'awaiting a platform-channel round-trip here would put the '
              'widget between the user and their Name');
    });
  });

  group('no loss framing while the question is still unanswered', () {
    // Plan §2 rule 6: no guilt mechanic under an invitation, and no clock near
    // the reveal. The awaiting state is precisely "the app has asked and the
    // user has not answered yet", and the 8 PM timeline entry resolves
    // `.atRisk` for exactly that state — so every evening glance was a
    // deadline about a question the app had not yet been answered.
    //
    // Small and medium got this right at Wave 6 (`AwaitingHero`,
    // `StreakChip(suppressLossFraming: true)`). `AccessoryView` was missed, and
    // it is the worst one to miss: the Lock Screen is the highest-frequency
    // surface in the app.
    //
    // A source test because the alternative is an Xcode snapshot target that
    // does not exist, and because the property is about which BRANCH the copy
    // sits behind — cheap to state, easy to break, invisible in review.
    late String swift;

    setUpAll(() {
      swift = File('ios/SakinaWidget/SakinaWidget.swift').readAsStringSync();
    });

    /// The body of a Swift `private struct <name>: View { … }`, matched by
    /// brace balance so a nested type cannot end the slice early, and with
    /// `//` lines stripped.
    ///
    /// The strip is not cosmetic. The first version of this test scanned the
    /// raw source and failed against the CORRECT code, because the doc comment
    /// explaining the fix quotes the very strings the fix removes. A test that
    /// cannot tell code from prose about code would have been "fixed" by
    /// deleting the explanation.
    String structBody(String name) {
      final start = swift.indexOf('private struct $name: View {');
      expect(start, greaterThan(0), reason: '$name not found');
      var depth = 0;
      for (var i = swift.indexOf('{', start); i < swift.length; i++) {
        if (swift[i] == '{') depth++;
        if (swift[i] == '}') {
          depth--;
          if (depth == 0) {
            return swift
                .substring(start, i + 1)
                .split('\n')
                .where((l) => !l.trimLeft().startsWith('//'))
                .join('\n');
          }
        }
      }
      fail('unbalanced braces in $name');
    }

    test('AccessoryView branches on awaitingReveal at all', () {
      expect(
        structBody('AccessoryView').contains('display.awaitingReveal'),
        isTrue,
        reason: 'without this branch the Lock Screen falls through to the '
            'streakState switch, where awaiting resolves to .atRisk every '
            'evening',
      );
    });

    for (final phrase in [
      "Don't lose your",
      'Reflect before midnight',
      'Keep your',
    ]) {
      test('AccessoryView guards "$phrase" behind the answered state', () {
        final body = structBody('AccessoryView');
        final at = body.indexOf(phrase);
        if (at < 0) return; // removed entirely — also fine
        final guard = body.indexOf('display.awaitingReveal');
        expect(
          guard,
          allOf(greaterThan(0), lessThan(at)),
          reason: '"$phrase" must sit after the awaiting check, never before '
              'it — on a surface glanced at 80–100 times a day it is the '
              'difference between an invitation and a deadline',
        );
      });
    }

    test('the small family still suppresses it', () {
      // The Wave 6 fix, pinned so this group covers every family rather than
      // just the one that regressed.
      expect(
        structBody('SmallView').contains('suppressLossFraming: true'),
        isTrue,
      );
    });
  });
}
