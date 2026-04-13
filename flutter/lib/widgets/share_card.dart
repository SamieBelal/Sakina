import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:share_plus/share_plus.dart';

/// Renders a beautiful share card for a reflection result and shares it.
/// On web, shows a preview overlay instead.
Future<void> shareReflectionCard({
  required BuildContext context,
  required String nameArabic,
  required String nameEnglish,
  required String duaArabic,
  required String duaTransliteration,
  required String duaTranslation,
  required String duaSource,
  String? story,
  String? reframe,
  Rect? sharePositionOrigin,
}) async {
  if (kIsWeb) {
    // Show preview on web
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            child: _ShareCardWidget(
                  nameArabic: nameArabic,
                  nameEnglish: nameEnglish,
                  duaArabic: duaArabic,
                  duaTransliteration: duaTransliteration,
                  duaTranslation: duaTranslation,
                  duaSource: duaSource,
                  story: story,
                  reframe: reframe,
                  preview: true,
                ),
          ),
        ),
      ),
    );
    return;
  }

  final key = GlobalKey();

  final overlay = OverlayEntry(
    builder: (_) => Positioned(
      left: -2000, // offscreen
      child: RepaintBoundary(
        key: key,
        child: _ShareCardWidget(
          nameArabic: nameArabic,
          nameEnglish: nameEnglish,
          duaArabic: duaArabic,
          duaTransliteration: duaTransliteration,
          duaTranslation: duaTranslation,
          duaSource: duaSource,
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlay);

  await Future.delayed(const Duration(milliseconds: 300));

  try {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = Directory.systemTemp;
    final file = File('${dir.path}/sakina_reflection.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Reflecting on $nameEnglish — from Sakina',
      sharePositionOrigin: sharePositionOrigin,
    );
  } finally {
    overlay.remove();
  }
}

class _ShareCardWidget extends StatelessWidget {
  const _ShareCardWidget({
    required this.nameArabic,
    required this.nameEnglish,
    required this.duaArabic,
    required this.duaTransliteration,
    required this.duaTranslation,
    required this.duaSource,
    this.story,
    this.reframe,
    this.preview = false,
  });

  final String nameArabic;
  final String nameEnglish;
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;
  final String duaSource;
  final String? story;
  final String? reframe;
  final bool preview;

  static const _emerald = Color(0xFF1B6B4A);
  static const _gold = Color(0xFFC8985E);
  static const _cream = Color(0xFFFBF7F2);

  /// Truncate story to first sentence or ~80 chars
  String get _shortStory {
    if (story == null || story!.isEmpty) return '';
    final s = story!;
    // First sentence
    final periodIdx = s.indexOf('. ');
    if (periodIdx > 0 && periodIdx < 120) return s.substring(0, periodIdx + 1);
    if (s.length <= 100) return s;
    return '${s.substring(0, 97)}...';
  }

  @override
  Widget build(BuildContext context) {
    // Scale factor: preview uses screen-friendly sizes, export uses 3x for high-res
    final double w = preview ? 380 : 1080;
    final double pad = preview ? 28 : 80;
    final double padV = preview ? 24 : 64;
    final double arabicSize = preview ? 48 : 100;
    final double englishSize = preview ? 18 : 30;
    final double storySize = preview ? 13 : 20;
    final double duaArabicSize = preview ? 22 : 38;
    final double translationSize = preview ? 14 : 22;
    final double sourceSize = preview ? 11 : 15;
    final double brandSize = preview ? 11 : 16;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: w,
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: padV),
        decoration: const BoxDecoration(
          color: _cream,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top branding
            Text(
              'SAKINA',
              style: AppTypography.labelLarge.copyWith(
                fontSize: brandSize,
                color: _emerald.withValues(alpha: 0.6),
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: preview ? 20 : 48),

            // Name of Allah — Arabic
            Text(
              nameArabic,
              style: AppTypography.nameOfAllahDisplay.copyWith(
                fontSize: arabicSize,
                color: _gold,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: _gold.withValues(alpha: 0.1),
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: preview ? 6 : 12),

            // Name — English
            Text(
              nameEnglish,
              style: AppTypography.headlineLarge.copyWith(
                fontSize: englishSize,
                color: const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: preview ? 16 : 36),

            // Short story (1 sentence max)
            if (_shortStory.isNotEmpty) ...[
              Text(
                _shortStory,
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: storySize,
                  color: const Color(0xFF6B7280),
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: preview ? 16 : 36),
            ],

            // Divider
            Container(width: preview ? 40 : 80, height: 1.5, color: _gold.withValues(alpha: 0.3)),
            SizedBox(height: preview ? 16 : 36),

            // Dua — Arabic
            Text(
              duaArabic,
              style: AppTypography.quranArabic.copyWith(
                fontSize: duaArabicSize,
                color: const Color(0xFF1A1A2E),
                height: 2.0,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: _gold.withValues(alpha: 0.1),
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: preview ? 12 : 24),

            // Translation
            Text(
              '"$duaTranslation"',
              style: AppTypography.bodyLarge.copyWith(
                fontSize: translationSize,
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: preview ? 6 : 12),

            // Source
            Text(
              duaSource,
              style: AppTypography.bodySmall.copyWith(
                fontSize: sourceSize,
                color: _emerald.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: preview ? 20 : 48),

            // Bottom line
            Container(width: preview ? 24 : 40, height: 1.5, color: _gold.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Built Dua share card
// ---------------------------------------------------------------------------

/// Share card specifically for built duas — shows 4 sections beautifully.
Future<void> shareBuiltDuaCard({
  required BuildContext context,
  required String need,
  required List<DuaShareSection> sections,
  required String translation,
  Rect? sharePositionOrigin,
}) async {
  if (kIsWeb) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            child: _BuiltDuaShareCard(
              need: need,
              sections: sections,
              translation: translation,
              preview: true,
            ),
          ),
        ),
      ),
    );
    return;
  }

  final key = GlobalKey();
  final overlay = OverlayEntry(
    builder: (_) => Positioned(
      left: -2000,
      child: RepaintBoundary(
        key: key,
        child: _BuiltDuaShareCard(
          need: need,
          sections: sections,
          translation: translation,
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlay);
  await Future.delayed(const Duration(milliseconds: 300));

  try {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = Directory.systemTemp;
    final file = File('${dir.path}/sakina_dua.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'A dua for $need — from Sakina',
      sharePositionOrigin: sharePositionOrigin,
    );
  } finally {
    overlay.remove();
  }
}

class DuaShareSection {
  final String label;
  final String arabic;
  const DuaShareSection({required this.label, required this.arabic});
}

/// Convenience to create sections from BuiltDuaSection list.
List<DuaShareSection> duaSectionsForShare(List sections) {
  return sections
      .map((s) => DuaShareSection(label: s.label as String, arabic: s.arabic as String))
      .toList();
}

class _BuiltDuaShareCard extends StatelessWidget {
  const _BuiltDuaShareCard({
    required this.need,
    required this.sections,
    required this.translation,
    this.preview = false,
  });

  final String need;
  final List<DuaShareSection> sections;
  final String translation;
  final bool preview;

  static const _emerald = Color(0xFF1B6B4A);
  static const _gold = Color(0xFFC8985E);
  static const _cream = Color(0xFFFBF7F2);

  @override
  Widget build(BuildContext context) {
    final double w = preview ? 380 : 1080;
    final double pad = preview ? 24 : 72;
    final double padV = preview ? 20 : 56;
    final double brandSize = preview ? 11 : 16;
    final double titleSize = preview ? 16 : 26;
    final double labelSize = preview ? 10 : 14;
    final double arabicSize = preview ? 20 : 34;
    final double translationSize = preview ? 13 : 20;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: w,
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: padV),
        decoration: const BoxDecoration(color: _cream),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branding
            Text(
              'SAKINA',
              style: AppTypography.labelLarge.copyWith(
                fontSize: brandSize,
                color: _emerald.withValues(alpha: 0.6),
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: preview ? 16 : 36),

            // Title — user's need
            Text(
              need,
              style: AppTypography.headlineMedium.copyWith(
                fontSize: titleSize,
                color: _gold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: preview ? 4 : 8),
            Container(width: preview ? 40 : 80, height: 1.5, color: _gold.withValues(alpha: 0.3)),
            SizedBox(height: preview ? 16 : 36),

            // 4 sections
            ...sections.map((section) => Padding(
              padding: EdgeInsets.only(bottom: preview ? 16 : 32),
              child: Column(
                children: [
                  // Section label
                  Text(
                    section.label.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: labelSize,
                      color: _gold,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: preview ? 8 : 16),
                  // Arabic
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: preview ? 16 : 40,
                      vertical: preview ? 14 : 28,
                    ),
                    decoration: BoxDecoration(
                      color: _emerald,
                      borderRadius: BorderRadius.circular(preview ? 12 : 20),
                    ),
                    child: Text(
                      section.arabic,
                      style: AppTypography.quranArabic.copyWith(
                        fontSize: arabicSize,
                        color: Colors.white,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )),

            // Divider
            Container(width: preview ? 40 : 80, height: 1.5, color: _gold.withValues(alpha: 0.3)),
            SizedBox(height: preview ? 12 : 24),

            // Translation
            Text(
              '"$translation"',
              style: AppTypography.bodyLarge.copyWith(
                fontSize: translationSize,
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: preview ? 20 : 48),

            // Bottom line
            Container(width: preview ? 24 : 40, height: 1.5, color: _gold.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
