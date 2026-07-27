import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_share_card.dart';
import 'package:sakina/widgets/share_card.dart' show showShareErrorSnackBar;

/// The E1 share preview: shows the composed card, then exports a hi-res frame
/// offscreen and hands it to the system share sheet.
///
/// Mirrors `_SharePreviewScreen` + `_exportAndShare` in lib/widgets/share_card.dart
/// (RepaintBoundary → toImage → Share.shareXFiles) — the same export path the
/// reflection and dua cards already ship.
class LanternSharePreview extends StatefulWidget {
  const LanternSharePreview({
    super.key,
    required this.skinId,
    required this.backdropId,
    required this.lanternName,
    required this.streak,
  });

  final String skinId;
  final String backdropId;
  final String lanternName;
  final int streak;

  @override
  State<LanternSharePreview> createState() => _LanternSharePreviewState();
}

class _LanternSharePreviewState extends State<LanternSharePreview> {
  final _exportKey = GlobalKey();
  bool _exporting = false;

  LanternShareCard _card({required bool preview}) => LanternShareCard(
        skinId: widget.skinId,
        backdropId: widget.backdropId,
        lanternName: widget.lanternName,
        streak: widget.streak,
        preview: preview,
      );

  Future<void> _share() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    HapticFeedback.mediumImpact();

    // Offscreen hi-res copy, exported from its own RepaintBoundary.
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: -3000,
        child: RepaintBoundary(
          key: _exportKey,
          child: _card(preview: false),
        ),
      ),
    );
    Overlay.of(context).insert(overlay);
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      if (!mounted) return;
      final boundary = _exportKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      final file = File('${Directory.systemTemp.path}/sakina_lantern.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My lantern on Sakina',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      debugPrint('[LANTERN SHARE ERROR] $e');
      if (mounted) showShareErrorSnackBar(ScaffoldMessenger.of(context));
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
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 24),
                    color: AppColors.textSecondaryLight,
                  ),
                  const Spacer(),
                  Text('Preview',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textSecondaryLight)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _card(preview: true),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _exporting ? null : _share,
                  icon: const Icon(Icons.share_rounded),
                  label: Text(_exporting ? 'Preparing…' : 'Share'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
