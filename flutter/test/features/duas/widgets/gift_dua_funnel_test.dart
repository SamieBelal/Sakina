// Pins the Gift-a-Dua funnel (2026-08-02). The gift affordance originally
// shipped with no instrumentation at all, so the thing we actually doubted —
// whether anyone finds it — was unmeasurable.
//
// The three steps and their exact semantics:
//   gift_cta_shown       ONCE per result, no placement (both affordances render
//                        together, so one event per affordance would double the
//                        impressions and halve every rate below it)
//   gift_preview_opened  carries the placement that was tapped
//   gift_sent            only when the share sheet actually received the pages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/duas/widgets/built_dua_ameen_screen.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/widgets/share_card.dart';

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }

  List<String> get names => tracked.map((e) => e.$1).toList();
  Map<String, dynamic>? propsOf(String event) =>
      tracked.firstWhere((e) => e.$1 == event).$2;
}

const _result = BuiltDuaResponse(
  arabic: 'دعاء',
  transliteration: 'dua',
  translation: 'a supplication',
  breakdown: [
    BuiltDuaSection(
      label: 'The Ask',
      arabic: 'يَا وَدُودُ',
      transliteration: 'Ya Wadud',
      translation: 'O Most Loving',
    ),
  ],
  namesUsed: [],
  relatedDuas: [],
);

Widget _harness(AnalyticsService spy, {String need = 'marriage'}) {
  return ProviderScope(
    overrides: [analyticsProvider.overrideWithValue(spy)],
    child: MaterialApp(
      home: Scaffold(
        body: BuiltDuaAmeenScreen(
          state: DuasState(buildNeed: need, buildResult: _result),
          notifier: DuasNotifier(loadOnInit: false),
          // Already handled, so the auto-save side effect stays out of the way.
          saveHandled: true,
          onFirstRender: () {},
          onRelatedDuaSaved: () {},
          onBuildAnother: () {},
        ),
      ),
    ),
  );
}

void main() {
  late ShareBuiltDuaFn originalShare;

  setUp(() => originalShare = shareBuiltDuaCard);
  tearDown(() => shareBuiltDuaCard = originalShare);

  testWidgets('gift_cta_shown fires exactly once per result, without placement',
      (tester) async {
    final spy = _TrackingSpy();
    await tester.pumpWidget(_harness(spy));
    await tester.pump(const Duration(seconds: 2));

    expect(
      spy.names.where((n) => n == AnalyticsEvents.giftCtaShown),
      hasLength(1),
      reason: 'two affordances render together but the impression is one',
    );
    expect(spy.propsOf(AnalyticsEvents.giftCtaShown), isNull);
  });

  testWidgets('a rebuild does not re-fire the impression', (tester) async {
    final spy = _TrackingSpy();
    await tester.pumpWidget(_harness(spy));
    await tester.pump(const Duration(seconds: 2));

    // Genuinely rebuild the widget with new inputs: same type and position, so
    // the element is UPDATED rather than remounted and build() runs again while
    // initState does not. MUTATION GUARD: moving the emit from initState into
    // build() must fail here — a plain extra pump() will not catch it, because
    // flutter_animate caches its child and won't rebuild the subtree on tick.
    await tester.pumpWidget(_harness(spy, need: 'a different need'));
    await tester.pump(const Duration(seconds: 2));

    expect(
      spy.names.where((n) => n == AnalyticsEvents.giftCtaShown),
      hasLength(1),
      reason: 'the impression is mount-scoped, not build-scoped',
    );
  });

  testWidgets('the labeled CTA opens the preview tagged with its placement',
      (tester) async {
    final spy = _TrackingSpy();
    var opened = 0;
    shareBuiltDuaCard = ({
      required BuildContext context,
      required String need,
      required List<DuaShareSection> sections,
      required String translation,
      Rect? sharePositionOrigin,
      void Function(int pageCount, String shareStatus)? onShared,
    }) async {
      opened++;
      onShared?.call(2, 'success');
    };

    await tester.pumpWidget(_harness(spy));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Gift this Dua'));
    await tester.pump(const Duration(seconds: 1));

    expect(opened, 1);
    expect(spy.propsOf(AnalyticsEvents.giftPreviewOpened),
        {AnalyticsEvents.propPlacement: AnalyticsEvents.giftPlacementPrimaryCta});
    expect(spy.propsOf(AnalyticsEvents.giftSent), {
      AnalyticsEvents.propPlacement: AnalyticsEvents.giftPlacementPrimaryCta,
      AnalyticsEvents.propPageCount: 2,
      AnalyticsEvents.propShareStatus: 'success',
    });
  });

  testWidgets('a dismissed share sheet is not counted as a sent gift',
      (tester) async {
    final spy = _TrackingSpy();
    // `Share.shareXFiles` completes when the sheet closes HOWEVER it closed, so
    // the real screen must check the result status. Modelled here by the share
    // fake simply never invoking onShared, which is what a dismissal produces.
    shareBuiltDuaCard = ({
      required BuildContext context,
      required String need,
      required List<DuaShareSection> sections,
      required String translation,
      Rect? sharePositionOrigin,
      void Function(int pageCount, String shareStatus)? onShared,
    }) async {
      // dismissed → no callback
    };

    await tester.pumpWidget(_harness(spy));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Gift this Dua'));
    await tester.pump(const Duration(seconds: 1));

    expect(spy.names, contains(AnalyticsEvents.giftPreviewOpened));
    expect(spy.names, isNot(contains(AnalyticsEvents.giftSent)));
  });

  testWidgets('the corner icon is separable from the labeled CTA',
      (tester) async {
    final spy = _TrackingSpy();
    shareBuiltDuaCard = ({
      required BuildContext context,
      required String need,
      required List<DuaShareSection> sections,
      required String translation,
      Rect? sharePositionOrigin,
      void Function(int pageCount, String shareStatus)? onShared,
    }) async {
      onShared?.call(1, 'success');
    };

    await tester.pumpWidget(_harness(spy));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.card_giftcard_outlined));
    await tester.pump(const Duration(seconds: 1));

    expect(spy.propsOf(AnalyticsEvents.giftPreviewOpened), {
      AnalyticsEvents.propPlacement: AnalyticsEvents.giftPlacementCornerIcon,
    });
  });

  testWidgets('a failed share is never counted as a sent gift',
      (tester) async {
    final spy = _TrackingSpy();
    shareBuiltDuaCard = ({
      required BuildContext context,
      required String need,
      required List<DuaShareSection> sections,
      required String translation,
      Rect? sharePositionOrigin,
      void Function(int pageCount, String shareStatus)? onShared,
    }) async {
      throw StateError('forced share failure');
    };

    await tester.pumpWidget(_harness(spy));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Gift this Dua'));
    await tester.pump(const Duration(seconds: 1));

    expect(spy.names, contains(AnalyticsEvents.giftPreviewOpened));
    expect(spy.names, isNot(contains(AnalyticsEvents.giftSent)),
        reason: 'an export that threw must not inflate the send rate');
  });
}
