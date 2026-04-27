import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/features/journal/screens/reflection_detail_page.dart';
import 'package:sakina/features/journal/screens/dua_detail_page.dart';
import 'package:sakina/widgets/confirm_delete_dialog.dart';
import 'package:sakina/widgets/provider_error_listener.dart';
import 'package:sakina/widgets/sakina_loader.dart';

// ---------------------------------------------------------------------------
// Stats provider
// ---------------------------------------------------------------------------

final _journalStatsProvider =
    FutureProvider<({XpState xp, StreakState streak})>((ref) async {
  final xp = await getXp();
  final streak = await getStreak();
  return (xp: xp, streak: streak);
});

// ---------------------------------------------------------------------------
// Achievements provider
// ---------------------------------------------------------------------------

final _achievementsProvider = FutureProvider<Set<String>>((ref) async {
  return getUnlockedAchievements();
});

// ---------------------------------------------------------------------------
// Entry type for unified feed
// ---------------------------------------------------------------------------

enum _EntryType { reflection, builtDua, savedDua }

class _JournalEntry {
  final _EntryType type;
  final DateTime date;
  final dynamic data; // SavedReflection | SavedBuiltDua | BrowseDua

  const _JournalEntry({
    required this.type,
    required this.date,
    required this.data,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _questFired = false;
  int _duaFilter = 0; // 0=All, 1=Built, 2=Saved

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_questFired) {
      _questFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(questsProvider.notifier).onJournalVisited();
      });
    }
    final reflectState = ref.watch(reflectProvider);
    final duasState = ref.watch(duasProvider);

    final reflections = reflectState.savedReflections;
    final builtDuas = duasState.savedBuiltDuas;
    final savedDuas = duasState.savedRelatedDuas;

    // Build merged feed
    final allEntries = <_JournalEntry>[
      ...reflections.map((r) => _JournalEntry(
            type: _EntryType.reflection,
            date: DateTime.parse(r.date),
            data: r,
          )),
      ...builtDuas.map((d) => _JournalEntry(
            type: _EntryType.builtDua,
            date: DateTime.parse(d.savedAt),
            data: d,
          )),
      ...savedDuas.map((d) => _JournalEntry(
            type: _EntryType.savedDua,
            date: DateTime.now(), // no saved date on related duas
            data: d,
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final totalCount = reflections.length + builtDuas.length + savedDuas.length;

    // Surface delete failures: deleteReflection / removeSavedBuiltDua roll back
    // state on server error and set state.error. Without these listeners, the
    // Reflect screen is the only place that renders the error, so a delete
    // while offline in Journal would silently revert with no UI feedback.
    return ProviderErrorSnackBarListener<ReflectState>(
      provider: reflectProvider,
      errorOf: (s) => s.error,
      child: ProviderErrorSnackBarListener<DuasState>(
        provider: duasProvider,
        errorOf: (s) => s.error,
        child: _buildScaffold(reflections, builtDuas, savedDuas, allEntries,
            totalCount),
      ),
    );
  }

  Widget _buildScaffold(
    List<SavedReflection> reflections,
    List<SavedBuiltDua> builtDuas,
    List<SavedRelatedDua> savedDuas,
    List<_JournalEntry> allEntries,
    int totalCount,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(totalCount),
            if (totalCount > 0) ...[
              const SizedBox(height: 12),
              _buildInlineStats(
                  reflections, builtDuas.length + savedDuas.length),
            ],
            const SizedBox(height: 16),
            _buildTabs(),
            Expanded(
              child: IndexedStack(
                index: _tab.index,
                children: [
                  _buildAllFeed(allEntries),
                  _buildReflectionsTab(reflections),
                  _buildDuasTab(builtDuas, savedDuas),
                  _buildAchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 32, AppSpacing.pagePadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Journal',
                  style: AppTypography.displayLarge
                      .copyWith(color: AppColors.textPrimaryLight))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.05, end: 0, duration: 500.ms),
          const SizedBox(height: 4),
          Text(
            total == 0 ? 'Your spiritual diary' : '$total entries',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        ],
      ),
    );
  }

  // ── Inline stats ───────────────────────────────────────────────────────────

  // Keyword → theme bucket mapping
  static const _themeBuckets = <String, List<String>>{
    'Anxiety & Worry': [
      'anxious',
      'anxiety',
      'stressed',
      'stress',
      'worry',
      'worried',
      'nervous',
      'fear',
      'scared',
      'overwhelmed',
      'panic'
    ],
    'Relationships': [
      'family',
      'friend',
      'friends',
      'wife',
      'husband',
      'mother',
      'father',
      'parents',
      'sister',
      'brother',
      'relationship',
      'people',
      'nosy',
      'marriage'
    ],
    'Work & Career': [
      'job',
      'work',
      'career',
      'business',
      'money',
      'salary',
      'boss',
      'interview',
      'study',
      'school',
      'exam',
      'university'
    ],
    'Sadness & Grief': [
      'sad',
      'sadness',
      'grief',
      'loss',
      'lost',
      'cry',
      'crying',
      'depressed',
      'depression',
      'lonely',
      'alone',
      'hurt'
    ],
    'Gratitude': [
      'grateful',
      'gratitude',
      'thankful',
      'blessed',
      'blessing',
      'alhamdulillah',
      'happy',
      'joy',
      'peace'
    ],
    'Guidance': [
      'confused',
      'decision',
      'istikhara',
      'guidance',
      'direction',
      'know',
      'should',
      'proceed',
      'unsure',
      'doubt'
    ],
  };

  String? _topTheme(List<SavedReflection> reflections) {
    if (reflections.length < 3) return null;
    final counts = <String, int>{};
    for (final r in reflections) {
      final text = r.userText.toLowerCase();
      for (final entry in _themeBuckets.entries) {
        for (final kw in entry.value) {
          if (text.contains(kw)) {
            counts[entry.key] = (counts[entry.key] ?? 0) + 1;
            break;
          }
        }
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Widget _buildInlineStats(List<SavedReflection> reflections, int duasCount) {
    final statsAsync = ref.watch(_journalStatsProvider);

    // Unique Names encountered
    final uniqueNames = reflections.map((r) => r.name).toSet().length;

    final topTheme = _topTheme(reflections);

    return statsAsync
        .when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: SakinaLoader()),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (stats) => Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, 0, AppSpacing.pagePadding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 4 stat tiles ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem(
                            Icons.auto_stories_rounded,
                            '${reflections.length}',
                            'Reflections',
                            AppColors.primary),
                        const VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: AppColors.borderLight),
                        _statItem(Icons.auto_awesome, '$duasCount', 'Duas',
                            AppColors.secondary),
                        const VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: AppColors.borderLight),
                        _statItem(Icons.star_rounded, '$uniqueNames', 'Names',
                            AppColors.secondary),
                        const VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: AppColors.borderLight),
                        _statItem(
                            Icons.local_fire_department,
                            '${stats.streak.longestStreak}',
                            'Best streak',
                            AppColors.streakAmber),
                      ],
                    ),
                  ),
                ),

                // ── Theme insight card (3+ reflections) ──
                if (topTheme != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBD9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.secondary, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You often turn to Allah with $topTheme',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms);
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    const labels = ['All', 'Reflections', 'Duas', 'Badges'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _tab.index == i;
          return Flexible(
            child: GestureDetector(
              onTap: () => _tab.animateTo(i),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      labels[i],
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── All feed ────────────────────────────────────────────────────────────────

  Widget _buildAllFeed(List<_JournalEntry> entries) {
    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 32),
      children: entries
          .asMap()
          .entries
          .map((e) => _animatedCard(e.key, _buildEntryCard(e.value)))
          .toList(),
    );
  }

  // ── Reflections tab ─────────────────────────────────────────────────────────

  Widget _buildReflectionsTab(List<SavedReflection> reflections) {
    if (reflections.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome_outlined,
        message: 'No reflections yet',
        sub: 'Complete a Reflect session and it will appear here.',
        actionLabel: 'Start Reflecting',
        onAction: () => context.go('/reflect'),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 32),
      children: reflections.asMap().entries.map((e) {
        return _animatedCard(
          e.key,
          _buildReflectionCard(e.value),
        );
      }).toList(),
    );
  }

  // ── Duas tab ────────────────────────────────────────────────────────────────

  Widget _buildDuasTab(
      List<SavedBuiltDua> builtDuas, List<SavedRelatedDua> savedDuas) {
    if (builtDuas.isEmpty && savedDuas.isEmpty) {
      return _buildEmptyState(
        icon: Icons.brightness_3_outlined,
        message: 'No duas saved yet',
        sub: 'Build a dua or save one from your reflections.',
        actionLabel: 'Build a Dua',
        onAction: () => context.go('/duas'),
      );
    }

    final List<Widget> duaWidgets;
    switch (_duaFilter) {
      case 1:
        duaWidgets = builtDuas.map(_buildBuiltDuaCard).toList();
      case 2:
        duaWidgets = savedDuas.map(_buildSavedDuaCard).toList();
      default:
        duaWidgets = [
          ...builtDuas.map(_buildBuiltDuaCard),
          ...savedDuas.map(_buildSavedDuaCard),
        ];
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 32),
      children: [
        // Filter chips
        Row(
          children: [
            _duaFilterChip('All', 0),
            const SizedBox(width: 8),
            _duaFilterChip('Built', 1),
            const SizedBox(width: 8),
            _duaFilterChip('Saved', 2),
          ],
        ),
        const SizedBox(height: 16),
        ...duaWidgets.asMap().entries.map((e) => _animatedCard(e.key, e.value)),
      ],
    );
  }

  Widget _duaFilterChip(String label, int index) {
    final selected = _duaFilter == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _duaFilter = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ── Achievements tab ────────────────────────────────────────────────────────

  Widget _buildAchievementsTab() {
    final asyncUnlocked = ref.watch(_achievementsProvider);

    return asyncUnlocked.when(
      loading: () => const Center(
        child: SakinaLoader(),
      ),
      error: (_, __) =>
          const Center(child: Text('Could not load achievements')),
      data: (unlocked) {
        const categories = AchievementCategory.values;
        final categoryLabels = {
          AchievementCategory.collection: 'Collection',
          AchievementCategory.reflection: 'Reflection',
          AchievementCategory.dua: 'Dua',
          AchievementCategory.streak: 'Streak',
          AchievementCategory.growth: 'Growth',
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 32),
          children: [
            // Summary
            Center(
              child: Text(
                '${unlocked.length} / ${allAchievements.length} unlocked',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: allAchievements.isNotEmpty
                    ? unlocked.length / allAchievements.length
                    : 0,
                minHeight: 6,
                backgroundColor: AppColors.borderLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
            const SizedBox(height: 20),

            // Grouped by category
            ...categories.expand((cat) {
              final achievements =
                  allAchievements.where((a) => a.category == cat).toList();
              if (achievements.isEmpty) return <Widget>[];

              return [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 8),
                  child: Text(
                    categoryLabels[cat] ?? '',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                      letterSpacing: 1.5,
                      fontSize: 11,
                    ),
                  ),
                ),
                ...achievements.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  final isUnlocked = unlocked.contains(a.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AchievementCard(
                      achievement: a,
                      unlocked: isUnlocked,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (i * 40).ms, duration: 300.ms)
                      .slideY(
                          begin: 0.04,
                          end: 0,
                          delay: (i * 40).ms,
                          duration: 300.ms);
                }),
              ];
            }),
          ],
        );
      },
    );
  }

  // ── Entry card dispatcher ───────────────────────────────────────────────────

  Widget _buildEntryCard(_JournalEntry entry) {
    switch (entry.type) {
      case _EntryType.reflection:
        return _buildReflectionCard(entry.data as SavedReflection);
      case _EntryType.builtDua:
        return _buildBuiltDuaCard(entry.data as SavedBuiltDua);
      case _EntryType.savedDua:
        return _buildSavedDuaCard(entry.data as SavedRelatedDua);
    }
  }

  // ── Reflection card ─────────────────────────────────────────────────────────

  Widget _buildReflectionCard(SavedReflection r) {
    final date = DateTime.parse(r.date);
    return _ExpandableCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (_) => ReflectionDetailPage(
                    reflection: r,
                    onRemove: () => ref
                        .read(reflectProvider.notifier)
                        .deleteReflection(r.id),
                  )),
        );
      },
      topLeft: _typeChip('Reflection', AppColors.primary),
      topRight: _dateLabel(date),
      summary: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Name badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.nameArabic,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      expanded: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDE4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              r.reframePreview,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _removeButton(() {
            ref.read(reflectProvider.notifier).deleteReflection(r.id);
          }, confirmTitle: 'Delete this reflection?'),
        ],
      ),
    );
  }

  // ── Built dua card ──────────────────────────────────────────────────────────

  Widget _buildBuiltDuaCard(SavedBuiltDua d) {
    final date = DateTime.parse(d.savedAt);
    return _ExpandableCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (_) => DuaDetailPage.fromBuiltDua(
                    d,
                    onRemove: () => ref
                        .read(duasProvider.notifier)
                        .removeSavedBuiltDua(d.id),
                  )),
        );
      },
      topLeft: _typeChip('Personal Dua', AppColors.secondary),
      topRight: _dateLabel(date),
      summary: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            d.need,
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.textPrimaryLight),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      expanded: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 12),
          Text(
            d.transliteration,
            style: AppTypography.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            d.translation,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimaryLight, height: 1.5),
          ),
          const SizedBox(height: 12),
          _removeButton(() {
            ref.read(duasProvider.notifier).removeSavedBuiltDua(d.id);
          }, confirmTitle: 'Delete this dua?'),
        ],
      ),
    );
  }

  // ── Saved dua card ──────────────────────────────────────────────────────────

  Widget _buildSavedDuaCard(SavedRelatedDua d) {
    return _ExpandableCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (_) => DuaDetailPage.fromRelatedDua(
                    d,
                    onRemove: () => ref
                        .read(duasProvider.notifier)
                        .removeSavedRelatedDua(d.id),
                  )),
        );
      },
      topLeft: _typeChip('Saved Dua', AppColors.secondary),
      topRight: Text(
        d.source,
        style: AppTypography.bodySmall
            .copyWith(color: AppColors.textTertiaryLight),
      ),
      summary: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            d.title,
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.textPrimaryLight),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      expanded: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 12),
          Text(
            d.transliteration,
            style: AppTypography.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            d.translation,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimaryLight, height: 1.5),
          ),
          const SizedBox(height: 12),
          _removeButton(() {
            ref.read(duasProvider.notifier).removeSavedRelatedDua(d.id);
          }, confirmTitle: 'Delete this dua?'),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    IconData icon = Icons.menu_book_outlined,
    String message = 'Your journal is empty',
    String sub =
        'Reflections, duas you build, and duas you save will all appear here.',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Align(
      alignment: const Alignment(0, -0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/illustrations/main_screens/journal_empty_state.svg',
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTypography.headlineMedium
                  .copyWith(color: AppColors.textPrimaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAction();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  child: Text(
                    actionLabel,
                    style:
                        AppTypography.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _animatedCard(int index, Widget child) {
    return child
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideY(begin: 0.05, end: 0, delay: (index * 50).ms, duration: 300.ms);
  }

  Widget _typeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _removeButton(VoidCallback onTap, {String confirmTitle = 'Delete this entry?'}) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final confirmed = await confirmDeleteDialog(
          context,
          title: confirmTitle,
        );
        if (!confirmed) return;
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded,
                size: 14, color: AppColors.textTertiaryLight),
            const SizedBox(width: 4),
            Text(
              'Remove',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    String label;
    if (diff == 0) {
      label = 'Today';
    } else if (diff == 1) {
      label = 'Yesterday';
    } else if (diff < 7) {
      label = '$diff days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      label = '${months[date.month - 1]} ${date.day}';
    }
    return Text(
      label,
      style:
          AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable expandable card
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Achievement card
// ---------------------------------------------------------------------------

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
  });

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: unlocked ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.surfaceLight : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: unlocked
                ? achievement.color.withValues(alpha: 0.3)
                : AppColors.borderLight,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: achievement.color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Badge icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked
                    ? achievement.color.withValues(alpha: 0.12)
                    : AppColors.borderLight,
              ),
              child: Icon(
                unlocked ? achievement.icon : Icons.lock_outline_rounded,
                color:
                    unlocked ? achievement.color : AppColors.textTertiaryLight,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: unlocked
                          ? AppColors.textPrimaryLight
                          : AppColors.textTertiaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 12,
                    ),
                  ),
                  if (achievement.scrollReward > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 12,
                            color: unlocked
                                ? AppColors.primary
                                : AppColors.textTertiaryLight),
                        const SizedBox(width: 3),
                        Text(
                          '+${achievement.scrollReward} Scroll${achievement.scrollReward == 1 ? '' : 's'}',
                          style: AppTypography.labelSmall.copyWith(
                            color: unlocked
                                ? AppColors.primary
                                : AppColors.textTertiaryLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Unlocked indicator
            if (unlocked)
              Icon(
                Icons.check_circle_rounded,
                color: achievement.color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableCard extends StatefulWidget {
  const _ExpandableCard({
    required this.topLeft,
    required this.topRight,
    required this.summary,
    required this.expanded,
    this.onTap,
  });

  final Widget topLeft;
  final Widget topRight;
  final Widget summary;
  final Widget expanded;
  final VoidCallback? onTap;

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ??
          () {
            HapticFeedback.selectionClick();
            setState(() => _open = !_open);
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gold accent bar
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.cardRadius),
                    bottomLeft: Radius.circular(AppSpacing.cardRadius),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: type chip + date/action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          widget.topLeft,
                          widget.topRight,
                        ],
                      ),
                      // Summary (always visible)
                      widget.summary,
                      const SizedBox(height: 8),
                      if (widget.onTap != null)
                        // Navigate hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'View full',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.textTertiaryLight,
                            ),
                          ],
                        )
                      else ...[
                        // Expand toggle hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedRotation(
                              turns: _open ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                        // Expanded content
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child:
                              _open ? widget.expanded : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
