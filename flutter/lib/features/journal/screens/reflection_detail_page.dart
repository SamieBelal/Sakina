import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
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
    final hasFullData = reflection.reframe.isNotEmpty;

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

                    if (hasFullData) ...[
                      const SizedBox(height: 24),
                      // Reflection section
                      _sectionCard(
                        label: 'Reflection',
                        content: reflection.reframe,
                        delay: 200,
                      ),
                      if (reflection.verses.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _verseCard(delay: 300),
                      ],
                      const SizedBox(height: 16),
                      // Story section
                      if (reflection.story.isNotEmpty)
                        _sectionCard(
                          label: 'A Prophetic Story',
                          content: reflection.story,
                          delay: 400,
                        ),
                      if (reflection.duaArabic.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        // Dua section
                        _duaCard(delay: 600),
                      ],
                    ] else ...[
                      const SizedBox(height: 24),
                      // Fallback for old reflections without full data
                      _sectionCard(
                        label: 'Reflection',
                        content: reflection.reframePreview,
                        delay: 200,
                      ),
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

  Widget _sectionCard(
      {required String label, required String content, int delay = 0}) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay.ms)
        .slideY(begin: 0.05, end: 0, duration: 600.ms, delay: delay.ms);
  }

  Widget _duaCard({int delay = 0}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Dua',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Text(
              reflection.duaArabic,
              style: AppTypography.quranArabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 16),
          Text(
            reflection.duaTransliteration,
            style: AppTypography.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reflection.duaTranslation,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.6,
            ),
          ),
          if (reflection.duaSource.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              reflection.duaSource,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiaryLight),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay.ms)
        .slideY(begin: 0.05, end: 0, duration: 600.ms, delay: delay.ms);
  }

  Widget _verseCard({int delay = 0}) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Quran Verse',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(reflection.verses.length, (index) {
            final verse = reflection.verses[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == reflection.verses.length - 1 ? 0 : 20,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      verse.arabic,
                      style: AppTypography.quranArabic.copyWith(fontSize: 24),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    verse.translation,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse.reference,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay.ms)
        .slideY(begin: 0.05, end: 0, duration: 600.ms, delay: delay.ms);
  }
}
