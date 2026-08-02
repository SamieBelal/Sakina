// Every self-collapsing card on the home column owns its own bottom margin.
//
// The convention exists because these cards are *conditional*: outside an
// occasion window, without an active duʿā window, for a non-subscriber, the
// card renders `SizedBox.shrink()`. If the COLUMN supplied the gap instead, a
// hidden card would leave a hole; so each shown card spaces itself and a hidden
// one contributes exactly zero height.
//
// `RamadanGiftCard` was the one that did not follow it, and the gap was
// invisible until W4 Wave 5 reordered the column: the spacer it had been
// borrowing from its neighbour ended up ABOVE it, leaving the claimed-gift
// banner butted flat against the dashboard card. Reported from device, 2026-07-30.
//
// This is a source-read test for the same reason the CTA position pins are:
// the property is about the ARRANGEMENT of widgets that are usually not on
// screen at all, and no widget test of a card in isolation can see it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The five conditional cards, in column order. The daily CTA is deliberately
  /// absent: it always renders one of three faces, never collapses, so the
  /// column supplying its spacer is correct rather than an oversight.
  const cards = <String, String>{
    'RamadanGiftCard': 'lib/features/gifts/widgets/ramadan_gift_card.dart',
    'DuaTimesCard': 'lib/features/dua_times/widgets/dua_times_card.dart',
    'ReferralNudgeCard':
        'lib/features/referrals/widgets/referral_nudge_card.dart',
    'WidgetInstallNudgeCard':
        'lib/features/widget_promo/widgets/widget_install_nudge_card.dart',
    'HomePremiumStrip': 'lib/features/home/widgets/home_premium_strip.dart',
  };

  for (final entry in cards.entries) {
    test('${entry.key} owns its bottom margin', () {
      final source = File(entry.value).readAsStringSync();

      expect(
        source.contains('EdgeInsets.only(bottom: AppSpacing'),
        isTrue,
        reason:
            '${entry.key} must space itself from the content below. Without it '
            'the home column has to supply the gap — and then the card is at '
            'the mercy of wherever a future reorder leaves that spacer, which '
            'is exactly how the gift banner ended up flush against the '
            'dashboard card.',
      );

      // The other half of the contract: it must actually collapse when it has
      // nothing to say, or the margin it now owns becomes dead space on every
      // screen where the card is irrelevant.
      expect(
        source.contains('SizedBox.shrink()'),
        isTrue,
        reason: '${entry.key} must render nothing when it has nothing to show',
      );
    });
  }

  test('the home column supplies no spacer after a self-collapsing card', () {
    final home = File(
      'lib/features/progress/screens/progress_screen.dart',
    ).readAsStringSync();

    // Between the first conditional card and the dashboard there must be no
    // `SizedBox` — every gap in that stretch belongs to a card. A spacer here
    // is the bug in the other direction: a hole on the (common) days when the
    // card above it is hidden.
    final start = home.indexOf('const RamadanGiftCard()');
    final end = home.indexOf('_buildDashboardCard(');
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));

    expect(
      home.substring(start, end).contains('SizedBox('),
      isFalse,
      reason: 'a spacer between the conditional cards leaves a hole whenever '
          'the card above it collapses — which is most days for all five',
    );
  });
}
