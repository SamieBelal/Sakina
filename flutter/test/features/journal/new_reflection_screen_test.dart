/// The Journal's new-reflection composer — the surface that replaced the
/// Reflect tab (2026-08-07).
///
/// The engine underneath is unchanged and is covered by the six files in
/// `test/features/reflect/`: gating, bypass, saving, the started/completed
/// funnel. What is new, and what this file covers, is the SHELL — that the
/// composer opens blank on emerald, sends what the user actually wrote, shows
/// the reveal in place rather than on another route, and leaves nothing behind
/// when it closes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/features/daily/widgets/daily_question_field.dart';
import 'package:sakina/features/journal/content/new_reflection_copy.dart';
import 'package:sakina/features/journal/screens/new_reflection_screen.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// A landed reflection fires `checkAchievements` and `onReflectCompleted` from
/// a post-frame callback. Both reach real services, and a future still in
/// flight when a test tears down surfaces later as
/// "A PublicCatalogRegistry was used after being disposed" — attributed to
/// whichever test happens to be running next. Stubbed so the shell under test
/// is the only thing under test.
class _StubQuests extends QuestsNotifier {
  int reflectCompletions = 0;

  @override
  Future<void> onReflectCompleted() async => reflectCompletions++;
}

ai.ReflectResponse _response() => const ai.ReflectResponse(
      name: 'As-Sabur',
      nameArabic: 'الصبور',
      meaning: 'The Patient',
      reframe: 'Steadiness is being given to you.',
      story: 'A story.',
      verses: [],
      duaArabic: 'دعاء',
      duaTransliteration: 'dua',
      duaTranslation: 'A dua',
      duaSource: 'Source',
      relatedNames: [],
      offTopic: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  /// Pumps the composer behind a `/journal` route, so a pop has somewhere to
  /// land — the arrangement it actually ships in.
  Future<ReflectNotifier> pump(
    WidgetTester t, {
    Future<ai.ReflectResponse> Function(String text)? reflect,
    List<String>? sent,
  }) async {
    late ReflectNotifier notifier;
    final router = GoRouter(
      initialLocation: '/journal',
      routes: [
        GoRoute(
          path: '/journal',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push<void>(newReflectionRoutePath),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: newReflectionRoutePath,
          builder: (_, __) => const NewReflectionScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          questsProvider.overrideWith((_) => _StubQuests()),
          duasProvider.overrideWith((_) => DuasNotifier(loadOnInit: false)),
          reflectProvider.overrideWith((_) {
            notifier = ReflectNotifier(
              loadOnInit: false,
              dependencies: ReflectDependencies(
                reflect: (text) async {
                  sent?.add(text);
                  return (reflect ?? (_) async => _response())(text);
                },
                now: DateTime.now,
                createId: () => 'id-1',
              ),
            );
            return notifier;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.tap(find.text('OPEN'));
    await t.pumpAndSettle();
    return notifier;
  }

  group('the composer opens as a blank page on the canvas', () {
    testWidgets('emerald from the first frame, not a cream form', (t) async {
      await pump(t);

      // The whole point of the move: the Reflect tab it replaced was a
      // cream-surface form with a pill button. Asserted on the gradient rather
      // than on a colour constant so a re-theme of the canvas travels with it.
      final decorated = t.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(NewReflectionScreen),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((decorated.decoration as BoxDecoration).gradient,
          AppColors.sacredCanvasGradient);
    });

    testWidgets('it asks its own question, not the muḥāsabah\'s', (t) async {
      await pump(t);

      expect(find.text(NewReflectionCopy.header), findsOneWidget);
      // A user who has already done today's muḥāsabah must not be asked the
      // identical question a second time — the two surfaces would read as a
      // bug. See `NewReflectionCopy.header`.
      expect(find.text("What's on your heart today?"), findsNothing);
    });

    testWidgets('the answer-set caption is present and is not a hint',
        (t) async {
      await pump(t);
      // Present BEFORE anything is typed and still present after — a hint
      // would clear on the first keystroke, which is the defect
      // `DailyQuestionCopy.answerSetCaption` documents at length.
      expect(find.text(NewReflectionCopy.answerSetCaption), findsOneWidget);
      await t.enterText(find.byType(TextField), 'something');
      await t.pump();
      expect(find.text(NewReflectionCopy.answerSetCaption), findsOneWidget);
    });

    testWidgets('it opens blank even after a previous reflection', (t) async {
      final notifier = await pump(t);
      // Simulate a previous visit that left a result on the shared, app-scoped
      // provider. Opening onto someone else's finished reflection is the shape
      // of bug that makes an archive untrustworthy.
      notifier.setUserText('from last time');
      await t.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(t.widget<TextField>(find.byType(TextField)).controller?.text, '');
    });
  });

  group('what it sends', () {
    testWidgets('the typed sentence, verbatim', (t) async {
      final sent = <String>[];
      await pump(t, sent: sent);

      await t.enterText(find.byType(TextField), 'I keep replaying it.');
      await t.pump();
      await t.tap(find.byKey(DailyQuestionField.sendButtonKey));
      await t.pumpAndSettle();

      // Nothing appended. The tab this replaced decorated the prompt with an
      // "Emotions:" line and AI follow-up Q/A pairs; what the model sees is now
      // what the user can see they wrote.
      expect(sent, ['I keep replaying it.']);
    });

    testWidgets('a chip sends its label, matching the daily question exactly',
        (t) async {
      final sent = <String>[];
      await pump(t, sent: sent);

      final chip = problemChips.first;
      await t.tap(find.text(chip.label));
      await t.pumpAndSettle();

      // Same taxonomy, same handling, so `problem_category` stays comparable
      // across onboarding, the muḥāsabah and here.
      expect(sent, [chip.label]);
    });

    testWidgets('an empty field sends nothing', (t) async {
      final sent = <String>[];
      await pump(t, sent: sent);

      await t.tap(find.byKey(DailyQuestionField.sendButtonKey));
      await t.pumpAndSettle();

      expect(sent, isEmpty);
    });

    testWidgets('a double-tap on send sends once', (t) async {
      final sent = <String>[];
      await pump(t, sent: sent);

      await t.enterText(find.byType(TextField), 'twice?');
      await t.pump();
      await t.tap(find.byKey(DailyQuestionField.sendButtonKey));
      await t.tap(find.byKey(DailyQuestionField.sendButtonKey),
          warnIfMissed: false);
      await t.pumpAndSettle();

      expect(sent, hasLength(1),
          reason: 'the commit latch must hold until the state flips');
    });
  });

  group('the reveal happens here, not on another route', () {
    testWidgets('a result replaces the composer in place', (t) async {
      await pump(t);

      await t.enterText(find.byType(TextField), 'I am worried.');
      await t.pump();
      await t.tap(find.byKey(DailyQuestionField.sendButtonKey));
      await t.pumpAndSettle();

      // Still the same route — the beat flow renders inside this screen. The
      // composer's field is gone because the reveal took its place.
      expect(find.byType(NewReflectionScreen), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(NewReflectionCopy.header), findsNothing);
    });

    testWidgets('a failed call returns to the composer, field alive',
        (t) async {
      await pump(t, reflect: (_) async => throw Exception('network'));

      await t.enterText(find.byType(TextField), 'I am worried.');
      await t.pump();
      await t.tap(find.byKey(DailyQuestionField.sendButtonKey));
      await t.pumpAndSettle();

      // The latch has to release, or the field stays dead after a blip and the
      // only way out is the back gesture.
      expect(find.byType(TextField), findsOneWidget);
      expect(t.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    });
  });

  group('closing', () {
    testWidgets('the × pops back to the Journal', (t) async {
      await pump(t);

      await t.tap(find.byKey(const ValueKey('new-reflection-close')));
      await t.pumpAndSettle();

      expect(find.byType(NewReflectionScreen), findsNothing);
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('the × is never live once a submit is in the air', (t) async {
      // Leaving mid-flight would land a saved reflection on a screen the user
      // has left. Two phases cover the window, and the assertion allows both
      // rather than pretending there is only one: between the tap and the gate
      // resolving, the composer is still up and its × is DISABLED; once the
      // state flips to loading the beat flow replaces the composer and the ×
      // is GONE. What must never happen is a live × in either phase.
      await pump(t, reflect: (_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return _response();
      });

      await t.enterText(find.byType(TextField), 'hold on');
      await t.pump();
      await t.tap(find.byKey(DailyQuestionField.sendButtonKey));

      for (var i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 50));
        final close = find.byKey(const ValueKey('new-reflection-close'));
        if (close.evaluate().isEmpty) continue;
        expect(t.widget<IconButton>(close).onPressed, isNull,
            reason: 'the × was live while a submit was in flight');
      }

      await t.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  group('the close control', () {
    testWidgets('sits top-RIGHT, where the beat flow puts its chrome',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await pump(t);

      final close = t.getRect(find.byKey(const ValueKey('new-reflection-close')));

      // `BeatRevealFlow` — the view this composer becomes the moment a
      // reflection lands — puts skip and share top-right. A top-left × made the
      // chrome jump sides mid-flow. It also sat directly above the first word
      // of a left-aligned headline, joining the title's block instead of
      // reading as chrome.
      expect(close.center.dx, greaterThan(390 / 2),
          reason: 'the × drifted back to the left half');
      expect(close.right, lessThanOrEqualTo(390));
    });

    testWidgets('clears the headline instead of crowding it', (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await pump(t);

      // **Measured on the GLYPH, not the button.** `IconButton` is a 48pt tap
      // target around a 24pt icon, so its rect carries 12pt of padding the eye
      // never sees — measuring the box understates the clearance by exactly
      // that much and would have this test demanding whitespace nobody asked
      // for. What the user sees is the × mark itself against the question.
      final glyph = t.getRect(find.byIcon(Icons.close_rounded));
      final header = t.getRect(find.text(NewReflectionCopy.header));

      expect(header.top - glyph.bottom, greaterThan(16),
          reason: 'only ${(header.top - glyph.bottom).toStringAsFixed(1)}pt '
              'between the × and the question');
    });

    testWidgets('does not overlap the headline horizontally either', (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await pump(t);

      final close = t.getRect(find.byKey(const ValueKey('new-reflection-close')));
      final header = t.getRect(find.text(NewReflectionCopy.header));
      // The headline is long; on the right it must still stop short of the ×'s
      // column, or the two collide at large Dynamic Type.
      expect(close.overlaps(header), isFalse);
    });
  });

  group('the allowance line', () {
    testWidgets('a fresh free account is told what it has, before writing',
        (t) async {
      // A fresh account has no warm-up counter yet, so the dial supplies one —
      // which is the state every new user meets this screen in. The cost is
      // stated BEFORE the writing, which is the whole premise.
      await pump(t);
      expect(find.byKey(const ValueKey('new-reflection-allowance')),
          findsOneWidget);
      // And it does NOT promise a reset the warm-up will not honour. Pinned
      // here as well as in `reflection_allowance_copy_test` because this is the
      // rendered string rather than the pure function.
      final text = t.widget<Text>(
          find.byKey(const ValueKey('new-reflection-allowance')));
      expect(text.data!.toLowerCase(), isNot(contains('week')));
    });
  });
}
