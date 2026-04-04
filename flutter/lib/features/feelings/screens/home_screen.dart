import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duasProvider);
    final notifier = ref.read(duasProvider.notifier);
    final reflectState = ref.watch(reflectProvider);
    final reflectNotifier = ref.read(reflectProvider.notifier);

    final hasReflections = reflectState.savedReflections.isNotEmpty;
    final hasSavedBuilt = state.savedBuiltDuas.isNotEmpty;
    final hasSavedRelated = state.savedRelatedDuas.isNotEmpty;
    final hasSavedBrowse = state.savedDuaIds.isNotEmpty;
    final hasAnything = hasReflections || hasSavedBuilt || hasSavedRelated || hasSavedBrowse;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Journal',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your saved reflections and duas',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              if (!hasAnything) _buildEmptyState(),

              // Recent Reflections
              if (hasReflections) ...[
                _sectionHeader('Recent Reflections'),
                const SizedBox(height: 12),
                ...reflectState.savedReflections.take(10).map(
                  (r) => _buildReflectionCard(r, reflectNotifier),
                ),
                const SizedBox(height: 24),
              ],

              // Saved Built Duas
              if (hasSavedBuilt) ...[
                _sectionHeader('My Built Duas'),
                const SizedBox(height: 12),
                ...state.savedBuiltDuas.reversed.map(
                  (dua) => _buildSavedBuiltDuaCard(dua, notifier),
                ),
                const SizedBox(height: 24),
              ],

              // Saved Related Duas
              if (hasSavedRelated) ...[
                _sectionHeader('Saved Duas'),
                const SizedBox(height: 12),
                ...state.savedRelatedDuas.map(
                  (dua) => _buildSavedRelatedDuaCard(dua, notifier),
                ),
                const SizedBox(height: 24),
              ],

              // Saved Browse Duas indicator
              if (hasSavedBrowse) ...[
                _sectionHeader('Favorites'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${state.savedDuaIds.length} saved from Browse',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View in Duas tab',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          const Icon(
            Icons.book_outlined,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Your journal is empty',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reflect on your feelings or build a dua — your saved content will appear here.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headlineMedium.copyWith(
        color: AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildReflectionCard(SavedReflection r, ReflectNotifier notifier) {
    final date = DateTime.tryParse(r.date);
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${r.name} · ${r.nameArabic}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.deleteReflection(r.id);
                  },
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '"${r.userText}"',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              r.reframePreview,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimaryLight,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedBuiltDuaCard(SavedBuiltDua dua, DuasNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: _ExpandableBuiltDua(dua: dua, notifier: notifier),
      ),
    );
  }

  Widget _buildSavedRelatedDuaCard(
      SavedRelatedDua dua, DuasNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: _ExpandableRelatedDua(dua: dua, notifier: notifier),
      ),
    );
  }
}

class _ExpandableBuiltDua extends StatefulWidget {
  const _ExpandableBuiltDua({required this.dua, required this.notifier});
  final SavedBuiltDua dua;
  final DuasNotifier notifier;

  @override
  State<_ExpandableBuiltDua> createState() => _ExpandableBuiltDuaState();
}

class _ExpandableBuiltDuaState extends State<_ExpandableBuiltDua> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Built Dua',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.notifier.removeSavedBuiltDua(widget.dua.id);
              },
              child: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.dua.need,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.dua.arabic,
          style: AppTypography.quranArabic.copyWith(fontSize: 20),
          textDirection: TextDirection.rtl,
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Text(
            widget.dua.transliteration,
            style: AppTypography.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.dua.translation,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Show more',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandableRelatedDua extends StatefulWidget {
  const _ExpandableRelatedDua({required this.dua, required this.notifier});
  final SavedRelatedDua dua;
  final DuasNotifier notifier;

  @override
  State<_ExpandableRelatedDua> createState() => _ExpandableRelatedDuaState();
}

class _ExpandableRelatedDuaState extends State<_ExpandableRelatedDua> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.dua.title,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.notifier.removeSavedRelatedDua(widget.dua.id);
              },
              child: const Icon(
                Icons.favorite,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.dua.arabic,
          style: AppTypography.quranArabic.copyWith(fontSize: 20),
          textDirection: TextDirection.rtl,
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Text(
            widget.dua.transliteration,
            style: AppTypography.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.dua.translation,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.dua.source,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Show more',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
