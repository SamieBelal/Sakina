import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sakina/features/collection/widgets/bronze_ornate_card.dart';
import 'package:sakina/features/collection/widgets/silver_card_preview.dart';
import 'package:sakina/features/collection/widgets/gold_ornate_card.dart';
import 'package:sakina/features/collection/widgets/emerald_ornate_card.dart';
import 'package:sakina/features/daily/reveal/reveal_spec.dart';
import 'package:sakina/services/card_collection_service.dart';

/// The card FACE for a reveal — the tier's real collection tile.
///
/// Bronze and Silver tiles take raw strings rather than [CollectibleName];
/// we pass the card's fields directly. Gold and Emerald accept [CollectibleName]
/// natively.
Widget revealCardTile(CollectibleName card, CardTier tier) {
  switch (tier) {
    case CardTier.bronze:
      return BronzeOrnateTile(
          arabic: card.arabic, transliteration: card.transliteration);
    case CardTier.silver:
      return SilverOrnateTile(card: card);
    case CardTier.gold:
      return GoldOrnateTile(card: card);
    case CardTier.emerald:
      return EmeraldOrnateTile(card: card);
  }
}

/// A shared card BACK, tinted per tier (shown only for spinning tiers).
class RevealCardBack extends StatelessWidget {
  const RevealCardBack({super.key, required this.tier});
  final CardTier tier;

  @override
  Widget build(BuildContext context) {
    final p = tierPalette(tier);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.1,
          colors: [p.color.withValues(alpha: 0.35), const Color(0xFF0F1F16)],
        ),
        border: Border.all(color: p.bright.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
              color: p.glow.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 4),
        ],
      ),
      child: CustomPaint(painter: _BackPainter(p)),
    );
  }
}

class _BackPainter extends CustomPainter {
  _BackPainter(this.p);
  final TierPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.30;
    final line = Paint()
      ..color = p.bright.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2;
        final pt = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, line);
    }
    canvas.drawCircle(c, r * 0.62, line..strokeWidth = 1.0);
    canvas.drawCircle(c, 3, Paint()..color = p.bright);
  }

  @override
  bool shouldRepaint(covariant _BackPainter old) => false;
}
