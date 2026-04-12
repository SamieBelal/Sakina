import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/widgets/share_card.dart';

import 'ornate_card_shimmer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Emerald palette (shared across tile + detail)
// Premium-exclusive: deep forest green with gold accents
// ═══════════════════════════════════════════════════════════════════════════════

const _bgDark = Color(0xFF0F1F16);
const _bgMid = Color(0xFF1A3328);
const _emeraldBright = Color(0xFF7EEAAF);
const _emeraldCore = Color(0xFF3CB371);
const _emeraldDim = Color(0xFF2A6B4A);
const _glowColor = Color(0xFF4AE68A);
const _goldAccent = Color(0xFFC8985E);
const _goldBright = Color(0xFFEDD9A3);

// ═══════════════════════════════════════════════════════════════════════════════
// Emerald Preview Tile — lightweight version for store/marketing (strings only)
// ═══════════════════════════════════════════════════════════════════════════════

class EmeraldPreviewTile extends StatelessWidget {
  const EmeraldPreviewTile({
    super.key,
    required this.arabic,
    required this.transliteration,
    this.unseen = false,
    this.shimmer,
  });

  final String arabic;
  final String transliteration;
  final bool unseen;
  final OrnateCardShimmer? shimmer;

  @override
  Widget build(BuildContext context) {
    final bool isShimmering = shimmer?.enabled ?? unseen;

    final Widget tile = AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: isShimmering ? 0.45 : 0.2),
              blurRadius: isShimmering ? 22 : 12,
              spreadRadius: isShimmering ? 3 : 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 1.1,
                    colors: [_bgMid, _bgDark],
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _EmeraldInterlacePatternPainter(
                    color: _emeraldDim.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _EmeraldOrnateBorderPainter(
                    borderColor: _goldAccent.withValues(alpha: 0.6),
                    flourishColor: _goldBright.withValues(alpha: 0.7),
                    gemColor: _emeraldCore.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final medallionSize = constraints.maxWidth * 0.52;
                    final glowSize = medallionSize + 20;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        SizedBox(
                          width: glowSize,
                          height: glowSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: glowSize,
                                height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _glowColor.withValues(
                                          alpha: isShimmering ? 0.3 : 0.15),
                                      _glowColor.withValues(alpha: 0.05),
                                      _glowColor.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size:
                                    Size(medallionSize + 8, medallionSize + 8),
                                painter: _TrefoilFramePainter(
                                  color: _goldAccent.withValues(alpha: 0.5),
                                  gemColor:
                                      _emeraldCore.withValues(alpha: 0.6),
                                ),
                              ),
                              Container(
                                width: medallionSize,
                                height: medallionSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _goldAccent.withValues(alpha: 0.7),
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          _glowColor.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      arabic,
                                      style: AppTypography.nameOfAllahDisplay
                                          .copyWith(
                                        fontSize: 18,
                                        color: _emeraldBright,
                                        shadows: [
                                          Shadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.7),
                                              blurRadius: 14),
                                          Shadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.3),
                                              blurRadius: 28),
                                        ],
                                      ),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(3, (i) {
                              return Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _goldBright,
                                  boxShadow: [
                                    BoxShadow(
                                        color: _goldAccent.withValues(
                                            alpha: 0.5),
                                        blurRadius: 4),
                                  ],
                                ),
                              );
                            }),
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(left: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _emeraldBright,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          _glowColor.withValues(alpha: 0.6),
                                      blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            transliteration,
                            style: AppTypography.labelSmall.copyWith(
                              color: _goldAccent.withValues(alpha: 0.8),
                              fontSize: 8,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return applyOrnateCardShimmer(
      child: tile,
      color: _glowColor.withValues(alpha: 0.2),
      legacyEnabled: unseen,
      shimmer: shimmer,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Emerald Ornate Tile
// ═══════════════════════════════════════════════════════════════════════════════

class EmeraldOrnateTile extends StatelessWidget {
  const EmeraldOrnateTile({
    super.key,
    required this.card,
    this.unseen = false,
    this.shimmer,
  });

  final CollectibleName card;
  final bool unseen;
  final OrnateCardShimmer? shimmer;

  @override
  Widget build(BuildContext context) {
    final bool isShimmering = shimmer?.enabled ?? unseen;

    final Widget tile = AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: isShimmering ? 0.45 : 0.2),
              blurRadius: isShimmering ? 22 : 12,
              spreadRadius: isShimmering ? 3 : 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // ── Deep forest gradient background ──
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 1.1,
                    colors: [_bgMid, _bgDark],
                  ),
                ),
              ),

              // ── Islamic interlace pattern ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _EmeraldInterlacePatternPainter(
                    color: _emeraldDim.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // ── Ornate border with gold flourishes ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _EmeraldOrnateBorderPainter(
                    borderColor: _goldAccent.withValues(alpha: 0.6),
                    flourishColor: _goldBright.withValues(alpha: 0.7),
                    gemColor: _emeraldCore.withValues(alpha: 0.8),
                  ),
                ),
              ),

              // ── Center medallion ──
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final medallionSize = constraints.maxWidth * 0.52;
                    final glowSize = medallionSize + 20;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        SizedBox(
                          width: glowSize,
                          height: glowSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Emerald glow
                              Container(
                                width: glowSize,
                                height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _glowColor.withValues(
                                          alpha: isShimmering ? 0.3 : 0.15),
                                      _glowColor.withValues(alpha: 0.05),
                                      _glowColor.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                              // Trefoil frame around medallion
                              CustomPaint(
                                size:
                                    Size(medallionSize + 8, medallionSize + 8),
                                painter: _TrefoilFramePainter(
                                  color: _goldAccent.withValues(alpha: 0.5),
                                  gemColor: _emeraldCore.withValues(alpha: 0.6),
                                ),
                              ),
                              // Gold ring
                              Container(
                                width: medallionSize,
                                height: medallionSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _goldAccent.withValues(alpha: 0.7),
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _glowColor.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Arabic text
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      card.arabic,
                                      style: AppTypography.nameOfAllahDisplay
                                          .copyWith(
                                        fontSize: 18,
                                        color: _emeraldBright,
                                        shadows: [
                                          Shadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.7),
                                              blurRadius: 14),
                                          Shadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.3),
                                              blurRadius: 28),
                                        ],
                                      ),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),

                        // Tier dots — all 3 filled + emerald crown dot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(3, (i) {
                              return Container(
                                width: 4,
                                height: 4,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _goldBright,
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            _goldAccent.withValues(alpha: 0.5),
                                        blurRadius: 4),
                                  ],
                                ),
                              );
                            }),
                            // Extra emerald dot — premium indicator
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(left: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _emeraldBright,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          _glowColor.withValues(alpha: 0.6),
                                      blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Transliteration
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            card.transliteration,
                            style: AppTypography.labelSmall.copyWith(
                              color: _goldAccent.withValues(alpha: 0.8),
                              fontSize: 8,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const Spacer(flex: 1),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return applyOrnateCardShimmer(
      child: tile,
      color: _glowColor.withValues(alpha: 0.2),
      legacyEnabled: unseen,
      shimmer: shimmer,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Emerald Ornate Detail Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class EmeraldOrnateDetailSheet extends StatelessWidget {
  const EmeraldOrnateDetailSheet(
      {super.key, required this.card, required this.tier});

  final CollectibleName card;
  final CardTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _glowColor.withValues(alpha: 0.2),
              blurRadius: 32,
              spreadRadius: 3),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Dark emerald gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgMid, _bgDark, Color(0xFF0A1710)],
                ),
              ),
            ),

            // Interlace pattern — kept subtle
            Positioned.fill(
              child: CustomPaint(
                painter: _EmeraldInterlacePatternPainter(
                  color: _emeraldDim.withValues(alpha: 0.04),
                  scale: 1.8,
                ),
              ),
            ),

            // Ornate detail border
            Positioned.fill(
              child: CustomPaint(
                painter: _EmeraldOrnateDetailBorderPainter(
                  borderColor: _goldAccent.withValues(alpha: 0.4),
                  accentColor: _goldBright.withValues(alpha: 0.5),
                  gemColor: _emeraldCore.withValues(alpha: 0.6),
                ),
              ),
            ),

            // Content + sticky footer
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _emeraldDim.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Large medallion
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _goldAccent.withValues(alpha: 0.6),
                                width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: _glowColor.withValues(alpha: 0.25),
                                  blurRadius: 28,
                                  spreadRadius: 5),
                              BoxShadow(
                                  color: _emeraldCore.withValues(alpha: 0.15),
                                  blurRadius: 16),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Inner glow
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _glowColor.withValues(alpha: 0.15),
                                      _glowColor.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              // Trefoil frame behind text
                              CustomPaint(
                                size: const Size(100, 100),
                                painter: _TrefoilFramePainter(
                                  color: _goldAccent.withValues(alpha: 0.3),
                                  gemColor:
                                      _emeraldCore.withValues(alpha: 0.4),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    card.arabic,
                                    style: AppTypography.nameOfAllahDisplay
                                        .copyWith(
                                      fontSize: 40,
                                      color: _emeraldBright,
                                      shadows: [
                                        Shadow(
                                            color: _glowColor.withValues(
                                                alpha: 0.8),
                                            blurRadius: 18),
                                        Shadow(
                                            color: _glowColor.withValues(
                                                alpha: 0.4),
                                            blurRadius: 36),
                                      ],
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 800.ms).scaleXY(
                            begin: 0.85,
                            end: 1.0,
                            duration: 800.ms,
                            curve: Curves.easeOutBack),
                        const SizedBox(height: 16),

                        // Tier badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _goldAccent.withValues(alpha: 0.35)),
                            color: _emeraldDim.withValues(alpha: 0.15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(
                                  3,
                                  (i) => Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.only(right: 3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i < tier.number
                                              ? _goldBright
                                              : _emeraldDim.withValues(
                                                  alpha: 0.3),
                                          boxShadow: i < tier.number
                                              ? [
                                                  BoxShadow(
                                                      color: _goldAccent
                                                          .withValues(
                                                              alpha: 0.4),
                                                      blurRadius: 3),
                                                ]
                                              : null,
                                        ),
                                      )),
                              // Extra emerald dot
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _emeraldBright,
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            _glowColor.withValues(alpha: 0.5),
                                        blurRadius: 3),
                                  ],
                                ),
                              ),
                              Text(
                                'EMERALD',
                                style: AppTypography.labelSmall.copyWith(
                                  color: _emeraldCore,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                        const SizedBox(height: 16),

                        Text(card.transliteration,
                                style: AppTypography.headlineMedium
                                    .copyWith(color: _emeraldBright))
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 300.ms)
                            .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 500.ms,
                                delay: 300.ms),
                        const SizedBox(height: 4),
                        Text(card.english,
                                style: AppTypography.bodyMedium.copyWith(
                                    color:
                                        _emeraldBright.withValues(alpha: 0.7)))
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 400.ms),
                        const SizedBox(height: 24),

                        // Ornate divider
                        _buildOrnateDivider(),
                        const SizedBox(height: 16),

                        // ── Meaning tile ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _bgDark.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _emeraldDim.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            card.meaning,
                            style: AppTypography.bodyMedium.copyWith(
                                color: _emeraldBright.withValues(alpha: 0.9),
                                height: 1.7),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Lesson tile ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2A1C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _emeraldCore.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            card.lesson,
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFFA8DCBE),
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // ── Tier 2+: Hadith ──
                        if (tier.number >= 2) ...[
                          const SizedBox(height: 24),
                          _buildOrnateDivider(),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _bgDark.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _emeraldDim.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _goldBright,
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                              color: _goldAccent.withValues(
                                                  alpha: 0.4),
                                              blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'PROPHETIC TEACHING',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: _goldAccent,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (card.hasTier2Content)
                                  Text(
                                    card.hadith,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: _emeraldBright.withValues(
                                          alpha: 0.85),
                                      height: 1.7,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else
                                  Text(
                                    'Coming soon...',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: _emeraldDim,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // ── Tier 3: Dua ──
                        if (tier.number >= 3 && card.hasTier3Content) ...[
                          const SizedBox(height: 24),
                          _buildOrnateDivider(),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _bgDark.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _emeraldDim.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _emeraldCore,
                                        boxShadow: [
                                          BoxShadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.5),
                                              blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'DUA',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: _emeraldBright,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  card.duaArabic,
                                  style: AppTypography.quranArabic.copyWith(
                                    color: _emeraldBright,
                                    fontSize: 22,
                                    shadows: [
                                      Shadow(
                                          color: _glowColor.withValues(
                                              alpha: 0.4),
                                          blurRadius: 10),
                                    ],
                                  ),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  card.duaTransliteration,
                                  style: AppTypography.bodyMedium.copyWith(
                                      color: _emeraldBright.withValues(
                                          alpha: 0.8),
                                      fontStyle: FontStyle.italic),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card.duaTranslation,
                                  style: AppTypography.bodyMedium.copyWith(
                                      color: _emeraldBright.withValues(
                                          alpha: 0.75)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Sticky footer
                if (tier.number < 3)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Text(
                      'Encounter this Name again to unlock the Dua',
                      style: AppTypography.bodySmall
                          .copyWith(color: _emeraldDim),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (tier.number >= 3 && card.hasTier3Content)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          shareReflectionCard(
                            context: context,
                            nameArabic: card.arabic,
                            nameEnglish: card.english,
                            duaArabic: card.duaArabic,
                            duaTransliteration: card.duaTransliteration,
                            duaTranslation: card.duaTranslation,
                            duaSource: '',
                          );
                        },
                        icon: const Icon(
                          Icons.share_outlined,
                          size: 18,
                          color: _emeraldBright,
                        ),
                        label: const Text(
                          'Share this Name',
                          style: TextStyle(color: _emeraldBright),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: _goldAccent.withValues(alpha: 0.4)),
                          backgroundColor: _bgDark.withValues(alpha: 0.7),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),

            // Dismiss button
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: _emeraldBright.withValues(alpha: 0.8), size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  Widget _buildOrnateDivider() {
    return SizedBox(
      height: 14,
      width: double.infinity,
      child: CustomPaint(
        painter: _EmeraldOrnateDividerPainter(
          lineColor: _emeraldDim.withValues(alpha: 0.3),
          accentColor: _goldBright.withValues(alpha: 0.5),
          gemColor: _emeraldCore.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Emerald Interlace Pattern Painter
// Six-pointed star interlace — distinct from bronze (grid), silver (squares),
// and gold (arabesque). Evokes classic Islamic geometric interlacing.
// ═══════════════════════════════════════════════════════════════════════════════

class _EmeraldInterlacePatternPainter extends CustomPainter {
  _EmeraldInterlacePatternPainter({required this.color, this.scale = 1.0});
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7 * scale;

    final cellSize = 24.0 * scale;
    final r = cellSize * 0.38;

    for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
      for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
        final cx = x + cellSize / 2;
        final cy = y + cellSize / 2;

        // Six-pointed star (two overlapping triangles)
        final path = Path();

        // Upward triangle
        path.moveTo(cx, cy - r);
        path.lineTo(cx + r * cos(pi / 6), cy + r * sin(pi / 6));
        path.lineTo(cx - r * cos(pi / 6), cy + r * sin(pi / 6));
        path.close();

        // Downward triangle
        path.moveTo(cx, cy + r);
        path.lineTo(cx + r * cos(pi / 6), cy - r * sin(pi / 6));
        path.lineTo(cx - r * cos(pi / 6), cy - r * sin(pi / 6));
        path.close();

        canvas.drawPath(path, paint);

        // Connecting hexagonal ring
        final hexPaint = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4 * scale;

        final hexPath = Path();
        final hr = r * 0.55;
        for (int i = 0; i < 6; i++) {
          final angle = i * pi / 3 - pi / 6;
          final px = cx + hr * cos(angle);
          final py = cy + hr * sin(angle);
          if (i == 0) {
            hexPath.moveTo(px, py);
          } else {
            hexPath.lineTo(px, py);
          }
        }
        hexPath.close();
        canvas.drawPath(hexPath, hexPaint);

        // Center dot
        canvas.drawCircle(
          Offset(cx, cy),
          1.2 * scale,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Emerald Ornate Border Painter (tile)
// Gold border with emerald gem accents — the key visual distinction
// ═══════════════════════════════════════════════════════════════════════════════

class _EmeraldOrnateBorderPainter extends CustomPainter {
  _EmeraldOrnateBorderPainter({
    required this.borderColor,
    required this.flourishColor,
    required this.gemColor,
  });
  final Color borderColor;
  final Color flourishColor;
  final Color gemColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer border — gold on emerald
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const inset = 3.0;
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(9),
    );
    canvas.drawRRect(borderRect, borderPaint);

    // Inner border
    final innerPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const innerInset = 6.5;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
      const Radius.circular(7),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Corner trefoil flourishes
    final flourishPaint = Paint()
      ..color = flourishColor
      ..style = PaintingStyle.fill;

    _drawEmeraldCorner(
        canvas, flourishPaint, inset + 1, inset + 1, 12, false, false);
    _drawEmeraldCorner(
        canvas, flourishPaint, w - inset - 1, inset + 1, 12, true, false);
    _drawEmeraldCorner(
        canvas, flourishPaint, inset + 1, h - inset - 1, 12, false, true);
    _drawEmeraldCorner(
        canvas, flourishPaint, w - inset - 1, h - inset - 1, 12, true, true);

    // Emerald gem accents at mid-edges
    final gemPaint = Paint()
      ..color = gemColor
      ..style = PaintingStyle.fill;

    final gemGlowPaint = Paint()
      ..color = gemColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Top center gem
    canvas.drawCircle(Offset(w / 2, inset), 2.5, gemGlowPaint);
    canvas.drawCircle(Offset(w / 2, inset), 1.8, gemPaint);
    // Bottom center gem
    canvas.drawCircle(Offset(w / 2, h - inset), 2.5, gemGlowPaint);
    canvas.drawCircle(Offset(w / 2, h - inset), 1.8, gemPaint);
    // Left center gem
    canvas.drawCircle(Offset(inset, h / 2), 2.5, gemGlowPaint);
    canvas.drawCircle(Offset(inset, h / 2), 1.8, gemPaint);
    // Right center gem
    canvas.drawCircle(Offset(w - inset, h / 2), 2.5, gemGlowPaint);
    canvas.drawCircle(Offset(w - inset, h / 2), 1.8, gemPaint);
  }

  void _drawEmeraldCorner(Canvas canvas, Paint paint, double x, double y,
      double size, bool flipX, bool flipY) {
    final dx = flipX ? -1.0 : 1.0;
    final dy = flipY ? -1.0 : 1.0;

    // Center diamond with trefoil shape
    const ds = 4.0;
    final diamond = Path()
      ..moveTo(x, y - ds * dy)
      ..lineTo(x + ds * dx, y)
      ..lineTo(x, y + ds * dy)
      ..lineTo(x - ds * dx, y)
      ..close();
    canvas.drawPath(diamond, paint);

    // Extending flourish lines with leaf-shaped ends
    final linePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Horizontal flourish
    canvas.drawLine(
      Offset(x + ds * dx * 1.2, y),
      Offset(x + size * dx * 0.7, y),
      linePaint,
    );
    // Leaf tip at end
    final hEnd = Offset(x + size * dx * 0.7, y);
    _drawLeafTip(canvas, hEnd, paint.color, dx > 0 ? 0 : pi);

    // Vertical flourish
    canvas.drawLine(
      Offset(x, y + ds * dy * 1.2),
      Offset(x, y + size * dy * 0.7),
      linePaint,
    );
    final vEnd = Offset(x, y + size * dy * 0.7);
    _drawLeafTip(canvas, vEnd, paint.color, dy > 0 ? pi / 2 : -pi / 2);
  }

  void _drawLeafTip(Canvas canvas, Offset center, Color color, double angle) {
    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const leafSize = 2.5;
    final path = Path();
    path.moveTo(
      center.dx + cos(angle) * leafSize,
      center.dy + sin(angle) * leafSize,
    );
    path.quadraticBezierTo(
      center.dx + cos(angle + pi / 2) * leafSize * 0.6,
      center.dy + sin(angle + pi / 2) * leafSize * 0.6,
      center.dx - cos(angle) * leafSize * 0.3,
      center.dy - sin(angle) * leafSize * 0.3,
    );
    path.quadraticBezierTo(
      center.dx + cos(angle - pi / 2) * leafSize * 0.6,
      center.dy + sin(angle - pi / 2) * leafSize * 0.6,
      center.dx + cos(angle) * leafSize,
      center.dy + sin(angle) * leafSize,
    );
    canvas.drawPath(path, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Trefoil Frame Painter (around medallion — replaces diamond frame)
// A trefoil (3-lobed clover) evokes Islamic arch motifs
// ═══════════════════════════════════════════════════════════════════════════════

class _TrefoilFramePainter extends CustomPainter {
  _TrefoilFramePainter({required this.color, required this.gemColor});
  final Color color;
  final Color gemColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.5;

    // Rotated square (diamond) frame — base shape
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final diamond = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    canvas.drawPath(diamond, paint);

    // Small trefoil arches at each diamond point
    final archPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 - pi / 2;
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r;
      final archR = r * 0.12;

      // Small arch/bump at each point
      final archPath = Path();
      archPath.addOval(
          Rect.fromCircle(center: Offset(px, py), radius: archR));
      canvas.drawPath(archPath, archPaint);
    }

    // Emerald gems at diamond points
    final gemPaint = Paint()
      ..color = gemColor
      ..style = PaintingStyle.fill;

    const gs = 2.0;
    for (final point in [
      Offset(cx, cy - r),
      Offset(cx + r, cy),
      Offset(cx, cy + r),
      Offset(cx - r, cy)
    ]) {
      canvas.drawCircle(point, gs, gemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Emerald Ornate Detail Border Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _EmeraldOrnateDetailBorderPainter extends CustomPainter {
  _EmeraldOrnateDetailBorderPainter({
    required this.borderColor,
    required this.accentColor,
    required this.gemColor,
  });
  final Color borderColor;
  final Color accentColor;
  final Color gemColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer frame
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const inset = 6.0;
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(14),
    );
    canvas.drawRRect(outerRect, borderPaint);

    // Inner frame
    final innerPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const innerInset = 10.0;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
      const Radius.circular(12),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Top & bottom center ornaments
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Diamond + gem at top
    const ds = 4.0;
    _drawDiamond(canvas, accentPaint, w / 2, inset, ds);
    canvas.drawCircle(
        Offset(w / 2, inset),
        2,
        Paint()
          ..color = gemColor
          ..style = PaintingStyle.fill);

    // Diamond + gem at bottom
    _drawDiamond(canvas, accentPaint, w / 2, h - inset, ds);
    canvas.drawCircle(
        Offset(w / 2, h - inset),
        2,
        Paint()
          ..color = gemColor
          ..style = PaintingStyle.fill);
  }

  void _drawDiamond(
      Canvas canvas, Paint paint, double cx, double cy, double size) {
    final path = Path()
      ..moveTo(cx, cy - size)
      ..lineTo(cx + size, cy)
      ..lineTo(cx, cy + size)
      ..lineTo(cx - size, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Emerald Ornate Divider Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _EmeraldOrnateDividerPainter extends CustomPainter {
  _EmeraldOrnateDividerPainter({
    required this.lineColor,
    required this.accentColor,
    required this.gemColor,
  });
  final Color lineColor;
  final Color accentColor;
  final Color gemColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final centerX = size.width / 2;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Center diamond (gold)
    const ds = 5.0;
    final diamond = Path()
      ..moveTo(centerX, cy - ds)
      ..lineTo(centerX + ds, cy)
      ..lineTo(centerX, cy + ds)
      ..lineTo(centerX - ds, cy)
      ..close();
    canvas.drawPath(
        diamond,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.fill);

    // Emerald gem in center
    canvas.drawCircle(
        Offset(centerX, cy),
        2,
        Paint()
          ..color = gemColor
          ..style = PaintingStyle.fill);

    // Lines
    canvas.drawLine(Offset(16, cy), Offset(centerX - ds - 6, cy), linePaint);
    canvas.drawLine(
        Offset(centerX + ds + 6, cy), Offset(size.width - 16, cy), linePaint);

    // End flourishes
    final dotPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(16, cy), 1.5, dotPaint);
    canvas.drawCircle(Offset(size.width - 16, cy), 1.5, dotPaint);

    // Small diamonds at quarter points
    const sds = 2.5;
    for (final px in [size.width * 0.28, size.width * 0.72]) {
      final sm = Path()
        ..moveTo(px, cy - sds)
        ..lineTo(px + sds, cy)
        ..lineTo(px, cy + sds)
        ..lineTo(px - sds, cy)
        ..close();
      canvas.drawPath(
          sm,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
