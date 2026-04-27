import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/widgets/confirm_delete_dialog.dart';
import 'package:sakina/widgets/share_card.dart';

/// Detail page for a saved built dua or saved related dua.
class DuaDetailPage extends StatelessWidget {
  const DuaDetailPage({
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.source = '',
    this.onRemove,
    super.key,
  });

  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;
  final VoidCallback? onRemove;

  /// Convenience constructor from a SavedBuiltDua.
  factory DuaDetailPage.fromBuiltDua(SavedBuiltDua d, {VoidCallback? onRemove}) => DuaDetailPage(
    title: d.need,
    arabic: d.arabic,
    transliteration: d.transliteration,
    translation: d.translation,
    onRemove: onRemove,
  );

  /// Convenience constructor from a SavedRelatedDua.
  factory DuaDetailPage.fromRelatedDua(SavedRelatedDua d, {VoidCallback? onRemove}) => DuaDetailPage(
    title: d.title,
    arabic: d.arabic,
    transliteration: d.transliteration,
    translation: d.translation,
    source: d.source,
    onRemove: onRemove,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Dua',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                        color: AppColors.textSecondaryLight,
                      ),
                      const Spacer(),
                      if (onRemove != null)
                        IconButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final confirmed = await confirmDeleteDialog(
                              context,
                              title: 'Delete this dua?',
                            );
                            if (!confirmed) return;
                            onRemove!();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          color: AppColors.textTertiaryLight,
                        ),
                      Builder(builder: (btnContext) => IconButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          HapticFeedback.mediumImpact();
                          final box = btnContext.findRenderObject() as RenderBox;
                          final origin = box.localToGlobal(Offset.zero) & box.size;
                          try {
                            await shareReflectionCard(
                          context: context,
                          nameArabic: '',
                          nameEnglish: title,
                          duaArabic: arabic,
                          duaTransliteration: transliteration,
                          duaTranslation: translation,
                          duaSource: source,
                          sharePositionOrigin: origin,
                        );
                      } catch (e) {
                        debugPrint('[SHARE ERROR] $e');
                        showShareErrorSnackBar(messenger);
                      }
                    },
                    icon: const Icon(Icons.share_outlined, size: 20),
                        color: AppColors.textSecondaryLight,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  children: [
                    // Gold sparkles
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.auto_awesome,
                          color: AppColors.secondary.withValues(alpha: i == 2 ? 1.0 : 0.6),
                          size: i == 2 ? 20 : 14,
                        )
                            .animate()
                            .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms, delay: (i * 80).ms)
                            .fadeIn(duration: 400.ms, delay: (i * 80).ms);
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      title,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                    const SizedBox(height: 24),
                    // Arabic card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        arabic,
                        style: AppTypography.quranArabic.copyWith(color: Colors.white),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .scaleXY(begin: 0.95, end: 1.0, duration: 800.ms, delay: 300.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    // Transliteration + Translation card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transliteration,
                            style: AppTypography.bodyMedium.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondaryLight,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.dividerLight),
                          const SizedBox(height: 16),
                          Text(
                            translation,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimaryLight,
                              height: 1.6,
                            ),
                          ),
                          if (source.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              source,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
