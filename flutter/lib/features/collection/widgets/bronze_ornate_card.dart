import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/widgets/share_card.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Bronze Ornate Tile (grid card)
// ═══════════════════════════════════════════════════════════════════════════════

class BronzeOrnateTile extends StatelessWidget {
  const BronzeOrnateTile({
    super.key,
    required this.arabic,
    required this.transliteration,
    this.unseen = false,
  });

  final String arabic;
  final String transliteration;
  final bool unseen;

  // Bronze palette
  static const _bgDark = Color(0xFF2A1F1A);
  static const _bgMid = Color(0xFF382A22);
  static const _bgInner = Color(0xFF2E2028);
  static const _bronzeBright = Color(0xFFD4A574);
  static const _bronzeCore = Color(0xFFCD7F32);
  static const _bronzeDim = Color(0xFF8B6338);
  static const _glowColor = Color(0xFFE8A154);
  static const _rubyRed = Color(0xFFCC3333);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: unseen ? 0.35 : 0.15),
              blurRadius: unseen ? 18 : 10,
              spreadRadius: unseen ? 2 : 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Dark warm gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 1.2,
                    colors: [_bgMid, _bgDark],
                  ),
                ),
              ),

              // Dark plum inner panel
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.08),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _bgInner,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _bronzeDim.withValues(alpha: 0.2), width: 0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Islamic pattern on inner panel only
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.08),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CustomPaint(
                          painter: _BronzePatternPainter(
                            color: _bronzeDim.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Ornate bronze border with corner studs
              Positioned.fill(
                child: CustomPaint(
                  painter: _BronzeOrnateBorderPainter(
                    borderColor: _bronzeCore.withValues(alpha: 0.6),
                    studColor: _bronzeBright.withValues(alpha: 0.8),
                    rubyColor: _rubyRed.withValues(alpha: 0.7),
                  ),
                ),
              ),

              // Center diamond frame + medallion
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final medallionSize = constraints.maxWidth * 0.48;
                    final diamondSize = constraints.maxWidth * 0.6;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        SizedBox(
                          width: diamondSize,
                          height: diamondSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Diamond shaped frame (rotated square)
                              Transform.rotate(
                                angle: pi / 4,
                                child: Container(
                                  width: medallionSize * 0.75,
                                  height: medallionSize * 0.75,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _bronzeCore.withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _glowColor.withValues(alpha: 0.15),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Inner ruby glow
                              Container(
                                width: medallionSize * 0.55,
                                height: medallionSize * 0.55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _rubyRed.withValues(alpha: unseen ? 0.15 : 0.08),
                                      _rubyRed.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              // Bronze ring
                              Container(
                                width: medallionSize * 0.6,
                                height: medallionSize * 0.6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _bronzeCore.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              // Arabic text — constrained to fit inside the circle
                              SizedBox(
                                width: medallionSize * 0.45,
                                height: medallionSize * 0.45,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    arabic,
                                    style: AppTypography.nameOfAllahDisplay.copyWith(
                                      fontSize: 17,
                                      color: _bronzeBright,
                                      shadows: [
                                        Shadow(color: _glowColor.withValues(alpha: 0.5), blurRadius: 10),
                                        Shadow(color: _glowColor.withValues(alpha: 0.2), blurRadius: 20),
                                      ],
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),

                        // Tier dot — only 1 filled for bronze
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final filled = i < 1;
                            return Container(
                              width: 4, height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled ? _bronzeBright : _bronzeDim.withValues(alpha: 0.3),
                                boxShadow: filled ? [
                                  BoxShadow(color: _glowColor.withValues(alpha: 0.4), blurRadius: 4),
                                ] : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 4),

                        // Transliteration
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            transliteration,
                            style: AppTypography.labelSmall.copyWith(
                              color: _bronzeCore.withValues(alpha: 0.7),
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
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bronze Ornate Detail Sheet (bottom sheet with real card data)
// ═══════════════════════════════════════════════════════════════════════════════

class BronzeOrnateDetailSheet extends StatelessWidget {
  const BronzeOrnateDetailSheet({
    super.key,
    required this.card,
    required this.tier,
  });

  final CollectibleName card;
  final CardTier tier;

  static const _bgDark = Color(0xFF2A1F1A);
  static const _bgMid = Color(0xFF382A22);
  static const _bronzeBright = Color(0xFFD4A574);
  static const _bronzeCore = Color(0xFFCD7F32);
  static const _bronzeDim = Color(0xFF8B6338);
  static const _glowColor = Color(0xFFE8A154);
  static const _rubyRed = Color(0xFFCC3333);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _glowColor.withValues(alpha: 0.18), blurRadius: 28, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Dark warm gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgMid, _bgDark, Color(0xFF1E1614)],
                ),
              ),
            ),

            // Pattern — subtle
            Positioned.fill(
              child: CustomPaint(
                painter: _BronzePatternPainter(
                  color: _bronzeDim.withValues(alpha: 0.03),
                  scale: 1.8,
                ),
              ),
            ),

            // Ornate detail border
            Positioned.fill(
              child: CustomPaint(
                painter: _BronzeOrnateDetailBorderPainter(
                  borderColor: _bronzeCore.withValues(alpha: 0.4),
                  accentColor: _bronzeBright.withValues(alpha: 0.5),
                  rubyColor: _rubyRed.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: _bronzeDim.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Large medallion with diamond frame
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer diamond frame
                        Transform.rotate(
                          angle: pi / 4,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: _bronzeCore.withValues(alpha: 0.4), width: 2),
                              boxShadow: [
                                BoxShadow(color: _glowColor.withValues(alpha: 0.15), blurRadius: 14, spreadRadius: 3),
                              ],
                            ),
                          ),
                        ),
                        // Ruby glow
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _rubyRed.withValues(alpha: 0.1),
                                _rubyRed.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                        // Bronze ring
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _bronzeCore.withValues(alpha: 0.5), width: 2),
                            boxShadow: [
                              BoxShadow(color: _glowColor.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 3),
                            ],
                          ),
                        ),
                        // Corner ruby studs on diamond
                        ..._buildDiamondStuds(75),
                        // Arabic — constrained inside the ring
                        SizedBox(
                          width: 60,
                          height: 50,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              card.arabic,
                              style: AppTypography.nameOfAllahDisplay.copyWith(
                                fontSize: 36,
                                color: _bronzeBright,
                                shadows: [
                                  Shadow(color: _glowColor.withValues(alpha: 0.6), blurRadius: 14),
                                  Shadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 28),
                                ],
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scaleXY(begin: 0.85, end: 1.0, duration: 800.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),

                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _bronzeCore.withValues(alpha: 0.3)),
                      color: _bronzeDim.withValues(alpha: 0.12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(3, (i) => Container(
                          width: 5, height: 5,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < tier.number ? _bronzeBright : _bronzeDim.withValues(alpha: 0.3),
                            boxShadow: i < tier.number ? [
                              BoxShadow(color: _glowColor.withValues(alpha: 0.4), blurRadius: 3),
                            ] : null,
                          ),
                        )),
                        const SizedBox(width: 6),
                        Text(
                          tier.label.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: _bronzeCore,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 16),

                  Text(card.transliteration, style: AppTypography.headlineMedium.copyWith(color: _bronzeBright))
                      .animate().fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 300.ms),
                  const SizedBox(height: 4),
                  Text(card.english, style: AppTypography.bodyMedium.copyWith(color: _bronzeBright.withValues(alpha: 0.7)))
                      .animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  const SizedBox(height: 24),

                  // Ornate divider
                  SizedBox(
                    height: 14,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _BronzeOrnateDividerPainter(
                        lineColor: _bronzeDim.withValues(alpha: 0.3),
                        accentColor: _bronzeBright.withValues(alpha: 0.5),
                        rubyColor: _rubyRed.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meaning tile (solid dark background for readability)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgDark.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _bronzeDim.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      card.meaning,
                      style: AppTypography.bodyMedium.copyWith(color: _bronzeBright.withValues(alpha: 0.9), height: 1.7),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lesson tile (solid dark green background for readability)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3D2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1B6B4A).withValues(alpha: 0.3)),
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

                  // Tier 2: Hadith / Prophetic Teaching
                  if (tier.number >= 2) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 14,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BronzeOrnateDividerPainter(
                          lineColor: _bronzeDim.withValues(alpha: 0.3),
                          accentColor: _bronzeBright.withValues(alpha: 0.5),
                          rubyColor: _rubyRed.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 3, height: 16,
                          decoration: BoxDecoration(
                            color: _bronzeBright,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'PROPHETIC TEACHING',
                          style: AppTypography.labelSmall.copyWith(
                            color: _bronzeCore,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _bgDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _bronzeDim.withValues(alpha: 0.15)),
                      ),
                      child: card.hasTier2Content
                          ? Text(
                              card.hadith,
                              style: AppTypography.bodyMedium.copyWith(
                                color: _bronzeBright.withValues(alpha: 0.85),
                                height: 1.7,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Text(
                              'Coming soon...',
                              style: AppTypography.bodySmall.copyWith(
                                color: _bronzeDim,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    ),
                  ],

                  // Tier 3: Dua
                  if (tier.number >= 3) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 14,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BronzeOrnateDividerPainter(
                          lineColor: _bronzeDim.withValues(alpha: 0.3),
                          accentColor: _bronzeBright.withValues(alpha: 0.5),
                          rubyColor: _rubyRed.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 3, height: 16,
                          decoration: BoxDecoration(
                            color: _bronzeBright,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'DUA',
                          style: AppTypography.labelSmall.copyWith(
                            color: _bronzeCore,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (card.hasTier3Content) ...[
                      // Dua Arabic
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _bronzeDim.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          card.duaArabic,
                          style: AppTypography.nameOfAllahDisplay.copyWith(
                            fontSize: 22,
                            color: _bronzeBright,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dua transliteration
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgDark.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _bronzeDim.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          card.duaTransliteration,
                          style: AppTypography.bodyMedium.copyWith(
                            color: _bronzeCore,
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dua translation
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3D2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1B6B4A).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          card.duaTranslation,
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFFA8DCBE),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Share button (tier 3 only)
                      SizedBox(
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
                          icon: Icon(Icons.share_rounded, size: 18, color: _bronzeBright),
                          label: Text(
                            'Share Reflection',
                            style: AppTypography.labelMedium.copyWith(color: _bronzeBright),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _bronzeCore.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _bronzeDim.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          'Coming soon...',
                          style: AppTypography.bodySmall.copyWith(
                            color: _bronzeDim,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],

                  // Upgrade hint
                  if (tier.number < 3) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      tier.number < 2
                          ? 'Encounter this Name again to unlock the Prophetic Teaching'
                          : 'Encounter this Name again to unlock the Dua',
                      style: AppTypography.bodySmall.copyWith(color: _bronzeDim),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  List<Widget> _buildDiamondStuds(double radius) {
    return [
      Positioned(
        top: 75 - radius + 2, left: 75 - 3,
        child: _rubyStud(),
      ),
      Positioned(
        bottom: 75 - radius + 2, left: 75 - 3,
        child: _rubyStud(),
      ),
      Positioned(
        left: 75 - radius + 2, top: 75 - 3,
        child: _rubyStud(),
      ),
      Positioned(
        right: 75 - radius + 2, top: 75 - 3,
        child: _rubyStud(),
      ),
    ];
  }

  Widget _rubyStud() {
    return Container(
      width: 6, height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFCC3333).withValues(alpha: 0.7),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE85555).withValues(alpha: 0.4), blurRadius: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bronze Pattern Painter (simpler, rougher feel)
// ═══════════════════════════════════════════════════════════════════════════════

class _BronzePatternPainter extends CustomPainter {
  _BronzePatternPainter({required this.color, this.scale = 1.0});
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7 * scale;

    final cellSize = 22.0 * scale;

    for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
      for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
        final cx = x + cellSize / 2;
        final cy = y + cellSize / 2;
        final r = cellSize * 0.35;

        // Simpler pattern — just the diamond + small cross
        final path = Path();
        path.moveTo(cx, cy - r);
        path.lineTo(cx + r, cy);
        path.lineTo(cx, cy + r);
        path.lineTo(cx - r, cy);
        path.close();

        canvas.drawPath(path, paint);

        // Small cross at center
        final crossSize = r * 0.3;
        canvas.drawLine(Offset(cx - crossSize, cy), Offset(cx + crossSize, cy), paint);
        canvas.drawLine(Offset(cx, cy - crossSize), Offset(cx, cy + crossSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bronze Ornate Border Painter (tile)
// ═══════════════════════════════════════════════════════════════════════════════

class _BronzeOrnateBorderPainter extends CustomPainter {
  _BronzeOrnateBorderPainter({
    required this.borderColor,
    required this.studColor,
    required this.rubyColor,
  });
  final Color borderColor;
  final Color studColor;
  final Color rubyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer border — thick and bold
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const inset = 2.5;
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(10),
    );
    canvas.drawRRect(borderRect, borderPaint);

    // Corner studs (circular bronze rivets)
    final studPaint = Paint()
      ..color = studColor
      ..style = PaintingStyle.fill;

    const studR = 3.5;
    const offset = inset + 5;
    // Four corners
    canvas.drawCircle(Offset(offset, offset), studR, studPaint);
    canvas.drawCircle(Offset(w - offset, offset), studR, studPaint);
    canvas.drawCircle(Offset(offset, h - offset), studR, studPaint);
    canvas.drawCircle(Offset(w - offset, h - offset), studR, studPaint);

    // Stud inner ring (gives a rivet look)
    final innerRingPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(offset, offset), studR - 1, innerRingPaint);
    canvas.drawCircle(Offset(w - offset, offset), studR - 1, innerRingPaint);
    canvas.drawCircle(Offset(offset, h - offset), studR - 1, innerRingPaint);
    canvas.drawCircle(Offset(w - offset, h - offset), studR - 1, innerRingPaint);

    // Mid-edge ruby accents
    final rubyPaint = Paint()
      ..color = rubyColor
      ..style = PaintingStyle.fill;
    const rs = 2.0;

    // Top & bottom center
    _drawDiamond(canvas, rubyPaint, w / 2, inset, rs);
    _drawDiamond(canvas, rubyPaint, w / 2, h - inset, rs);
    // Left & right center
    _drawDiamond(canvas, rubyPaint, inset, h / 2, rs);
    _drawDiamond(canvas, rubyPaint, w - inset, h / 2, rs);
  }

  void _drawDiamond(Canvas canvas, Paint paint, double cx, double cy, double s) {
    final path = Path()
      ..moveTo(cx, cy - s)
      ..lineTo(cx + s, cy)
      ..lineTo(cx, cy + s)
      ..lineTo(cx - s, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bronze Ornate Detail Border Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _BronzeOrnateDetailBorderPainter extends CustomPainter {
  _BronzeOrnateDetailBorderPainter({
    required this.borderColor,
    required this.accentColor,
    required this.rubyColor,
  });
  final Color borderColor;
  final Color accentColor;
  final Color rubyColor;

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

    // Corner studs
    final studPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    const studR = 4.0;
    const sOffset = inset + 6;
    canvas.drawCircle(Offset(sOffset, sOffset), studR, studPaint);
    canvas.drawCircle(Offset(w - sOffset, sOffset), studR, studPaint);
    canvas.drawCircle(Offset(sOffset, h - sOffset), studR, studPaint);
    canvas.drawCircle(Offset(w - sOffset, h - sOffset), studR, studPaint);

    // Inner rings
    final ringPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(sOffset, sOffset), studR - 1.2, ringPaint);
    canvas.drawCircle(Offset(w - sOffset, sOffset), studR - 1.2, ringPaint);
    canvas.drawCircle(Offset(sOffset, h - sOffset), studR - 1.2, ringPaint);
    canvas.drawCircle(Offset(w - sOffset, h - sOffset), studR - 1.2, ringPaint);

    // Top & bottom ruby diamonds
    final rubyPaint = Paint()
      ..color = rubyColor
      ..style = PaintingStyle.fill;
    const ds = 3.5;
    _drawDiamond(canvas, rubyPaint, w / 2, inset, ds);
    _drawDiamond(canvas, rubyPaint, w / 2, h - inset, ds);
  }

  void _drawDiamond(Canvas canvas, Paint paint, double cx, double cy, double s) {
    final path = Path()
      ..moveTo(cx, cy - s)
      ..lineTo(cx + s, cy)
      ..lineTo(cx, cy + s)
      ..lineTo(cx - s, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bronze Ornate Divider Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _BronzeOrnateDividerPainter extends CustomPainter {
  _BronzeOrnateDividerPainter({
    required this.lineColor,
    required this.accentColor,
    required this.rubyColor,
  });
  final Color lineColor;
  final Color accentColor;
  final Color rubyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final centerX = size.width / 2;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Center diamond (bronze)
    const ds = 5.0;
    final diamond = Path()
      ..moveTo(centerX, cy - ds)
      ..lineTo(centerX + ds, cy)
      ..lineTo(centerX, cy + ds)
      ..lineTo(centerX - ds, cy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = accentColor..style = PaintingStyle.fill);

    // Ruby center dot
    canvas.drawCircle(Offset(centerX, cy), 1.8, Paint()..color = rubyColor..style = PaintingStyle.fill);

    // Lines
    canvas.drawLine(Offset(16, cy), Offset(centerX - ds - 6, cy), linePaint);
    canvas.drawLine(Offset(centerX + ds + 6, cy), Offset(size.width - 16, cy), linePaint);

    // End studs (bronze circles instead of dots)
    final studPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(16, cy), 2, studPaint);
    canvas.drawCircle(Offset(size.width - 16, cy), 2, studPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
