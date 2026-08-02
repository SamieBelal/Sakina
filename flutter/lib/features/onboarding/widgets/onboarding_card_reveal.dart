import 'package:flutter/material.dart';

import '../../../services/card_collection_service.dart';
import '../../daily/reveal/reveal_spec.dart';
import '../../daily/widgets/card_reveal_overlay.dart';

/// Pushes the tiered gacha hero moment for [nameId] and completes when the user
/// dismisses it.
///
/// Same push shape as the muḥāsabah reveal (root navigator, named route so the
/// tour's `blockingRouteNames` guard still matches, opaque + non-dismissible).
/// **Visual only** — nothing here writes to the collection; the row is seeded
/// by `completeOnboarding` at the same tier.
///
/// A [nameId] with no catalog entry is a no-op rather than a crash: the ship
/// gate pins every deck's `name_id` to the catalog, so reaching that branch
/// means a hand-edited asset, and a missing card must not eat the reveal.
Future<void> pushOnboardingCardReveal(
  BuildContext context, {
  required int nameId,
  required CardTier tier,
  void Function(String name, Map<String, Object?> props)? onEvent,
}) async {
  final matches = allCollectibleNames.where((c) => c.id == nameId);
  if (matches.isEmpty) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  await navigator.push(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: CardRevealOverlay.routeName),
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => CardRevealOverlay(
        card: matches.first,
        spec: revealSpecFor(tier),
        onContinue: navigator.pop,
        onEvent: onEvent,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
