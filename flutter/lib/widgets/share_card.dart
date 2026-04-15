import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:share_plus/share_plus.dart';

// ---------------------------------------------------------------------------
// Image export helper — shared by both reflection and dua share flows
// ---------------------------------------------------------------------------

Future<void> _exportAndShare({
  required GlobalKey repaintKey,
  required String shareText,
  required String fileName,
  Rect? sharePositionOrigin,
}) async {
  final boundary =
      repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final dir = Directory.systemTemp;
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: shareText,
    sharePositionOrigin: sharePositionOrigin,
  );
}

// ---------------------------------------------------------------------------
// Reflection share — opens a full-screen preview, then shares on tap
// ---------------------------------------------------------------------------

/// Opens a full-screen preview of the share card. User taps "Share" to export.
Future<void> shareReflectionCard({
  required BuildContext context,
  required String nameArabic,
  required String nameEnglish,
  required String duaArabic,
  required String duaTransliteration,
  required String duaTranslation,
  required String duaSource,
  List<ReflectVerse> verses = const [],
  String? story,
  String? reframe,
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
            child: ReflectionShareCard(
              nameArabic: nameArabic,
              nameEnglish: nameEnglish,
              verses: verses,
              duaArabic: duaArabic,
              duaTransliteration: duaTransliteration,
              duaTranslation: duaTranslation,
              duaSource: duaSource,
              preview: true,
            ),
          ),
        ),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _SharePreviewScreen(
        shareText: 'Reflecting on $nameEnglish — from Sakina',
        fileName: 'sakina_reflection.png',
        cardBuilder: (preview) => ReflectionShareCard(
          nameArabic: nameArabic,
          nameEnglish: nameEnglish,
          verses: verses,
          duaArabic: duaArabic,
          duaTransliteration: duaTransliteration,
          duaTranslation: duaTranslation,
          duaSource: duaSource,
          preview: preview,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Built Dua share — same full-screen preview pattern
// ---------------------------------------------------------------------------

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

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _SharePreviewScreen(
        shareText: 'A dua for $need — from Sakina',
        fileName: 'sakina_dua.png',
        cardBuilder: (preview) => _BuiltDuaShareCard(
          need: need,
          sections: sections,
          translation: translation,
          preview: preview,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Share preview screen — shows the card full-screen with a share button
// ---------------------------------------------------------------------------

class _SharePreviewScreen extends StatefulWidget {
  const _SharePreviewScreen({
    required this.shareText,
    required this.fileName,
    required this.cardBuilder,
  });

  final String shareText;
  final String fileName;

  /// Builds the card widget. `true` = screen-sized preview, `false` = hi-res export.
  final Widget Function(bool preview) cardBuilder;

  @override
  State<_SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<_SharePreviewScreen> {
  final _exportKey = GlobalKey();
  bool _exporting = false;

  Future<void> _share() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    HapticFeedback.mediumImpact();

    // Insert offscreen hi-res card for export
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: -2000,
        child: RepaintBoundary(
          key: _exportKey,
          child: widget.cardBuilder(false),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      final origin = box.localToGlobal(Offset.zero) & box.size;
      await _exportAndShare(
        repaintKey: _exportKey,
        shareText: widget.shareText,
        fileName: widget.fileName,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('[SHARE ERROR] $e');
    } finally {
      overlay.remove();
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 24),
                    color: AppColors.textSecondaryLight,
                  ),
                  const Spacer(),
                  Text(
                    'Preview',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Card preview — centered and scrollable
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.cardBuilder(true),
                  ),
                ),
              ),
            ),

            // Share button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _exporting ? null : _share,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(_exporting ? 'Preparing...' : 'Share'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    textStyle: AppTypography.labelLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reflection share card widget
// ---------------------------------------------------------------------------

class ReflectionShareCard extends StatelessWidget {
  const ReflectionShareCard({
    required this.nameArabic,
    required this.nameEnglish,
    this.verses = const [],
    required this.duaArabic,
    required this.duaTransliteration,
    required this.duaTranslation,
    required this.duaSource,
    this.preview = false,
    super.key,
  });

  final String nameArabic;
  final String nameEnglish;
  final List<ReflectVerse> verses;
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;
  final String duaSource;
  final bool preview;

  static const _emerald = Color(0xFF1B6B4A);
  static const _gold = Color(0xFFC8985E);
  static const _cream = Color(0xFFFBF7F2);

  @override
  Widget build(BuildContext context) {
    final primaryVerse = verses.isNotEmpty ? verses.first : null;
    final double w = preview ? 380 : 1080;
    final double pad = preview ? 28 : 80;
    final double padV = preview ? 24 : 64;
    final double arabicSize = preview ? 48 : 100;
    final double englishSize = preview ? 18 : 30;
    final double verseArabicSize = preview ? 24 : 42;
    final double verseTranslationSize = preview ? 14 : 22;
    final double verseReferenceSize = preview ? 11 : 16;
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

            if (primaryVerse != null) ...[
              Text(
                primaryVerse.arabic,
                style: AppTypography.quranArabic.copyWith(
                  fontSize: verseArabicSize,
                  color: const Color(0xFF1A1A2E),
                  height: 1.9,
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
              Text(
                '"${primaryVerse.translation}"',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: verseTranslationSize,
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: preview ? 6 : 12),
              Text(
                primaryVerse.reference,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: verseReferenceSize,
                  color: _emerald.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: preview ? 16 : 36),
            ],

            Container(
              width: preview ? 40 : 80,
              height: 1.5,
              color: _gold.withValues(alpha: 0.3),
            ),
            SizedBox(height: preview ? 16 : 36),

            if (duaArabic.trim().isNotEmpty) ...[
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
            ],

            if (duaTranslation.trim().isNotEmpty) ...[
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
            ],

            if (duaSource.trim().isNotEmpty) ...[
              Text(
                duaSource,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: sourceSize,
                  color: _emerald.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: preview ? 20 : 48),
            ] else
              SizedBox(height: preview ? 16 : 36),

            // Bottom line
            Container(
              width: preview ? 24 : 40,
              height: 1.5,
              color: _gold.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Built Dua share card
// ---------------------------------------------------------------------------

class DuaShareSection {
  final String label;
  final String arabic;
  const DuaShareSection({required this.label, required this.arabic});
}

/// Convenience to create sections from BuiltDuaSection list.
List<DuaShareSection> duaSectionsForShare(List sections) {
  return sections
      .map((s) =>
          DuaShareSection(label: s.label as String, arabic: s.arabic as String))
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
            Container(
                width: preview ? 40 : 80,
                height: 1.5,
                color: _gold.withValues(alpha: 0.3)),
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
                          borderRadius:
                              BorderRadius.circular(preview ? 12 : 20),
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
            Container(
                width: preview ? 40 : 80,
                height: 1.5,
                color: _gold.withValues(alpha: 0.3)),
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
            Container(
                width: preview ? 24 : 40,
                height: 1.5,
                color: _gold.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
