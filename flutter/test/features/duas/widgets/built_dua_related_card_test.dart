// W6 Wave D — pins `dua_read`. Definition (see the widget's docstring in
// `built_dua_related_card.dart`): a USER-INITIATED expand of a related-dua
// card (collapsed → expanded), not a screen mount and not the card that
// starts pre-expanded by default (`initiallyExpanded`, for the tour anchor).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart'
    show SavedRelatedDua;
import 'package:sakina/features/duas/widgets/built_dua_related_card.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

const _dua = FindDuasDuaEntry(
  title: 'Dua for Ease',
  arabic: 'دعاء',
  transliteration: 'transliteration',
  translation: 'translation',
  source: 'Sahih Muslim',
);

Widget _harness(AnalyticsService spy, {bool initiallyExpanded = false}) {
  return ProviderScope(
    overrides: [analyticsProvider.overrideWithValue(spy)],
    child: MaterialApp(
      home: Scaffold(
        body: BuiltDuaRelatedCard(
          dua: _dua,
          heart: const SizedBox(width: 24, height: 24),
          initiallyExpanded: initiallyExpanded,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'tapping a collapsed card fires dua_read{dua_id, source} — '
      'MUTATION: emitting from initState instead of the tap handler '
      'would make this fail', (tester) async {
    final spy = _TrackingSpy();
    await tester.pumpWidget(_harness(spy));
    await tester.pumpAndSettle();

    expect(spy.tracked, isEmpty,
        reason: 'mounting collapsed must not itself count as a read');

    await tester.tap(find.text('Dua for Ease'));
    await tester.pump();

    final reads =
        spy.tracked.where((e) => e.$1 == AnalyticsEvents.duaRead).toList();
    expect(reads, hasLength(1));
    expect(
      reads.single.$2?[AnalyticsEvents.propDuaId],
      SavedRelatedDua.idFor(_dua.title, _dua.source),
    );
    expect(reads.single.$2?[AnalyticsEvents.propSource], 'built_dua_related');
  });

  testWidgets('collapsing an expanded card does NOT fire dua_read again',
      (tester) async {
    final spy = _TrackingSpy();
    await tester.pumpWidget(_harness(spy));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dua for Ease')); // expand
    await tester.pump();
    await tester.tap(find.text('Dua for Ease')); // collapse
    await tester.pump();

    final reads =
        spy.tracked.where((e) => e.$1 == AnalyticsEvents.duaRead).toList();
    expect(reads, hasLength(1),
        reason: 'collapsing is not a read; only the expand transition is');
  });

  testWidgets(
      'the card that starts pre-expanded (tour anchor default) does NOT '
      'fire dua_read on mount', (tester) async {
    final spy = _TrackingSpy();
    await tester.pumpWidget(_harness(spy, initiallyExpanded: true));
    await tester.pumpAndSettle();

    final reads =
        spy.tracked.where((e) => e.$1 == AnalyticsEvents.duaRead).toList();
    expect(reads, isEmpty,
        reason:
            'the default-expanded first card was never tapped — no read');
  });
}
