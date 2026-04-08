import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Preview screen — Ornate gold collectible card inspired by
/// golden Hearthstone card backs with lotus flowers, gem accents,
/// and a glowing center vortex. Translated into Islamic aesthetics.
class GoldCardPreviewScreen extends StatelessWidget {
  const GoldCardPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1610),
      appBar: AppBar(
        title: Text('Gold Card — "Royal Ornate"',
            style: AppTypography.labelLarge.copyWith(color: const Color(0xFFE8D5A8))),
        backgroundColor: const Color(0xFF1A1610),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE8D5A8)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Grid tiles ──
            Text('Grid Tiles (3-up)', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFE8D5A8))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _GoldOrnateTile(arabic: 'الرَّحْمَنُ', transliteration: 'Ar-Rahman', unseen: true)),
                const SizedBox(width: 14),
                Expanded(child: _GoldOrnateTile(arabic: 'المَلِكُ', transliteration: 'Al-Malik', unseen: false)),
                const SizedBox(width: 14),
                Expanded(child: _GoldOrnateTile(arabic: 'القُدُّوسُ', transliteration: 'Al-Quddus', unseen: false)),
              ],
            ),

            const SizedBox(height: 48),

            // ── Comparison ──
            Text('Side-by-side: Current vs Ornate', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFE8D5A8))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Current', style: AppTypography.labelMedium.copyWith(color: const Color(0xFF9CA3AF))),
                      const SizedBox(height: 8),
                      _CurrentGoldTile(arabic: 'الرَّحْمَنُ', transliteration: 'Ar-Rahman'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text('Ornate', style: AppTypography.labelMedium.copyWith(color: const Color(0xFF9CA3AF))),
                      const SizedBox(height: 8),
                      _GoldOrnateTile(arabic: 'الرَّحْمَنُ', transliteration: 'Ar-Rahman', unseen: false),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // ── On light background ──
            Text('On Light Background (in-app)', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFE8D5A8))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: _GoldOrnateTile(arabic: 'الرَّحْمَنُ', transliteration: 'Ar-Rahman', unseen: true)),
                  const SizedBox(width: 14),
                  Expanded(child: _GoldOrnateTile(arabic: 'المَلِكُ', transliteration: 'Al-Malik', unseen: false)),
                  const SizedBox(width: 14),
                  Expanded(child: _GoldOrnateTile(arabic: 'القُدُّوسُ', transliteration: 'Al-Quddus', unseen: false)),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // ── Large single card ──
            Text('Single Card (Large)', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFE8D5A8))),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 200,
                child: _GoldOrnateTile(arabic: 'الوَدُودُ', transliteration: 'Al-Wadud', unseen: true),
              ),
            ),

            const SizedBox(height: 48),

            // ── Detail card ──
            Text('Detail Card (Bottom Sheet)', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFE8D5A8))),
            const SizedBox(height: 16),
            const _GoldOrnateDetailCard(),

            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Gold Ornate Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _GoldOrnateTile extends StatelessWidget {
  const _GoldOrnateTile({required this.arabic, required this.transliteration, this.unseen = false});

  final String arabic;
  final String transliteration;
  final bool unseen;

  // Gold palette
  static const _bgDark = Color(0xFF2C2618);        // dark warm brown
  static const _bgMid = Color(0xFF3A3122);          // slightly lighter
  static const _goldBright = Color(0xFFEDD9A3);     // bright gold for text
  static const _goldCore = Color(0xFFC8985E);       // mid gold (matches app secondary)
  static const _goldDim = Color(0xFF8B7340);         // dim gold for subtle elements
  static const _glowColor = Color(0xFFE8C56D);      // warm gold glow
  static const _gemBlue = Color(0xFF5B8DD9);         // blue gem accents
  static const _gemGlow = Color(0xFF7EB3F7);         // blue gem glow

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: unseen ? 0.45 : 0.2),
              blurRadius: unseen ? 22 : 12,
              spreadRadius: unseen ? 3 : 0,
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
              // ── Rich dark gradient background ──
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 1.1,
                    colors: [_bgMid, _bgDark],
                  ),
                ),
              ),

              // ── Islamic arabesque pattern ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _GoldArabesquePatternPainter(
                    color: _goldDim.withValues(alpha: 0.1),
                  ),
                ),
              ),

              // ── Ornate gold border with corner flourishes ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _GoldOrnateBorderPainter(
                    borderColor: _goldCore.withValues(alpha: 0.6),
                    flourishColor: _goldBright.withValues(alpha: 0.7),
                    gemColor: _gemBlue.withValues(alpha: 0.8),
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
                              // Warm gold glow
                              Container(
                                width: glowSize,
                                height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _glowColor.withValues(alpha: unseen ? 0.3 : 0.15),
                                      _glowColor.withValues(alpha: 0.05),
                                      _glowColor.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                              // Diamond-shaped frame around medallion
                              CustomPaint(
                                size: Size(medallionSize + 8, medallionSize + 8),
                                painter: _DiamondFramePainter(
                                  color: _goldCore.withValues(alpha: 0.5),
                                  gemColor: _gemBlue.withValues(alpha: 0.6),
                                ),
                              ),
                              // Gold ring
                              Container(
                                width: medallionSize,
                                height: medallionSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _goldCore.withValues(alpha: 0.7),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      arabic,
                                      style: AppTypography.nameOfAllahDisplay.copyWith(
                                        fontSize: 18,
                                        color: _goldBright,
                                        shadows: [
                                          Shadow(color: _glowColor.withValues(alpha: 0.7), blurRadius: 14),
                                          Shadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 28),
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

                        // Tier dots — all 3 filled for gold
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return Container(
                              width: 4, height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _goldBright,
                                boxShadow: [
                                  BoxShadow(color: _glowColor.withValues(alpha: 0.5), blurRadius: 4),
                                ],
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
                              color: _goldCore.withValues(alpha: 0.8),
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
// Current gold tile (for comparison)
// ═══════════════════════════════════════════════════════════════════════════════

class _CurrentGoldTile extends StatelessWidget {
  const _CurrentGoldTile({required this.arabic, required this.transliteration});

  final String arabic;
  final String transliteration;

  @override
  Widget build(BuildContext context) {
    const tierColor = Color(0xFFC8985E);

    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tierColor.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: tierColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  width: 5, height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tierColor,
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(arabic, style: AppTypography.nameOfAllahDisplay.copyWith(fontSize: 22, color: AppColors.secondary),
                textDirection: TextDirection.rtl, textAlign: TextAlign.center, maxLines: 1),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(transliteration, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight, fontSize: 9),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 2),
            Text('Gold', style: AppTypography.labelSmall.copyWith(color: tierColor, fontSize: 8, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Gold Ornate Detail Card
// ═══════════════════════════════════════════════════════════════════════════════

class _GoldOrnateDetailCard extends StatelessWidget {
  const _GoldOrnateDetailCard();

  static const _bgDark = Color(0xFF2C2618);
  static const _bgMid = Color(0xFF3A3122);
  static const _goldBright = Color(0xFFEDD9A3);
  static const _goldCore = Color(0xFFC8985E);
  static const _goldDim = Color(0xFF8B7340);
  static const _glowColor = Color(0xFFE8C56D);
  static const _gemBlue = Color(0xFF5B8DD9);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _glowColor.withValues(alpha: 0.2), blurRadius: 32, spreadRadius: 3),
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 8)),
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
                  colors: [_bgMid, _bgDark, Color(0xFF241F14)],
                ),
              ),
            ),

            // Arabesque pattern — kept subtle so text is readable
            Positioned.fill(
              child: CustomPaint(
                painter: _GoldArabesquePatternPainter(
                  color: _goldDim.withValues(alpha: 0.035),
                  scale: 1.8,
                ),
              ),
            ),

            // Ornate detail border
            Positioned.fill(
              child: CustomPaint(
                painter: _GoldOrnateDetailBorderPainter(
                  borderColor: _goldCore.withValues(alpha: 0.4),
                  accentColor: _goldBright.withValues(alpha: 0.5),
                  gemColor: _gemBlue.withValues(alpha: 0.6),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: _goldDim.withValues(alpha: 0.4),
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
                      border: Border.all(color: _goldCore.withValues(alpha: 0.6), width: 2.5),
                      boxShadow: [
                        BoxShadow(color: _glowColor.withValues(alpha: 0.25), blurRadius: 28, spreadRadius: 5),
                        BoxShadow(color: _goldCore.withValues(alpha: 0.15), blurRadius: 16),
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
                        // Diamond frame behind text
                        CustomPaint(
                          size: const Size(100, 100),
                          painter: _DiamondFramePainter(
                            color: _goldCore.withValues(alpha: 0.3),
                            gemColor: _gemBlue.withValues(alpha: 0.4),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'الرَّحْمَنُ',
                              style: AppTypography.nameOfAllahDisplay.copyWith(
                                fontSize: 40,
                                color: _goldBright,
                                shadows: [
                                  Shadow(color: _glowColor.withValues(alpha: 0.8), blurRadius: 18),
                                  Shadow(color: _glowColor.withValues(alpha: 0.4), blurRadius: 36),
                                ],
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _goldCore.withValues(alpha: 0.35)),
                      color: _goldDim.withValues(alpha: 0.15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(3, (i) => Container(
                          width: 5, height: 5,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _goldBright,
                            boxShadow: [
                              BoxShadow(color: _glowColor.withValues(alpha: 0.4), blurRadius: 3),
                            ],
                          ),
                        )),
                        const SizedBox(width: 6),
                        Text(
                          'GOLD',
                          style: AppTypography.labelSmall.copyWith(
                            color: _goldCore,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Ar-Rahman', style: AppTypography.headlineMedium.copyWith(color: _goldBright)),
                  const SizedBox(height: 4),
                  Text('The Most Gracious', style: AppTypography.bodyMedium.copyWith(color: _goldBright.withValues(alpha: 0.7))),
                  const SizedBox(height: 24),

                  // Ornate divider
                  SizedBox(
                    height: 14,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _GoldOrnateDividerPainter(
                        lineColor: _goldDim.withValues(alpha: 0.3),
                        accentColor: _goldBright.withValues(alpha: 0.5),
                        gemColor: _gemBlue.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Meaning tile ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgDark.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _goldDim.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      'Ar-Rahman refers to the vastness of Allah\'s mercy, which encompasses all of creation without exception.',
                      style: AppTypography.bodyMedium.copyWith(color: _goldBright.withValues(alpha: 0.9), height: 1.7),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Lesson tile ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3D2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1B6B4A).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Even when the world feels harsh, know that the Most Gracious has woven mercy into everything around you.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFFA8DCBE),
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ornate divider
                  SizedBox(
                    height: 14,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _GoldOrnateDividerPainter(
                        lineColor: _goldDim.withValues(alpha: 0.3),
                        accentColor: _goldBright.withValues(alpha: 0.5),
                        gemColor: _gemBlue.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Hadith tile ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgDark.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _goldDim.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3, height: 16,
                              decoration: BoxDecoration(
                                color: _goldBright,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(color: _glowColor.withValues(alpha: 0.4), blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'PROPHETIC TEACHING',
                              style: AppTypography.labelSmall.copyWith(
                                color: _goldCore,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '"When Allah completed the creation, He wrote in His Book which is with Him above the Throne: \'My mercy prevails over My wrath.\'"',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _goldBright.withValues(alpha: 0.85),
                            height: 1.7,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '— Sahih al-Bukhari',
                            style: AppTypography.bodySmall.copyWith(color: _goldBright.withValues(alpha: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ornate divider
                  SizedBox(
                    height: 14,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _GoldOrnateDividerPainter(
                        lineColor: _goldDim.withValues(alpha: 0.3),
                        accentColor: _goldBright.withValues(alpha: 0.5),
                        gemColor: _gemBlue.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Dua tile ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgDark.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _goldDim.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _gemBlue,
                                boxShadow: [
                                  BoxShadow(color: _gemBlue.withValues(alpha: 0.5), blurRadius: 6),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'DUA',
                              style: AppTypography.labelSmall.copyWith(
                                color: _goldBright,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
                          style: AppTypography.quranArabic.copyWith(
                            color: _goldBright,
                            fontSize: 22,
                            shadows: [
                              Shadow(color: _glowColor.withValues(alpha: 0.4), blurRadius: 10),
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Allahumma innaka \'afuwwun tuhibbul \'afwa fa\'fu \'anni',
                          style: AppTypography.bodyMedium.copyWith(color: _goldBright.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'O Allah, You are the Pardoner and You love to pardon, so pardon me.',
                          style: AppTypography.bodyMedium.copyWith(color: _goldBright.withValues(alpha: 0.75)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.share_outlined, size: 18, color: _goldBright),
                      label: Text('Share this Name', style: TextStyle(color: _goldBright)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _goldCore.withValues(alpha: 0.4)),
                        backgroundColor: _bgDark.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Gold Arabesque Pattern Painter (lotus/floral inspired)
// ═══════════════════════════════════════════════════════════════════════════════

class _GoldArabesquePatternPainter extends CustomPainter {
  _GoldArabesquePatternPainter({required this.color, this.scale = 1.0});
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
        final r = cellSize * 0.36;

        // 8-pointed star with curved petals
        final path = Path();

        // Inner overlapping squares (same as silver base)
        final s1 = r * 0.65;
        path.moveTo(cx - s1, cy - s1);
        path.lineTo(cx + s1, cy - s1);
        path.lineTo(cx + s1, cy + s1);
        path.lineTo(cx - s1, cy + s1);
        path.close();

        path.moveTo(cx, cy - r);
        path.lineTo(cx + r, cy);
        path.lineTo(cx, cy + r);
        path.lineTo(cx - r, cy);
        path.close();

        canvas.drawPath(path, paint);

        // Small petal curves at each cardinal direction (lotus hint)
        final petalPaint = Paint()
          ..color = color.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5 * scale;

        for (int d = 0; d < 4; d++) {
          final angle = d * pi / 2;
          final px = cx + cos(angle) * r * 1.1;
          final py = cy + sin(angle) * r * 1.1;
          final petalPath = Path();
          final pr = r * 0.25;
          petalPath.addOval(Rect.fromCircle(center: Offset(px, py), radius: pr));
          canvas.drawPath(petalPath, petalPaint);
        }

        // Center dot
        canvas.drawCircle(
          Offset(cx, cy),
          1.5 * scale,
          Paint()..color = color..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Gold Ornate Border Painter (tile)
// ═══════════════════════════════════════════════════════════════════════════════

class _GoldOrnateBorderPainter extends CustomPainter {
  _GoldOrnateBorderPainter({
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

    // Outer border — thicker for gold
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
      Rect.fromLTWH(innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
      const Radius.circular(7),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Corner flourishes (larger than silver)
    final flourishPaint = Paint()
      ..color = flourishColor
      ..style = PaintingStyle.fill;

    _drawGoldCorner(canvas, flourishPaint, inset + 1, inset + 1, 12, false, false);
    _drawGoldCorner(canvas, flourishPaint, w - inset - 1, inset + 1, 12, true, false);
    _drawGoldCorner(canvas, flourishPaint, inset + 1, h - inset - 1, 12, false, true);
    _drawGoldCorner(canvas, flourishPaint, w - inset - 1, h - inset - 1, 12, true, true);

    // Blue gem accents at mid-edges
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

  void _drawGoldCorner(Canvas canvas, Paint paint, double x, double y, double size, bool flipX, bool flipY) {
    final dx = flipX ? -1.0 : 1.0;
    final dy = flipY ? -1.0 : 1.0;

    // Larger diamond
    const ds = 4.0;
    final diamond = Path()
      ..moveTo(x, y - ds * dy)
      ..lineTo(x + ds * dx, y)
      ..lineTo(x, y + ds * dy)
      ..lineTo(x - ds * dx, y)
      ..close();
    canvas.drawPath(diamond, paint);

    // Extending flourish lines with curled ends
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
    // Small curl at end
    final hCurlEnd = Offset(x + size * dx * 0.7, y);
    canvas.drawCircle(hCurlEnd, 1.2, Paint()..color = paint.color..style = PaintingStyle.fill);

    // Vertical flourish
    canvas.drawLine(
      Offset(x, y + ds * dy * 1.2),
      Offset(x, y + size * dy * 0.7),
      linePaint,
    );
    final vCurlEnd = Offset(x, y + size * dy * 0.7);
    canvas.drawCircle(vCurlEnd, 1.2, Paint()..color = paint.color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Diamond Frame Painter (around medallion)
// ═══════════════════════════════════════════════════════════════════════════════

class _DiamondFramePainter extends CustomPainter {
  _DiamondFramePainter({required this.color, required this.gemColor});
  final Color color;
  final Color gemColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.5;

    // Rotated square (diamond) frame
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

    // Small gems at diamond points
    final gemPaint = Paint()
      ..color = gemColor
      ..style = PaintingStyle.fill;

    const gs = 2.0;
    for (final point in [Offset(cx, cy - r), Offset(cx + r, cy), Offset(cx, cy + r), Offset(cx - r, cy)]) {
      canvas.drawCircle(point, gs, gemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Gold Ornate Detail Border Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _GoldOrnateDetailBorderPainter extends CustomPainter {
  _GoldOrnateDetailBorderPainter({
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
      Rect.fromLTWH(innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
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
    canvas.drawCircle(Offset(w / 2, inset), 2, Paint()..color = gemColor..style = PaintingStyle.fill);

    // Diamond + gem at bottom
    _drawDiamond(canvas, accentPaint, w / 2, h - inset, ds);
    canvas.drawCircle(Offset(w / 2, h - inset), 2, Paint()..color = gemColor..style = PaintingStyle.fill);
  }

  void _drawDiamond(Canvas canvas, Paint paint, double cx, double cy, double size) {
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
// Gold Ornate Divider Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _GoldOrnateDividerPainter extends CustomPainter {
  _GoldOrnateDividerPainter({
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
    canvas.drawPath(diamond, Paint()..color = accentColor..style = PaintingStyle.fill);

    // Blue gem in center of diamond
    canvas.drawCircle(Offset(centerX, cy), 2, Paint()..color = gemColor..style = PaintingStyle.fill);

    // Lines
    canvas.drawLine(Offset(16, cy), Offset(centerX - ds - 6, cy), linePaint);
    canvas.drawLine(Offset(centerX + ds + 6, cy), Offset(size.width - 16, cy), linePaint);

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
      canvas.drawPath(sm, Paint()..color = lineColor..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
