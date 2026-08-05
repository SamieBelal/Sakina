import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/widgets/beat_reveal/mihrab_arch_frame.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sakina/core/constants/app_durations.dart';

// ---------------------------------------------------------------------------
// Image export helper — shared by both reflection and dua share flows
// ---------------------------------------------------------------------------

/// Rasterizes one already-mounted [RepaintBoundary] to a PNG in the temp dir.
Future<XFile> _exportPng({
  required GlobalKey repaintKey,
  required String fileName,
}) async {
  final boundary =
      repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final dir = Directory.systemTemp;
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  return XFile(file.path);
}

/// The Sakina brand mark for share cards: the calligraphic **س** glyph
/// (recolored from the transparent glyph asset via `srcIn`). A pure monogram —
/// no wordmark — pinned top-left as a corner brand tag (off the center axis so
/// it doesn't stack under the Arabic name).
class ShareBrandLockup extends StatelessWidget {
  const ShareBrandLockup({
    required this.preview,
    required this.markColor,
    super.key,
  });

  final bool preview;
  final Color markColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/sakina_mark.png',
      height: preview ? 15 : 32,
      color: markColor,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
    );
  }
}

// Shows a uniform "couldn't share" SnackBar. Called by every share IconButton's
// catch block so the user sees consistent feedback when share fails.
void showShareErrorSnackBar(ScaffoldMessengerState messenger) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(duration: kSnackBarDuration, content: Text("Couldn't share. Please try again.")),
    );
}

// ---------------------------------------------------------------------------
// Reflection share — opens a full-screen preview, then shares on tap
// ---------------------------------------------------------------------------

/// Signature of [shareReflectionCard]. Exposed so tests can swap in a
/// throwing fake to exercise the catch-block snackbar wiring on every share
/// IconButton without needing a real Navigator+RepaintBoundary export.
typedef ShareReflectionFn = Future<void> Function({
  required BuildContext context,
  required String nameArabic,
  required String nameEnglish,
  required String duaArabic,
  required String duaTransliteration,
  required String duaTranslation,
  required String duaSource,
  List<ReflectVerse> verses,
  String? story,
  String? reframe,
  Rect? sharePositionOrigin,
});

/// Opens a full-screen preview of the share card. User taps "Share" to export.
///
/// This is a top-level *variable* (not a function declaration) so tests can
/// override it via the [ShareReflectionFn] typedef. Production code keeps
/// calling `shareReflectionCard(...)` exactly as before.
ShareReflectionFn shareReflectionCard = _defaultShareReflectionCard;

Future<void> _defaultShareReflectionCard({
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
// Takeaway share — the beat flow's quotable moment, on the emerald canvas
// ---------------------------------------------------------------------------

/// Signature of [shareTakeawayCard]. Exposed so tests can inject a throwing
/// fake (mirrors [ShareReflectionFn]).
typedef ShareTakeawayFn = Future<void> Function({
  required BuildContext context,
  required String nameArabic,
  required String nameEnglish,
  required String reframeKey,
  required String takeaway,
  String meaning,
  Rect? sharePositionOrigin,
});

ShareTakeawayFn shareTakeawayCard = _defaultShareTakeawayCard;

/// Shares a story deck as a takeaway card, sourced entirely from its own beats.
///
/// **Why the verse and not the deck's own closing line.** The card is built as
/// one hero quote plus a small attribution, and the deck's obvious candidates
/// both fail as standalone quotes:
///
///  * the opening `bridge` is scene-setting prose (67-117 chars) written to lead
///    somewhere, so on its own it reads as a fragment;
///  * the closing `takeaway` hands off to the pair partner — eight of the
///    fourteen shipped decks contain a phrase like "As-Samad — the second Name
///    of your answer" — which is a dangling reference to anyone who did not just
///    read the deck.
///
/// The verse has none of those problems. It is short (35-145 chars, median ~60),
/// already verified in the deck's own `sources` table, and quotable by
/// construction — and Name + verse is exactly what CLAUDE.md calls the
/// share-worthy artifact.
///
/// Only the verse's ENGLISH translation goes to the card. Its Arabic is left off
/// deliberately: the Name's calligraphy is already the hero, and a second Arabic
/// block would both crowd the card and risk sharing a widget with Latin text.
Future<void> shareStoryDeckCard({
  required BuildContext context,
  required NameStoryDeck deck,
  Rect? sharePositionOrigin,
}) {
  NameStoryBeat? firstOf(Set<String> kinds) {
    for (final beat in deck.beats) {
      if (kinds.contains(beat.kind)) return beat;
    }
    return null;
  }

  final nameBeat = firstOf({'name_intro'});
  // The Name's OWN verse wins, with the comfort verse only as a fallback —
  // preference order, not deck order. A single set searched positionally picked
  // whichever came first in the beat list, and `ar-rahman@1` opens with a
  // comfort_verse at index 1 while its own verse sits at index 7. That card went
  // out headed "Ar-Rahman / The Most Gracious" over 2:286, "Allāh does not
  // charge a soul except with that within its capacity" — correctly attributed,
  // but asserting a Name-to-verse pairing the deck itself never makes, on the
  // deck the reel hook lands on.
  final verse = firstOf({'verse'}) ?? firstOf({'comfort_verse'});

  return shareTakeawayCard(
    context: context,
    nameArabic: nameBeat?.arabic ?? '',
    nameEnglish: deck.transliteration,
    meaning: nameBeat?.primary ?? '',
    reframeKey: verse?.primary ?? '',
    takeaway: shareableVerseSource(verse?.source ?? ''),
    sharePositionOrigin: sharePositionOrigin,
  );
}

/// The citation with its reviewer note stripped.
///
/// A deck's `source` carries provenance written for the reviewer, not the reader
/// — "Qur'an 58:1 (revealed for a woman whose complaint the person in the same
/// room could not hear)". Everything from the first parenthesis on is an
/// editorial aside and must not reach a shared card.
String shareableVerseSource(String source) {
  final cut = source.indexOf(' (');
  if (cut == -1) return source.trim();
  final aside = source.substring(cut + 2).replaceAll(')', '').trim();
  // Accuracy qualifiers are NOT asides — they are part of the claim. Stripping
  // "(excerpt)" from `al-ghaffar@1` presented a genuinely partial ayah (39:53
  // opens "Say, O Prophet…" and closes differently, with no ellipsis in the
  // quoted text) flatly as the whole verse. Quoting scripture short while
  // implying it is complete is precisely what the content rules exist to
  // prevent, so these survive; the reviewer's provenance notes still go.
  if (_verseAccuracyQualifiers.contains(aside.toLowerCase())) return source.trim();
  return source.substring(0, cut).trim();
}

const Set<String> _verseAccuracyQualifiers = {
  'excerpt',
  'excerpted',
  'partial',
  'abridged',
  'paraphrase',
};

Future<void> _defaultShareTakeawayCard({
  required BuildContext context,
  required String nameArabic,
  required String nameEnglish,
  required String reframeKey,
  required String takeaway,
  String meaning = '',
  Rect? sharePositionOrigin,
}) async {
  Widget card(bool preview) => TakeawayShareCard(
        nameArabic: nameArabic,
        nameEnglish: nameEnglish,
        meaning: meaning,
        reframeKey: reframeKey,
        takeaway: takeaway,
        preview: preview,
      );

  if (kIsWeb) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(child: card(true)),
        ),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _SharePreviewScreen(
        shareText: 'A reflection on $nameEnglish — from Sakina',
        fileName: 'sakina_reflection.png',
        cardBuilder: card,
      ),
    ),
  );
}

/// The emerald "sacred canvas" share card — Name + key line + takeaway. Cream
/// type on the canvas gradient; gold is a non-text accent only (contrast rule).
class TakeawayShareCard extends StatelessWidget {
  const TakeawayShareCard({
    required this.nameArabic,
    required this.nameEnglish,
    required this.reframeKey,
    required this.takeaway,
    this.meaning = '',
    this.preview = false,
    super.key,
  });

  final String nameArabic;
  final String nameEnglish;

  /// English epithet / meaning shown under the transliteration (e.g. "The
  /// Giver of Death"). Empty for legacy responses — the line is omitted.
  final String meaning;
  final String reframeKey;
  final String takeaway;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final double w = preview ? 380 : 1080;
    final double pad = preview ? 26 : 74;
    final double padV = preview ? 34 : 92;
    final double arabicSize = preview ? 52 : 118;
    final double englishSize = preview ? 20 : 40;
    final double meaningSize = preview ? 14 : 26;
    final double keySize = preview ? 22 : 44;
    final double takeawaySize = preview ? 15 : 26;
    final double crest = preview ? 24 : 52;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: w,
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: padV),
        decoration: const BoxDecoration(
          gradient: AppColors.sacredCanvasGradient,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ShareBrandLockup(
                preview: preview,
                markColor: AppColors.secondary,
              ),
            ),
            SizedBox(height: preview ? 12 : 28),
            MihrabArchFrame(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MihrabCrestOrnament(size: crest),
                  SizedBox(height: preview ? 18 : 40),
                  Text(
                    nameArabic,
                    style: AppTypography.nameOfAllahDisplay.copyWith(
                      fontSize: arabicSize,
                      color: AppColors.sacredInk,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: preview ? 14 : 32),
                  Text(
                    nameEnglish,
                    style: AppTypography.headlineLarge.copyWith(
                      fontSize: englishSize,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (meaning.trim().isNotEmpty) ...[
                    SizedBox(height: preview ? 4 : 8),
                    Text(
                      meaning,
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: meaningSize,
                        fontStyle: FontStyle.italic,
                        color: AppColors.sacredInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: preview ? 20 : 48),
                  _shareDivider(preview),
                  SizedBox(height: preview ? 20 : 48),
                  if (reframeKey.trim().isNotEmpty) ...[
                    Text(
                      reframeKey,
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: keySize,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sacredInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: preview ? 20 : 48),
                  ],
                  if (takeaway.trim().isNotEmpty)
                    Text(
                      takeaway,
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: takeawaySize,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sacredInk.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _shareDivider(bool preview) {
    Widget line() => Container(
          width: preview ? 34 : 74,
          height: preview ? 1 : 2,
          color: AppColors.secondary.withValues(alpha: 0.5),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        SizedBox(width: preview ? 8 : 16),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: preview ? 5 : 10,
            height: preview ? 5 : 10,
            color: AppColors.secondary,
          ),
        ),
        SizedBox(width: preview ? 8 : 16),
        line(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Built Dua share — same full-screen preview pattern
// ---------------------------------------------------------------------------

/// Signature of [shareBuiltDuaCard]. Mirrors [ShareReflectionFn] so tests can
/// inject a throwing fake.
typedef ShareBuiltDuaFn = Future<void> Function({
  required BuildContext context,
  required String need,
  required List<DuaShareSection> sections,
  required String translation,
  Rect? sharePositionOrigin,

  /// Fired when the gift was actually sent: the number of images, and the
  /// platform's own verdict (`success`, or `unavailable` where the platform
  /// cannot report). Deliberately NOT fired when the export throws OR when the
  /// user dismisses the share sheet — neither is a sent gift.
  void Function(int pageCount, String shareStatus)? onShared,
});

ShareBuiltDuaFn shareBuiltDuaCard = _defaultShareBuiltDuaCard;

Future<void> _defaultShareBuiltDuaCard({
  required BuildContext context,
  required String need,
  required List<DuaShareSection> sections,
  required String translation,
  Rect? sharePositionOrigin,
  void Function(int pageCount, String shareStatus)? onShared,
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

  // A four-stanza gift at readable type runs past a 1:2 aspect ratio. The PNG
  // exports intact, but chat clients centre-crop anything that tall, so the
  // recipient sees a sliver. Splitting the stanzas across pages keeps every
  // image close to square — and the split follows the duʿā's own order
  // (praise → salawat → ask → closing), never resequenced to front-load the
  // ask, so the pages can still be recited straight through.
  final pages = splitDuaSectionsForShare(sections);

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _SharePreviewScreen(
        title: 'Gift a Dua',
        shareLabel: 'Send this Gift',
        shareIcon: Icons.card_giftcard_rounded,
        shareText: 'I made this dua for you 🤲 — from Sakina',
        fileName: 'sakina_dua.png',
        onShared: onShared,
        cardBuilder: (preview) => _BuiltDuaShareCard(
          need: need,
          sections: pages.first,
          translation: translation,
          preview: preview,
          pageNumber: pages.length > 1 ? 1 : null,
          pageCount: pages.length > 1 ? pages.length : null,
        ),
        extraCardBuilders: [
          for (var i = 1; i < pages.length; i++)
            (preview) => _BuiltDuaShareCard(
                  need: need,
                  sections: pages[i],
                  translation: translation,
                  preview: preview,
                  pageNumber: i + 1,
                  pageCount: pages.length,
                ),
        ],
      ),
    ),
  );
}

/// Splits the stanzas into shareable pages, preserving their order.
///
/// Three or fewer stanzas stay on one card; beyond that the list is halved so
/// neither page carries the full height. Balancing by stanza COUNT rather than
/// text length is deliberate — it keeps the split stable and predictable
/// instead of shifting as the model returns longer or shorter duʿās.
@visibleForTesting
List<List<DuaShareSection>> splitDuaSectionsForShare(
    List<DuaShareSection> sections) {
  if (sections.length <= 3) return [sections];
  final mid = (sections.length / 2).ceil();
  return [sections.sublist(0, mid), sections.sublist(mid)];
}

// ---------------------------------------------------------------------------
// Share preview screen — shows the card full-screen with a share button
// ---------------------------------------------------------------------------

class _SharePreviewScreen extends StatefulWidget {
  const _SharePreviewScreen({
    required this.shareText,
    required this.fileName,
    required this.cardBuilder,
    this.extraCardBuilders = const [],
    this.title = 'Preview',
    this.shareLabel = 'Share',
    this.shareIcon = Icons.share_rounded,
    this.onShared,
  });

  /// Called only when the gift was actually sent — not on export failure and
  /// not when the user dismisses the share sheet.
  final void Function(int pageCount, String shareStatus)? onShared;

  final String shareText;
  final String fileName;

  /// Additional pages beyond [cardBuilder], exported as their own images and
  /// shared together. A single very tall card survives export intact but gets
  /// centre-cropped by chat clients, so a long gift is split across pages that
  /// each carry a shareable aspect ratio.
  final List<Widget Function(bool preview)> extraCardBuilders;

  /// Header label. Gift flows override the neutral 'Preview' (e.g. 'Gift a Dua').
  final String title;

  /// Primary-button label. Gift flows override 'Share' (e.g. 'Send this Gift').
  final String shareLabel;

  /// Primary-button icon. Gift flows swap in a gift glyph.
  final IconData shareIcon;

  /// Builds the card widget. `true` = screen-sized preview, `false` = hi-res export.
  final Widget Function(bool preview) cardBuilder;

  @override
  State<_SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<_SharePreviewScreen> {
  bool _exporting = false;

  List<Widget Function(bool preview)> get _pages =>
      [widget.cardBuilder, ...widget.extraCardBuilders];

  /// `sakina_dua.png` → `sakina_dua_1.png` for page 1 of a multi-page gift.
  String _fileNameFor(int index) {
    if (_pages.length == 1) return widget.fileName;
    final dot = widget.fileName.lastIndexOf('.');
    if (dot == -1) return '${widget.fileName}_${index + 1}';
    return '${widget.fileName.substring(0, dot)}_${index + 1}'
        '${widget.fileName.substring(dot)}';
  }

  Future<void> _share() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    HapticFeedback.mediumImpact();

    // Each page is mounted offscreen, rasterized, then removed — one at a time,
    // so several hi-res cards never occupy the overlay (or memory) at once.
    final files = <XFile>[];
    try {
      for (var i = 0; i < _pages.length; i++) {
        if (!mounted) return;
        final key = GlobalKey();
        final overlay = OverlayEntry(
          builder: (_) => Positioned(
            left: -2000,
            child: RepaintBoundary(key: key, child: _pages[i](false)),
          ),
        );
        Overlay.of(context).insert(overlay);
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          files.add(await _exportPng(
            repaintKey: key,
            fileName: _fileNameFor(i),
          ));
        } finally {
          overlay.remove();
        }
      }

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      final origin = box.localToGlobal(Offset.zero) & box.size;
      final result = await Share.shareXFiles(
        files,
        text: widget.shareText,
        sharePositionOrigin: origin,
      );
      // `shareXFiles` completes when the sheet CLOSES, however it closed —
      // so reporting unconditionally here would count every cancel as a sent
      // gift and inflate the send rate. Only a non-dismissed result counts.
      // `unavailable` (platform can't determine) is reported rather than
      // dropped, but is passed through so it stays separable from a confirmed
      // `success` when reading the funnel.
      if (result.status != ShareResultStatus.dismissed) {
        widget.onShared?.call(files.length, result.status.name);
      }
    } catch (e) {
      debugPrint('[SHARE ERROR] $e');
      if (mounted) {
        showShareErrorSnackBar(ScaffoldMessenger.of(context));
      }
    } finally {
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
                    widget.title,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _pages.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.lg),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _pages[i](true),
                        ),
                      ],
                    ],
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
                      : Icon(widget.shareIcon, size: 20),
                  label: Text(_exporting ? 'Preparing...' : widget.shareLabel),
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
            Align(
              alignment: Alignment.centerLeft,
              child: ShareBrandLockup(
                preview: preview,
                markColor: _emerald,
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

  /// This stanza's OWN meaning. Carried so the gift card can sit each English
  /// line directly under its Arabic instead of fusing all four into one
  /// paragraph at the foot of the card. Optional — falls back to the whole-dua
  /// translation when absent.
  final String translation;

  const DuaShareSection({
    required this.label,
    required this.arabic,
    this.translation = '',
  });
}

/// Convenience to create sections from BuiltDuaSection list.
List<DuaShareSection> duaSectionsForShare(List sections) {
  return sections
      .map((s) => DuaShareSection(
            label: s.label as String,
            arabic: s.arabic as String,
            translation: (s.translation as String?) ?? '',
          ))
      .toList();
}

/// The gifted-dua share card — a framed cream keepsake, not a screenshot.
///
/// Reads as something you *give*: a gold "A DUA FOR YOU" eyebrow over the
/// recipient's need, the composed duʿā laid out as calligraphic stanzas (emerald
/// ink on cream — no heavy solid blocks), and a "made for you with Sakina"
/// footer. A gold hairline frame wraps the whole card so it feels like an object.
class _BuiltDuaShareCard extends StatelessWidget {
  const _BuiltDuaShareCard({
    required this.need,
    required this.sections,
    required this.translation,
    this.preview = false,
    this.pageNumber,
    this.pageCount,
  });

  final String need;

  /// The stanzas on THIS page (a subset when the gift spans pages).
  final List<DuaShareSection> sections;
  final String translation;
  final bool preview;

  /// 1-based page position, set only for a multi-page gift. Every page repeats
  /// the crest / eyebrow / need header and the brand footer so each image
  /// stands on its own — a recipient may well see only one of them.
  final int? pageNumber;
  final int? pageCount;

  bool get _isLastPage => pageCount == null || pageNumber == pageCount;

  static const _emerald = Color(0xFF1B6B4A);
  static const _gold = Color(0xFFC8985E);
  static const _cream = Color(0xFFFBF7F2);
  static const _ink = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final double w = preview ? 380 : 1080;
    final double frameGap = preview ? 14 : 40; // cream margin outside the frame
    final double pad = preview ? 24 : 68; // inside the gold frame
    final double padV = preview ? 32 : 88;
    final double crest = preview ? 22 : 48;
    final double eyebrowSize = preview ? 11 : 20;
    final double needSize = preview ? 22 : 46;
    final double labelSize = preview ? 10 : 16;
    // Every stanza is set at ONE size, and set large: scripture has to be
    // legible before it is decorative, and a recipient reading unfamiliar
    // Arabic shouldn't get the frame stanzas in small type. Emphasis on the ask
    // is carried by its label alone, never by shrinking the other stanzas.
    final double arabicSize = preview ? 26 : 47;
    final double translationSize = preview ? 13.5 : 24;
    final double footerSize = preview ? 10 : 17;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: w,
        color: _cream,
        padding: EdgeInsets.all(frameGap),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _gold.withValues(alpha: 0.45),
              width: preview ? 1 : 2,
            ),
            borderRadius: BorderRadius.circular(preview ? 12 : 28),
          ),
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: padV),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MihrabCrestOrnament(size: crest),
              SizedBox(height: preview ? 14 : 32),

              // Gift framing — this is the dua being *given*.
              Text(
                'A DUA FOR YOU',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: eyebrowSize,
                  color: _gold,
                  letterSpacing: preview ? 3 : 6,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: preview ? 8 : 18),

              // The need it was made for.
              Text(
                need,
                style: AppTypography.headlineLarge.copyWith(
                  fontSize: needSize,
                  color: _emerald,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: preview ? 22 : 52),
              _giftDivider(preview),

              // The composed duʿā, in its own liturgical order (praise →
              // salawat → ask → closing — never reordered). Each stanza carries
              // its OWN meaning directly beneath it, so a recipient who doesn't
              // read Arabic understands each line in place rather than hunting
              // through one fused paragraph at the foot of the card.
              //
              // The ask is the personal message and praise / salawat / closing
              // are the frame around it, but that is marked ONLY by the label's
              // weight — every stanza is set at the same size, because a
              // recipient who reads Arabic slowly must not be handed the frame
              // in smaller type than the request.
              ...List.generate(sections.length, (i) {
                final section = sections[i];
                final hero = _isAskLabel(section.label);
                final meaning = section.translation.trim();
                return Column(
                  children: [
                    SizedBox(height: preview ? 22 : 52),
                    Text(
                      _softLabel(section.label),
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: labelSize,
                        color: _gold.withValues(alpha: hero ? 1 : 0.75),
                        letterSpacing: preview ? 1.4 : 2.6,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: preview ? 10 : 22),
                    Text(
                      section.arabic,
                      style: AppTypography.quranArabic.copyWith(
                        fontSize: arabicSize,
                        color: _emerald,
                        height: 1.95,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                    if (meaning.isNotEmpty) ...[
                      SizedBox(height: preview ? 9 : 20),
                      Text(
                        meaning,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: translationSize,
                          color: _ink.withValues(alpha: 0.78),
                          height: 1.55,
                          fontStyle: FontStyle.italic,
                        ),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              }),

              SizedBox(height: preview ? 26 : 60),
              _giftDivider(preview),

              // Fallback only: when the sections carry no meanings of their own
              // there would otherwise be no English on the card at all, so the
              // whole-dua translation stands in. It covers the WHOLE duʿā, so
              // it belongs on the final page only.
              if (_isLastPage &&
                  !sections.any((s) => s.translation.trim().isNotEmpty) &&
                  translation.trim().isNotEmpty) ...[
                SizedBox(height: preview ? 20 : 48),
                Text(
                  '"$translation"',
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: translationSize,
                    color: _ink.withValues(alpha: 0.78),
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: preview ? 24 : 56),
              ShareBrandLockup(preview: preview, markColor: _emerald),
              SizedBox(height: preview ? 8 : 16),
              Text(
                'made for you with Sakina',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: footerSize,
                  color: _emerald.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              // Tells a recipient another image completes the duʿā — without it
              // a page read alone looks like the whole gift.
              if (pageCount != null && pageCount! > 1) ...[
                SizedBox(height: preview ? 6 : 14),
                Text(
                  '$pageNumber of $pageCount',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: footerSize,
                    color: _gold.withValues(alpha: 0.8),
                    letterSpacing: preview ? 1.2 : 2.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// True when this stanza is the personal ask (the heart of the gift) rather
  /// than the liturgical frame around it. Label text comes from the model, so
  /// this matches loosely; when nothing matches, no stanza is promoted and the
  /// card simply renders every stanza at the frame size.
  static bool _isAskLabel(String label) =>
      label.toLowerCase().contains('ask') ||
      label.toLowerCase().contains('request');

  /// Gift-appropriate section labels.
  ///
  /// The raw labels are builder vocabulary explaining how the duʿā was
  /// assembled ("OPENING PRAISE"). Set in caps with wide tracking they read as
  /// scaffolding on something meant to be given, so they are title-cased, the
  /// "Opening" qualifier is dropped, and the caller sets them small and light.
  static String _softLabel(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
    if (s.toLowerCase().startsWith('opening ')) s = s.substring(8);
    return s
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// A gold line — diamond — line rule, echoing the takeaway card's divider so
  /// both share surfaces speak one visual language.
  static Widget _giftDivider(bool preview) {
    Widget line() => Container(
          width: preview ? 34 : 74,
          height: preview ? 1 : 2,
          color: _gold.withValues(alpha: 0.5),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        SizedBox(width: preview ? 8 : 16),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: preview ? 5 : 10,
            height: preview ? 5 : 10,
            color: _gold,
          ),
        ),
        SizedBox(width: preview ? 8 : 16),
        line(),
      ],
    );
  }
}
