import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/journal/widgets/chunked_section_view.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/widgets/confirm_delete_dialog.dart';
import 'package:sakina/widgets/share_card.dart';

class ReflectionDetailPage extends StatelessWidget {
  const ReflectionDetailPage(
      {required this.reflection, this.onRemove, super.key});

  final SavedReflection reflection;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasReflectionBody = reflection.hasBeats ||
        reflection.reframe.isNotEmpty ||
        reflection.story.isNotEmpty ||
        reflection.duaArabic.isNotEmpty;

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
                      'Reflection',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon:
                            const Icon(Icons.arrow_back_ios_rounded, size: 20),
                        color: AppColors.textSecondaryLight,
                      ),
                      const Spacer(),
                      if (onRemove != null)
                        IconButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final confirmed = await confirmDeleteDialog(
                              context,
                              title: 'Delete this reflection?',
                            );
                            if (!confirmed) return;
                            onRemove!();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 20),
                          color: AppColors.textTertiaryLight,
                        ),
                      Builder(
                          builder: (btnContext) => IconButton(
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  HapticFeedback.mediumImpact();
                                  final box = btnContext.findRenderObject()
                                      as RenderBox;
                                  final origin =
                                      box.localToGlobal(Offset.zero) & box.size;
                                  try {
                                    await shareReflectionCard(
                                      context: context,
                                      nameArabic: reflection.nameArabic,
                                      nameEnglish: reflection.name,
                                      verses: reflection.verses,
                                      duaArabic: reflection.duaArabic,
                                      duaTransliteration:
                                          reflection.duaTransliteration,
                                      duaTranslation: reflection.duaTranslation,
                                      duaSource: reflection.duaSource,
                                      reframe: reflection.reframe,
                                      story: reflection.story,
                                      sharePositionOrigin: origin,
                                    );
                                  } catch (e) {
                                    debugPrint('[SHARE ERROR] $e');
                                    showShareErrorSnackBar(messenger);
                                  }
                                },
                                icon:
                                    const Icon(Icons.share_outlined, size: 20),
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
                          color: AppColors.secondary
                              .withValues(alpha: i == 2 ? 1.0 : 0.6),
                          size: i == 2 ? 20 : 14,
                        )
                            .animate()
                            .scale(
                                begin: const Offset(0, 0),
                                end: const Offset(1, 1),
                                curve: Curves.elasticOut,
                                duration: 600.ms,
                                delay: (i * 80).ms)
                            .fadeIn(duration: 400.ms, delay: (i * 80).ms);
                      }),
                    ),
                    const SizedBox(height: 12),
                    // User's original text
                    Text(
                      '"${reflection.userText}"',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    const SizedBox(height: 24),
                    // Name card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'A Name for your heart',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            reflection.nameArabic,
                            style: AppTypography.nameOfAllahDisplay
                                .copyWith(color: Colors.white),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            reflection.name,
                            style: AppTypography.headlineLarge
                                .copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          if (reflection.relatedNames.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Related Names of Allah:',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: reflection.relatedNames
                                  .map((r) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${r['name']} · ',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      color: Colors.white),
                                            ),
                                            Text(
                                              '${r['nameArabic']}',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      color: Colors.white),
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.05, end: 0, duration: 600.ms),

                    if (hasReflectionBody) ...[
                      const SizedBox(height: 32),
                      // Cardless, typographic chunked layout (spec §4).
                      // Renders structured beats when present, falls back to
                      // splitIntoBeats(reframe/story) for legacy entries.
                      ChunkedSectionView(reflection: reflection)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 200.ms)
                          .slideY(begin: 0.03, end: 0, duration: 600.ms, delay: 200.ms),
                      if (reflection.verses.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _verses(delay: 300),
                      ],
                    ] else ...[
                      const SizedBox(height: 32),
                      // Legacy entries with only a preview string.
                      ChunkedSectionView(reflection: reflection)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 200.ms),
                    ],
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

  /// Cardless Quran verse block: gold accent bar above a small label, then each
  /// verse as Arabic (RTL) + translation + reference, separated by whitespace.
  Widget _verses({int delay = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Quran',
          style:
              AppTypography.labelMedium.copyWith(color: AppColors.primary),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(reflection.verses.length, (index) {
          final verse = reflection.verses[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom:
                  index == reflection.verses.length - 1 ? 0 : AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  verse.arabic,
                  style: AppTypography.quranArabic.copyWith(fontSize: 24),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  verse.translation,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  verse.reference,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay.ms)
        .slideY(begin: 0.03, end: 0, duration: 600.ms, delay: delay.ms);
  }
}
