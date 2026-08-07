import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/journal/widgets/chunked_section_view.dart';
import 'package:sakina/features/journal/widgets/edit_entry_sheet.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/widgets/confirm_delete_dialog.dart';
import 'package:sakina/widgets/share_card.dart';

class ReflectionDetailPage extends ConsumerWidget {
  const ReflectionDetailPage(
      {required this.reflection, this.onRemove, super.key});

  /// The entry as it was when this page was pushed.
  ///
  /// Read through [_live] rather than directly, so an edit made from this page
  /// is on screen the instant it commits. A route argument is a snapshot, and
  /// before the edit existed there was nothing that could make one go stale.
  final SavedReflection reflection;
  final VoidCallback? onRemove;

  /// The current row for this id, falling back to the pushed snapshot.
  ///
  /// The fallback is what covers delete: the moment `onRemove` fires the id
  /// leaves the list, and this page is still mounted for the frame before its
  /// `pop` lands. Falling back keeps that frame rendering the entry the user was
  /// looking at instead of throwing.
  SavedReflection _live(WidgetRef ref) {
    final saved = ref.watch(
      reflectProvider.select((s) => s.savedReflections),
    );
    for (final r in saved) {
      if (r.id == reflection.id) return r;
    }
    return reflection;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reflection = _live(ref);
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
                      IconButton(
                        onPressed: () => _onEdit(context, ref, reflection),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppColors.textSecondaryLight,
                        tooltip: JournalEditCopy.title,
                      ),
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
                        _verses(reflection, delay: 300),
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
  /// Opens the edit sheet and commits what comes back.
  ///
  /// Three things have to happen on a committed edit, and only the first is
  /// obvious:
  ///
  ///  1. the write itself (`editReflectionText` — server first, then the cache,
  ///     then every live `ReflectNotifier`, which is what re-renders this page);
  ///  2. `adoptEditedEntry`, because the daily loop holds its OWN copy of
  ///     tonight's row and of the time-machine anchor, and neither is reached by
  ///     the notifier broadcast — without it, editing tonight's words here and
  ///     going back to the completion screen shows the old text;
  ///  3. the event, emitted here rather than inside the write, so it counts an
  ///     edit a person made and not a row a sync touched.
  Future<void> _onEdit(
    BuildContext context,
    WidgetRef ref,
    SavedReflection entry,
  ) async {
    HapticFeedback.lightImpact();
    await showEditEntrySheet(
      context,
      initialText: entry.userText,
      onSave: (text) async {
        final updated = await editReflectionText(id: entry.id, text: text);
        if (updated == null) return false;
        ref.read(dailyLoopProvider.notifier).adoptEditedEntry(updated);
        // `updated == entry` when the text came back unchanged: the sheet's save
        // button was pressed on words nobody altered. That is a successful
        // close, not an edit, so it must not be counted as one.
        if (updated.userText != entry.userText) {
          ref.read(analyticsProvider).track(
            AnalyticsEvents.journalEntryEdited,
            properties: {
              AnalyticsEvents.propSource: entry.isMuhasabah
                  ? AnalyticsEvents.journalSourceMuhasabah
                  : AnalyticsEvents.journalSourceReflect,
              AnalyticsEvents.propAgeDays: _ageDays(entry),
            },
          );
        }
        return true;
      },
    );
  }

  /// Whole days from the entry's own date to now, floored at zero.
  ///
  /// Zero for an unparseable date rather than a null or a negative: this is a
  /// telemetry breakdown, and "today" is the honest bucket for a row whose date
  /// we cannot read.
  static int _ageDays(SavedReflection entry) {
    final written = DateTime.tryParse(entry.date);
    if (written == null) return 0;
    final days = DateTime.now().difference(written).inDays;
    return days < 0 ? 0 : days;
  }

  /// Takes the entry explicitly rather than reading the field, so it renders the
  /// same row [build] is rendering. The field is the pre-edit snapshot.
  Widget _verses(SavedReflection reflection, {int delay = 0}) {
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
