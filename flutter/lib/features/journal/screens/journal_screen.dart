import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/xp_service.dart';

// ---------------------------------------------------------------------------
// Stats provider
// ---------------------------------------------------------------------------

final _journalStatsProvider = FutureProvider<({XpState xp, StreakState streak})>((ref) async {
  final xp = await getXp();
  final streak = await getStreak();
  return (xp: xp, streak: streak);
});

// ---------------------------------------------------------------------------
// Entry type for unified feed
// ---------------------------------------------------------------------------

enum _EntryType { reflection, builtDua }

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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reflectState = ref.watch(reflectProvider);
    final duasState = ref.watch(duasProvider);

    final reflections = reflectState.savedReflections;
    final builtDuas = duasState.savedBuiltDuas;

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
    ]..sort((a, b) => b.date.compareTo(a.date));

    final totalCount = reflections.length + builtDuas.length;

    // Most connected name
    String? topName;
    if (reflections.isNotEmpty) {
      final freq = <String, int>{};
      for (final r in reflections) {
        freq[r.name] = (freq[r.name] ?? 0) + 1;
      }
      topName = freq.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(totalCount, topName, reflections.length),
            _buildStatsStrip(totalCount, reflections.length, builtDuas.length),
            const SizedBox(height: AppSpacing.lg), // Increased: 12→24 for breathing room
            _buildTabs(),
            Expanded(
              child: IndexedStack(
                index: _tab.index,
                children: [
                  _buildAllFeed(allEntries),
                  _buildReflectionsTab(reflections),
                  _buildDuasTab(builtDuas),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(int total, String? topName, int reflectionCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, AppSpacing.pagePadding, AppSpacing.pagePadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Journal',
                  style: AppTypography.displayLarge
                      .copyWith(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 4),
              Text(
                total == 0
                    ? 'Your spiritual diary'
                    : '$total saved entries',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          if (topName != null && reflectionCount >= 3) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBD9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.secondary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Most connected with $topName this month',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg), // Increased: 16→24 for hierarchy
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Stats strip ─────────────────────────────────────────────────────────────

  // Keyword → theme bucket mapping
  static const _themeBuckets = <String, List<String>>{
    'Anxiety & Worry': ['anxious', 'anxiety', 'stressed', 'stress', 'worry', 'worried', 'nervous', 'fear', 'scared', 'overwhelmed', 'panic'],
    'Relationships': ['family', 'friend', 'friends', 'wife', 'husband', 'mother', 'father', 'parents', 'sister', 'brother', 'relationship', 'people', 'nosy', 'marriage'],
    'Work & Career': ['job', 'work', 'career', 'business', 'money', 'salary', 'boss', 'interview', 'study', 'school', 'exam', 'university'],
    'Sadness & Grief': ['sad', 'sadness', 'grief', 'loss', 'lost', 'cry', 'crying', 'depressed', 'depression', 'lonely', 'alone', 'hurt'],
    'Gratitude': ['grateful', 'gratitude', 'thankful', 'blessed', 'blessing', 'alhamdulillah', 'happy', 'joy', 'peace'],
    'Guidance': ['confused', 'decision', 'istikhara', 'guidance', 'direction', 'know', 'should', 'proceed', 'unsure', 'doubt'],
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

  Widget _buildStatsStrip(int total, int reflections, int builtDuas) {
    final statsAsync = ref.watch(_journalStatsProvider);
    final savedReflections = ref.watch(reflectProvider).savedReflections;

    // Unique Names encountered
    final uniqueNames = savedReflections.map((r) => r.name).toSet().length;

    // Days active this week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final reflectionDates = savedReflections
        .map((r) => DateTime.parse(r.date))
        .toSet();
    final activeDays = List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      return reflectionDates.any((d) =>
          d.year == day.year && d.month == day.month && d.day == day.day);
    });

    final topTheme = _topTheme(savedReflections);

    return statsAsync.when(
      loading: () => const SizedBox(height: 120),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding, 0, AppSpacing.pagePadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 4 stat tiles ──
            Row(
              children: [
                _statTile(
                  icon: '📖',
                  value: '$reflections',
                  label: 'Reflections',
                  color: AppColors.primary,
                  bgColor: const Color(0xFFE8F5EE),
                ),
                const SizedBox(width: 10),
                _statTile(
                  icon: '🤲',
                  value: '$builtDuas',
                  label: 'Personal duas',
                  color: AppColors.secondary,
                  bgColor: const Color(0xFFF5EBD9),
                ),
                const SizedBox(width: 10),
                _statTile(
                  icon: '✨',
                  value: '$uniqueNames',
                  label: 'Names met',
                  color: const Color(0xFF6B4E9B),
                  bgColor: const Color(0xFFF3EEFF),
                ),
                const SizedBox(width: 10),
                _statTile(
                  icon: '⭐',
                  value: '${stats.xp.totalXp}',
                  label: 'Total XP',
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Week activity dots ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Text(
                    'This week',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...List.generate(7, (i) {
                    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    final isToday = i == now.weekday - 1;
                    final active = activeDays[i];
                    return Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? AppColors.primary
                                  : isToday
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : const Color(0xFFF0EBE3),
                              border: isToday && !active
                                  ? Border.all(color: AppColors.primary, width: 1.5)
                                  : null,
                            ),
                            child: active
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : Center(
                                    child: Text(
                                      dayLabels[i],
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: isToday
                                            ? AppColors.primary
                                            : AppColors.textTertiaryLight,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Theme insight card (3+ reflections) ──
            if (topTheme != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        'You often bring $topTheme to Allah',
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
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _statTile({
    required String icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.labelLarge.copyWith(
                color: color,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    const labels = ['All', 'Reflections', 'Duas'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.bodyMedium
            .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            AppTypography.bodyMedium.copyWith(fontSize: 13),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondaryLight,
        tabs: labels.map((l) => Tab(text: l)).toList(),
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
      children: entries.asMap().entries
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

  Widget _buildDuasTab(List<SavedBuiltDua> builtDuas) {
    if (builtDuas.isEmpty) {
      return _buildEmptyState(
        icon: Icons.brightness_3_outlined,
        message: 'No personal duas yet',
        sub: 'Build a dua for your specific need and it will be saved here.',
        actionLabel: 'Build a Dua',
        onAction: () => context.go('/duas'),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 32),
      children: builtDuas.asMap().entries
          .map((e) => _animatedCard(e.key, _buildBuiltDuaCard(e.value)))
          .toList(),
    );
  }

  // ── Entry card dispatcher ───────────────────────────────────────────────────

  Widget _buildEntryCard(_JournalEntry entry) {
    switch (entry.type) {
      case _EntryType.reflection:
        return _buildReflectionCard(entry.data as SavedReflection);
      case _EntryType.builtDua:
        return _buildBuiltDuaCard(entry.data as SavedBuiltDua);
    }
  }

  // ── Reflection card ─────────────────────────────────────────────────────────

  Widget _buildReflectionCard(SavedReflection r) {
    final date = DateTime.parse(r.date);
    return _ExpandableCard(
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(reflectProvider.notifier).deleteReflection(r.id);
            },
            child: Text(
              'Remove',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight),
            ),
          ),
        ],
      ),
    );
  }

  // ── Built dua card ──────────────────────────────────────────────────────────

  Widget _buildBuiltDuaCard(SavedBuiltDua d) {
    final date = DateTime.parse(d.savedAt);
    return _ExpandableCard(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            d.arabic,
            style: AppTypography.quranArabic.copyWith(fontSize: 18),
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      expanded: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            d.arabic,
            style: AppTypography.quranArabic.copyWith(fontSize: 22),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
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
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(duasProvider.notifier).removeSavedBuiltDua(d.id);
            },
            child: Text(
              'Remove',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight),
            ),
          ),
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
    return Center(
      child: Transform.translate(
        offset: const Offset(0, 40), // Move down for better visual centering
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBD9),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    width: 1.5),
              ),
              child: Icon(icon,
                  color: AppColors.secondary.withValues(alpha: 0.7), size: 32),
            ),
            const SizedBox(height: 20),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  child: Text(
                    actionLabel,
                    style: AppTypography.labelLarge
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      label = '${months[date.month - 1]} ${date.day}';
    }
    return Text(
      label,
      style: AppTypography.bodySmall
          .copyWith(color: AppColors.textTertiaryLight),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable expandable card
// ---------------------------------------------------------------------------

class _ExpandableCard extends StatefulWidget {
  const _ExpandableCard({
    required this.topLeft,
    required this.topRight,
    required this.summary,
    required this.expanded,
  });

  final Widget topLeft;
  final Widget topRight;
  final Widget summary;
  final Widget expanded;

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _open = !_open);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
            // Expand toggle hint
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
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
              child: _open ? widget.expanded : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
