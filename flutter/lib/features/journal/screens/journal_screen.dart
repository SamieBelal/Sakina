import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/constants/fade_through_route.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/motion_context.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
// `premiumStateProvider` — the compose sheet's cost line differs for a
// subscriber. See [showRadialComposeMenu].
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/widgets/add_to_tonight_card.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_compose_action.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';
import 'package:sakina/features/journal/journal_search.dart';
import 'package:sakina/features/journal/journal_themes.dart';
import 'package:sakina/features/journal/widgets/answered_dua_card.dart';
import 'package:sakina/features/journal/widgets/on_this_night_card.dart';
import 'package:sakina/features/journal/widgets/radial_compose_menu.dart';
import 'package:sakina/features/journal/widgets/weekly_recap_line.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/features/streaks/providers/month_of_light_provider.dart';
import 'package:sakina/features/streaks/widgets/month_of_light.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/daily_question_analytics.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/features/journal/screens/reflection_detail_page.dart';
import 'package:sakina/features/journal/screens/reflection_story_page.dart';
import 'package:sakina/features/journal/screens/weekly_recap_story_page.dart';
import 'package:sakina/features/journal/screens/dua_detail_page.dart';
import 'package:sakina/widgets/coachmark/tour_anchor.dart';
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

// Invalidated every time the Badges tab is opened (see the TabController
// listener in _JournalScreenState) — without that, this caches the unlocked
// set from its first read and badges earned later in the session render as
// locked until app restart. `when` keeps the previous data while the refresh
// runs (skipLoadingOnRefresh), so re-entering the tab doesn't flicker.
final _achievementsProvider = FutureProvider<Set<String>>((ref) async {
  return getUnlockedAchievements();
});

// ---------------------------------------------------------------------------
// Today's local day (Wave E)
// ---------------------------------------------------------------------------

/// The user's own calendar day, for the three resurfacing surfaces.
///
/// `resolveUserLocalDay()` and not `DateTime.now()`, for the reason Wave B
/// wrote the column that way: `entry_local_day` is the user's LOCAL day, and a
/// device-clock date computed in a different zone lands "On This Night" on the
/// wrong night — near midnight, by a whole day.
///
/// `autoDispose` so re-entering the Journal after a rollover re-resolves. A
/// keep-alive provider would pin the day the app was launched on and quietly
/// stop matching the anchors after midnight.
final journalLocalDayProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    return (await resolveUserLocalDay()).dateString;
  } catch (_) {
    // Every Wave E surface treats a null day as "show nothing", so an
    // unresolvable timezone costs the cards and never the archive.
    return null;
  }
});

/// The week the Journal last gave the weekly recap its slot, or null.
///
/// Read once, at the start of a visit, and never invalidated: the write that
/// follows a show would otherwise re-run this and re-evaluate the gate against
/// the value just written. `autoDispose` so that LEAVING the Journal is what
/// re-reads it — but the answer is latched in `_recapAllowedThisVisit` rather
/// than read live, because this provider can also be disposed *mid-visit* (see
/// that field, and the search-mode note on `_gatedWeeklyRecap`).
///
/// Failures are indistinguishable from "never shown", which is the direction
/// the gate is safe in: a SharedPreferences that cannot be read shows the recap
/// rather than silencing it forever.
final journalRecapWeekProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString(supabaseSyncService.scopedKey(weeklyRecapLastWeekPrefsKey));
  } catch (_) {
    return null;
  }
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

/// The sort key for a saved related duʿā, which carries no timestamp of any
/// kind (see `SavedRelatedDua` — id, title, arabic, transliteration,
/// translation, source, and nothing else).
///
/// **D6, the sort bug.** This used to be `DateTime.now()`, evaluated during
/// `build`. A value that is by definition the newest instant in existence, on
/// every rebuild, pinned every saved duʿā to the top of the All feed forever —
/// so a duʿā saved eight months ago outranked tonight's muḥāsabah, and the feed
/// stopped being chronological the first time anyone tapped a heart.
///
/// The epoch is the honest replacement: *we do not know when this was saved*,
/// so it sorts below everything that does know, in a stable order, instead of
/// claiming to be the most recent thing the user did. Giving these entries a
/// real timestamp needs a column that does not exist; that is a migration, and
/// deliberately not in Wave D's scope.
final DateTime _undatedEntrySortKey =
    DateTime.fromMillisecondsSinceEpoch(0);

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

  /// One `journal_resurfacing_shown` per visit — see
  /// [_maybeEmitResurfacingShown]. Scoped to the State, so a bottom-nav
  /// tab-switch that rebuilds this screen re-arms it and a `setState` from the
  /// tab controller does not.
  bool _resurfacingFired = false;

  /// The weekly recap's cadence gate, answered once per visit and then held.
  /// Null until [_maybeEmitResurfacingShown] has both its async inputs. See
  /// [_gatedWeeklyRecap] for why this is a latch and not a live read.
  bool? _recapAllowedThisVisit;
  int _duaFilter = 0; // 0=All, 1=Built, 2=Saved
  int _lastTabIndex = 0;

  /// D1's half of the filter work: 0=All, 1=Nightly (muḥāsabah), 2=Reflect.
  ///
  /// The Reflections tab now holds two genuinely different kinds of entry —
  /// the nightly accounting, one per day, and an ad-hoc Reflect save — and
  /// before Wave B it could only ever hold the second. Mirrors `_duaFilter`'s
  /// shape exactly so the two chip rows behave identically.
  int _reflectionFilter = 0;

  /// Index of the Badges tab in [_buildScaffold]'s IndexedStack / TabBar.
  static const _achievementsTabIndex = 3;

  // ── Search (2026-08-06) ───────────────────────────────────────────────────
  //
  // Search is a MODE, not a fifth tab and not a fourth filter chip.
  //
  // The filters and the tabs both answer "which KIND of thing", and the archive
  // already has two rows of controls saying so. The question search answers —
  // "where is the night I wrote about my father" — is not a kind, it cuts across
  // every tab at once, and a per-tab search box would have meant a user who
  // searched from the wrong tab being told, truthfully and uselessly, that their
  // entry does not exist. So the whole screen becomes the results, and closing
  // it puts every one of those controls back exactly as it was.

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;

  /// The parsed query. Empty means "not filtering" even while the mode is open,
  /// which is what the prompt state renders.
  List<String> _searchTokens = const [];

  /// Set during build, read by [_searchDebounce] when it fires — the count is a
  /// property of the results the user is looking at, and that is the only place
  /// it is known.
  int _searchResultCount = 0;
  Timer? _searchDebounce;

  /// Debounced so `p` / `pa` / `pai` / `pain` is one `journal_searched` and not
  /// four. Long enough to sit out ordinary typing, short enough that a user who
  /// pauses to read their results has already been counted.
  static const _searchAnalyticsDebounce = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() {
      // Re-read the unlocked set on every arrival at the Badges tab so
      // achievements earned since the last visit render as unlocked.
      if (_tab.index != _lastTabIndex) {
        _lastTabIndex = _tab.index;
        if (_tab.index == _achievementsTabIndex) {
          ref.invalidate(_achievementsProvider);
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    // Cancelled, not left to fire: the timer's callback reads `ref` and calls
    // `setState`, and both are errors once this State is gone.
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
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
    _maybeEmitResurfacingShown(reflections, duasState);
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
            // No saved date on related duʿās — see [_undatedEntrySortKey] (D6).
            date: _undatedEntrySortKey,
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
    // Wave E's strip, resolved HERE so its `ref.watch` calls happen during
    // build. See [_buildResurfacingStrip].
    //
    // Built BEFORE the search branch even though search never renders it. It
    // holds the only surviving `ref.watch(journalLocalDayProvider)` once
    // `_resurfacingFired` latches, and that provider is `autoDispose`: skipping
    // this line while searching drops its last watcher, disposes it, and makes
    // closing search re-await a future — so the strip would pop back in a frame
    // late, every time.
    final resurfacing = _buildResurfacingStrip(reflections);

    if (_searching) return _buildSearchScaffold(allEntries);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      // D3 — the one primary control. It sits on the Scaffold rather than
      // inside a tab so it is present whichever tab is open: composing is a
      // property of the day, not of what you are currently browsing.
      floatingActionButton: _buildComposeButton(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              totalCount,
              reflections,
              builtDuas.length + savedDuas.length,
            ),
            if (totalCount > 0) _buildRecapBlock(reflections),
            const SizedBox(height: 20),
            _buildTabs(),
            Expanded(
              child: IndexedStack(
                index: _tab.index,
                children: [
                  _buildAllFeed(allEntries, resurfacing),
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

  Widget _buildHeader(
    int total,
    List<SavedReflection> reflections,
    int duasCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 20, AppSpacing.pagePadding, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Journal',
                        style: AppTypography.displayLarge
                            .copyWith(color: AppColors.textPrimaryLight))
                    .animate()
                    .fadeIn(duration: context.motion(AppMotion.entrance))
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: context.motion(AppMotion.entrance),
                      curve: AppMotion.enter,
                    ),
                const SizedBox(height: 6),
                Text(
                  _statsLine(total, reflections, duasCount),
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiaryLight),
                ).animate().fadeIn(
                      duration: context.motion(AppMotion.entrance),
                      delay: context.motion(AppMotion.beat),
                    ),
              ],
            ),
          ),
          _buildSearchButton(),
          _buildBrowseButton(reflections),
        ],
      ),
    );
  }

  // ── Search (2026-08-06) ─────────────────────────────────────────────────────

  /// The entry point, next to the calendar.
  ///
  /// Both are ways of *finding* an entry rather than of making one, so they sit
  /// together in the header and leave the compose FAB as the only primary
  /// control on the screen (D3). Search first, because it is the one that works
  /// on a journal of any size.
  Widget _buildSearchButton() {
    return Semantics(
      button: true,
      label: 'Search your journal',
      child: IconButton(
        onPressed: _openSearch,
        icon: const Icon(Icons.search_rounded, size: 22),
        color: AppColors.textSecondaryLight,
        tooltip: 'Search',
      ),
    ).animate().fadeIn(
          duration: context.motion(AppMotion.entrance),
          delay: context.motion(AppMotion.beat),
        );
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    setState(() => _searching = true);
    // After the frame that builds the field — a focus request against a node
    // whose widget does not exist yet is dropped, and the keyboard never opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searching) _searchFocus.requestFocus();
    });
  }

  /// Leaves search and forgets the query.
  ///
  /// The query is cleared rather than kept, so re-opening search starts from the
  /// prompt. A box that reopens holding a half-typed word from twenty minutes
  /// ago is answering a question the user is no longer asking, and the archive
  /// behind it would come back pre-filtered with no visible reason why.
  void _closeSearch() {
    _searchDebounce?.cancel();
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() {
      _searching = false;
      _searchTokens = const [];
      _searchResultCount = 0;
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchTokens = journalSearchTokens(value));
    _searchDebounce?.cancel();
    if (_searchTokens.isEmpty) return;
    // Reads [_searchResultCount], which the build triggered by the `setState`
    // above will have written by the time this fires.
    _searchDebounce = Timer(_searchAnalyticsDebounce, () {
      if (!mounted) return;
      ref.read(analyticsProvider).track(
        AnalyticsEvents.journalSearched,
        properties: {
          AnalyticsEvents.propResultCount: _searchResultCount,
          AnalyticsEvents.propHasResults: _searchResultCount > 0,
        },
      );
    });
  }

  /// The whole screen while searching: the field, and the results.
  ///
  /// The stats row, the tab bar, the filter chips, the resurfacing strip and the
  /// compose FAB are all gone — deliberately. Results are the only thing on
  /// screen that can answer the question being asked, the keyboard is already
  /// covering half of it, and a FAB floating over a result list is a target for
  /// the thumb that is reaching past it.
  Widget _buildSearchScaffold(List<_JournalEntry> allEntries) {
    final results = _searchTokens.isEmpty
        ? const <_JournalEntry>[]
        : allEntries.where(_matchesSearch).toList();
    // Written during build on purpose — see [_searchResultCount].
    _searchResultCount = results.length;

    // A back gesture closes SEARCH, not the Journal. Search is a mode on this
    // screen rather than a pushed route, so without this the system back swipe
    // would skip straight past it to the previous tab and leave the user
    // wondering where the archive went.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF7F2),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              Expanded(child: _buildSearchResults(results)),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesSearch(_JournalEntry entry) {
    switch (entry.type) {
      case _EntryType.reflection:
        return reflectionMatchesSearch(
            entry.data as SavedReflection, _searchTokens);
      case _EntryType.builtDua:
        return builtDuaMatchesSearch(
            entry.data as SavedBuiltDua, _searchTokens);
      case _EntryType.savedDua:
        return relatedDuaMatchesSearch(
            entry.data as SavedRelatedDua, _searchTokens);
    }
  }

  Widget _buildSearchField() {
    final hasText = _searchController.text.isNotEmpty;
    return Padding(
      // Top matches the header's 32, so the field lands where the title was and
      // the screen does not jump when search opens.
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 32, AppSpacing.pagePadding, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Search your journal',
              textField: true,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Search your journal',
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textTertiaryLight),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textTertiaryLight),
                  suffixIcon: !hasText
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppColors.textTertiaryLight,
                          tooltip: 'Clear',
                        ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 4,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.borderLight, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.borderLight, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: _closeSearch,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondaryLight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 44),
            ),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: context.motion(AppMotion.feedback));
  }

  Widget _buildSearchResults(List<_JournalEntry> results) {
    if (_searchTokens.isEmpty) {
      return _searchMessage(
        'Search your entries, your duas and the Names.',
        sub: 'A word you wrote, a place, a feeling.',
      );
    }
    if (results.isEmpty) {
      return _searchMessage(
        'Nothing matches that.',
        sub: 'Try one word rather than a phrase — every word you type has to '
            'appear in the entry.',
      );
    }

    return ListView.builder(
      // The keyboard is up: dragging the list should put it away, the way every
      // other search list on the platform does.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 32),
      itemCount: results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              results.length == 1 ? '1 entry' : '${results.length} entries',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textTertiaryLight),
            ),
          );
        }
        return _animatedCard(
          index - 1,
          _buildEntryCard(
            results[index - 1],
            origin: AnalyticsEvents.originJournalSearch,
          ),
        );
      },
    );
  }

  /// The two quiet states of search — nothing typed, and nothing found.
  ///
  /// Deliberately not [_buildEmptyState]: that one carries a 200px illustration
  /// and a primary button, and neither belongs on a screen where the keyboard is
  /// already covering the bottom half and the user is mid-question.
  Widget _searchMessage(String message, {required String sub}) {
    return Align(
      alignment: const Alignment(0, -0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              sub,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiaryLight, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: context.motion(AppMotion.item));
  }

  // ── Browse (D4) ─────────────────────────────────────────────────────────────

  /// Promotes the month-of-light calendar from a read-only sheet buried behind
  /// the streak line to the Journal's browse control (D4).
  ///
  /// The calendar was already the right shape for this — it computes
  /// `lit / todayPending / excused / held / missed / future` from check-in
  /// history and renders gaps as *"an open invitation, not a gap"*. All it was
  /// missing was somewhere for a tap to go. Now `lit` opens that night's entry
  /// and `todayPending` starts tonight; every other state stays inert, which is
  /// what keeps the gentle framing honest.
  Widget _buildBrowseButton(List<SavedReflection> reflections) {
    return Semantics(
      button: true,
      label: 'Browse by month',
      child: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          // The denominator for `journal_entry_opened{origin:
          // journal_calendar}`. Without it a calendar nobody converts from
          // reads identically to one nobody opens, and D4's promotion of this
          // control from the streak line would be unfalsifiable.
          ref.read(analyticsProvider).track(AnalyticsEvents.journalBrowseOpened);
          showMonthOfLightSheet(
            context,
            onDaySelected: (day, state) => _onCalendarDay(day, state, reflections),
          );
        },
        icon: const Icon(Icons.calendar_month_rounded, size: 22),
        color: AppColors.textSecondaryLight,
        tooltip: 'Browse by month',
      ),
    ).animate().fadeIn(
          duration: context.motion(AppMotion.entrance),
          delay: context.motion(AppMotion.beat),
        );
  }

  void _onCalendarDay(
    DateTime day,
    MonthCellState state,
    List<SavedReflection> reflections,
  ) {
    if (state == MonthCellState.todayPending) {
      context.go('/muhasabah?$questionEntryQueryParam='
          '$questionEntryHomeCta');
      return;
    }
    final entry = _entryForDay(reflections, day);
    if (entry == null) {
      // A night the streak knows about but the journal does not: every night
      // completed before Wave B started persisting entries is one of these, and
      // so is a night whose write the server refused. Say so plainly rather
      // than open an empty page or do nothing at all.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That night was lit, but no entry was saved for it.'),
        ),
      );
      return;
    }
    _openReflection(entry, origin: AnalyticsEvents.originJournalCalendar);
  }

  /// The entry belonging to [day].
  ///
  /// `entry_local_day` first, because that is the column the night is filed
  /// under and the one the time machine joins on. The `saved_at` fallback
  /// catches the two kinds of row that have no local day at all: everything
  /// written before Wave B, and every Reflect save (which is not a night).
  ///
  /// Known seam, deliberately left: the calendar's cells are UTC days (it is
  /// aligned with `streak_service`, which is also UTC), while `entry_local_day`
  /// is the user's own local day. For a user far from UTC the two can differ by
  /// one, and then the fallback is what answers. Reconciling them is a change to
  /// the streak's day resolution, not to the Journal.
  SavedReflection? _entryForDay(
    List<SavedReflection> reflections,
    DateTime day,
  ) {
    final key = formatLocalDay(day);
    for (final r in reflections) {
      if (r.entryLocalDay == key) return r;
    }
    for (final r in reflections) {
      final d = DateTime.tryParse(r.date);
      if (d == null) continue;
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        return r;
      }
    }
    return null;
  }

  // ── Inline stats ───────────────────────────────────────────────────────────

  /// The lifetime theme line's source. Shared with the Wave E weekly recap via
  /// `journal_themes.dart` — the keyword list used to live here as a private
  /// constant, and a second copy of it for the recap would have been a copy free
  /// to disagree with this one the moment either gained a word.
  String? _topTheme(List<SavedReflection> reflections) =>
      journalTopTheme(reflections);

  /// The lifetime counts, as one quiet line under the title.
  ///
  /// This used to be a bordered box of four icon tiles — ~72px of the first
  /// screen spent on numbers nobody opens the Journal to read. The counts are
  /// worth keeping (they are the only place "19 Names" is ever stated) but not
  /// worth a card: they are context for the title, so they render as the
  /// title's subtitle and the screen starts ~92px higher.
  ///
  /// The streak segment is dropped while [_journalStatsProvider] is in flight
  /// or has failed, rather than holding the whole line behind a loader. A line
  /// that grows by one clause when the fetch lands is invisible; the 120px
  /// spinner that used to sit here was not.
  String _statsLine(
    int total,
    List<SavedReflection> reflections,
    int duasCount,
  ) {
    if (total == 0) return 'Your spiritual diary';

    final uniqueNames = reflections.map((r) => r.name).toSet().length;
    final parts = <String>[
      '$total ${total == 1 ? 'entry' : 'entries'}',
      if (duasCount > 0) '$duasCount ${duasCount == 1 ? 'duʿā' : 'duʿās'}',
      if (uniqueNames > 0) '$uniqueNames ${uniqueNames == 1 ? 'Name' : 'Names'}',
    ];

    final best = ref.watch(_journalStatsProvider).valueOrNull?.streak.longestStreak;
    if (best != null && best > 0) parts.add('best streak $best');

    return parts.join('  ·  ');
  }

  /// E2's weekly recap, else the lifetime theme line, else nothing.
  ///
  /// One slot, never both: the recap wins when the week has something in it AND
  /// the cadence gate lets it, exactly as before. What changed is that the slot
  /// is no longer nested inside the stats card — it is the first thing under
  /// the title, which is the only place on this screen worth spending on
  /// something the archive is OFFERING rather than something it holds.
  Widget _buildRecapBlock(List<SavedReflection> reflections) {
    final recap = _gatedWeeklyRecap(reflections);
    final topTheme = recap != null ? null : _topTheme(reflections);
    if (recap == null && topTheme == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 0),
      child: recap != null
          ? WeeklyRecapLine(
              recap: recap,
              onOpen: () => _openWeeklyRecapStory(recap),
            )
          // A caption, NOT a pill.
          //
          // This used to be a sand-filled rounded rect with the same ✦ mark the
          // recap line wears — so the archive's one slot held two things that
          // looked identical and behaved differently: the recap is a door onto
          // a story, and this is a sentence. A founder tapping this and getting
          // nothing is the whole reason it changed. Stripping the fill, the
          // border and the icon leaves the affordance where the behaviour is:
          // if it looks like a surface, it opens.
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'You often turn to Allah with $topTheme',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
            ),
    ).animate().fadeIn(duration: context.motion(AppMotion.layer));
  }

  // ── Tabs ────────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    const labels = ['All', 'Reflections', 'Duas', 'Badges'];
    // An underline row, not the four-segment pill this used to be. The pill
    // gave each tab a quarter of the width whether or not its word fitted, so
    // "Reflections" was scaled down by a `FittedBox` on every phone and the
    // four labels rendered at four different sizes. Underlined tabs are sized
    // by their own text, which is why they can afford to be 15px.
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      // Scrollable so a large text scale pushes the row sideways instead of
      // overflowing it — the `FittedBox` used to absorb that by shrinking, and
      // shrinking text is the wrong answer to someone who asked for bigger.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = _tab.index == i;
            return GestureDetector(
              // Keyed because the tab labels are not unique on this screen —
              // a `find.text` in a test would have to disambiguate.
              key: ValueKey('journal-tab-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tab.animateTo(i),
              child: Container(
                margin:
                    EdgeInsets.only(right: i == labels.length - 1 ? 0 : 24),
                // 12 top / 11 bottom keeps the target at ~44px without the
                // label sitting off-centre against the divider.
                padding: const EdgeInsets.only(top: 12, bottom: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          selected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? AppColors.textPrimaryLight
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── All feed ────────────────────────────────────────────────────────────────

  // ── Resurfacing (Wave E) ────────────────────────────────────────────────────

  /// Today, in the user's own timezone. Null until [journalLocalDayProvider]
  /// resolves (one frame) and on a device whose zone cannot be resolved at all.
  String? get _todayLocalDay =>
      ref.watch(journalLocalDayProvider).value;

  /// The weekly recap the Journal may actually show, or null.
  ///
  /// Two conditions, and the second is the new one. `resolveWeeklyRecap` is a
  /// WINDOW rule — two entries inside a rolling seven days — which for anyone
  /// writing regularly is true every single day, with content that barely moves
  /// between one day and the next. [weeklyRecapIsDue] turns that into a rhythm:
  /// at most one per calendar week. See its doc comment for why a content
  /// fingerprint was the worse of the two options.
  ///
  /// **The gate's answer is LATCHED for the visit** ([_recapAllowedThisVisit]),
  /// not re-derived here, and that is load-bearing rather than an optimisation.
  /// The marker is written the moment the recap is shown, so any later re-read
  /// of it answers "already spent" — and `journalRecapWeekProvider` is
  /// `autoDispose`, so anything that drops its last watcher for a frame makes it
  /// re-read. Entering search does exactly that (`_buildInlineStats` is not
  /// built in search mode), which without the latch would make the line vanish
  /// when the user cancelled a search. It is the same class of bug the
  /// `journalLocalDayProvider` note in [_buildScaffold] describes.
  ///
  /// Null until the latch is set — one frame of the lifetime theme line, which
  /// is better than a flash of a recap the gate is about to suppress.
  ///
  /// **The muḥāsabah completion screen does not go through here.** Its recap is
  /// already gated on having finished a night and on the time machine having
  /// stayed quiet, and it is the night's own closing card — see
  /// `muhasabah_screen.dart`.
  WeeklyRecap? _gatedWeeklyRecap(List<SavedReflection> reflections) {
    if (_recapAllowedThisVisit != true) return null;
    return resolveWeeklyRecap(
      entries: reflections,
      todayLocalDay: _todayLocalDay,
    );
  }

  /// Records that this week's recap has been spent.
  ///
  /// Fire-and-forget and latched to the visit: a failed write means the recap
  /// shows again, which is the harmless direction. Called from
  /// [_maybeEmitResurfacingShown] because that is the one place that already
  /// runs exactly once per visit, after both async inputs the gate depends on
  /// have resolved, and it is deciding the same boolean for the same reason.
  Future<void> _recordRecapShownThisWeek(String? todayLocalDay) async {
    final week = weeklyRecapWeekKey(todayLocalDay);
    if (week == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        supabaseSyncService.scopedKey(weeklyRecapLastWeekPrefsKey),
        week,
      );
    } catch (_) {
      // See above: an unwritten marker costs a repeat, not a lost recap.
    }
  }

  /// Opens the recap as a story on the sacred canvas.
  ///
  /// **The payload is structural only.** The line the user tapped is their own
  /// writing and the beat count is a property of the recap's SHAPE; neither the
  /// quote, nor a theme, nor a Name travels with the event.
  void _openWeeklyRecapStory(WeeklyRecap recap) {
    HapticFeedback.lightImpact();
    ref.read(analyticsProvider).track(
      AnalyticsEvents.journalRecapOpened,
      properties: {
        AnalyticsEvents.propEntryCount: recap.entryCount,
        AnalyticsEvents.propBeatCount: buildWeeklyRecapScreens(recap).length,
      },
    );
    Navigator.of(context, rootNavigator: true).push(
      fadeThroughRoute(
        context,
        WeeklyRecapStoryPage(recap: recap),
        name: 'WeeklyRecapStoryPage',
      ),
    );
  }

  /// The strip above the All feed: at most two cards, often none.
  ///
  /// **Order is the product decision.** The answered-duʿā prompt sits above
  /// "On This Night" because it is the only one of the three that asks the user
  /// for anything, and burying an ask under a reminiscence is how it gets
  /// missed and then repeated. Everything else in Wave E is passive.
  ///
  /// This is also the ceiling. Two is the most the archive may ever open with —
  /// the point of a journal is the entries, and a third card would make the
  /// first screen of it a briefing.
  ///
  /// **Built eagerly in [_buildScaffold], not inside the feed's `itemBuilder`.**
  /// It is item 0 of a `ListView.builder`, and an `itemBuilder` runs during
  /// LAYOUT — `ref.watch` there is outside the build phase, so the subscription
  /// it creates is not one the element reliably owns.
  Widget _buildResurfacingStrip(List<SavedReflection> reflections) {
    final onThisNight = resolveOnThisNight(
      entries: reflections,
      todayLocalDay: _todayLocalDay,
    );
    final duasState = ref.watch(duasProvider);
    final prompt = selectAnsweredDuaPrompt(
      duas: duasState.savedBuiltDuas,
      now: DateTime.now(),
      snoozedUntil: duasState.answeredPromptSnoozedUntil,
    );

    if (onThisNight == null && prompt == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prompt != null)
          AnsweredDuaCard(
            prompt: prompt,
            onAnswered: () => _markDuaAnswered(prompt.dua.id),
            onNotYet: () => ref
                .read(duasProvider.notifier)
                .snoozeAnsweredDuaPrompt(prompt.dua.id),
          ),
        if (onThisNight != null)
          OnThisNightCard(
            onThisNight: onThisNight,
            // The same door the calendar uses for a lit night: the story when
            // there is one, the detail page otherwise.
            onOpen: () => _openReflection(
              onThisNight.entry,
              origin: AnalyticsEvents.originOnThisNight,
            ),
          ),
      ],
    );
  }

  /// Wave H — **one event per Journal visit**, naming which of Wave E's three
  /// surfaces the archive opened with.
  ///
  /// Session-aggregated rather than a `shown` per card, which is the standing
  /// convention in this plan and here is also the only correct shape: all three
  /// resolve in the same build, all three are passive, and a per-card event
  /// emitted from `build` would count rebuilds rather than visits.
  ///
  /// Latched by [_resurfacingFired] and gated on the local day having RESOLVED.
  /// `journalLocalDayProvider` is a future, and every resolver returns null
  /// while it is loading — emitting on the first frame would report an
  /// all-quiet archive for every visit ever made.
  ///
  /// **The answered-duʿā boolean is a fact about the APP, not the user.** It
  /// records that the prompt was offered. Marking a duʿā answered emits nothing
  /// — a deliberate Wave E decision, pinned by a test in
  /// `built_dua_answered_status_test.dart`, and untouched here.
  void _maybeEmitResurfacingShown(
    List<SavedReflection> reflections,
    DuasState duasState,
  ) {
    if (_resurfacingFired) return;
    final dayAsync = ref.watch(journalLocalDayProvider);
    if (dayAsync.isLoading) return;
    // The cadence marker is the second async input the answer depends on. Its
    // `weekly_recap` boolean must mean "the archive opened with it", not "the
    // window would have allowed it" — otherwise the property counts something
    // no user ever saw.
    final weekAsync = ref.watch(journalRecapWeekProvider);
    if (weekAsync.isLoading) return;
    _resurfacingFired = true;

    final day = dayAsync.value;
    // The gate, decided ONCE for this visit — see [_gatedWeeklyRecap] for why
    // it may not be re-derived after the marker below is written.
    _recapAllowedThisVisit = weeklyRecapIsDue(
      todayLocalDay: day,
      lastShownWeek: weekAsync.value,
    );
    final onThisNight =
        resolveOnThisNight(entries: reflections, todayLocalDay: day);
    final recap = _gatedWeeklyRecap(reflections);
    if (recap != null) unawaited(_recordRecapShownThisWeek(day));
    final prompt = selectAnsweredDuaPrompt(
      duas: duasState.savedBuiltDuas,
      now: DateTime.now(),
      snoozedUntil: duasState.answeredPromptSnoozedUntil,
    );

    final analytics = ref.read(analyticsProvider);
    // Post-frame: `build` is not a place to run side effects, and the tracked
    // values are already captured above.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analytics.track(
        AnalyticsEvents.journalResurfacingShown,
        properties: {
          AnalyticsEvents.propOnThisNight: onThisNight != null,
          AnalyticsEvents.propWeeklyRecap: recap != null,
          AnalyticsEvents.propAnsweredPrompt: prompt != null,
          if (onThisNight != null)
            AnalyticsEvents.propOffsetDays: onThisNight.offsetDays,
        },
      );
    });
  }

  Future<void> _markDuaAnswered(String id) async {
    final ok = await ref
        .read(duasProvider.notifier)
        .setBuiltDuaAnswered(id, answered: true);
    if (!ok || !mounted) return;
    // A quiet confirmation, once. The undo lives on the duʿā itself rather than
    // in this snackbar — a mis-tap the user notices tomorrow still has to be
    // reversible, and a toast is gone in four seconds.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(JournalResurfacingCopy.answeredConfirmation),
      ),
    );
  }

  Widget _buildAllFeed(List<_JournalEntry> entries, Widget resurfacing) {
    if (entries.isEmpty) {
      final action = _composeAction;
      // Register the tour anchor on the empty hero as a fallback — the
      // tour step targeting `journal.firstEntry` (step 12) expects an
      // anchor here. By step 12 the user has just saved a dua, so the
      // list is normally non-empty; this is defense-in-depth.
      return TourAnchor(
        surface: TourSurface.journal,
        anchorId: 'firstEntry',
        // D3: the All tab's empty state used to describe what would eventually
        // appear here and offer no way to make any of it happen. It now carries
        // the same one control as the FAB, with copy that follows the day.
        child: _buildEmptyState(
          sub: JournalComposeCopy.emptyStateSub(action),
          actionLabel: JournalComposeCopy.label(action),
          onAction: () => _onCompose(
            action,
            entryPoint: AnalyticsEvents.composeEntryEmptyState,
          ),
        ),
      );
    }

    // D5: windowed. A daily journaler produces ~365 entries a year and Wave A
    // removed the five-entry cap that was the only thing keeping this list
    // short; a plain `ListView` with a materialised children list builds and
    // lays out every one of them on every frame.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 96),
      // +1 for the Wave E resurfacing strip, which scrolls with the feed rather
      // than pinning above it: it is something the archive OFFERS, not a banner
      // the archive is wearing, and a user who wants their entries can scroll
      // past it and never see it again.
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return resurfacing;
        final card =
            _animatedCard(index - 1, _buildEntryCard(entries[index - 1]));
        // Wrap only the first entry with the tour anchor so step 12 can
        // target it.
        if (index == 1) {
          return TourAnchor(
            surface: TourSurface.journal,
            anchorId: 'firstEntry',
            child: card,
          );
        }
        return card;
      },
    );
  }

  // ── Reflections tab ─────────────────────────────────────────────────────────

  Widget _buildReflectionsTab(List<SavedReflection> reflections) {
    if (reflections.isEmpty) {
      final action = _composeAction;
      return _buildEmptyState(
        icon: Icons.auto_awesome_outlined,
        message: 'No reflections yet',
        sub: 'Your nightly muḥāsabah and every Reflect session land here.',
        actionLabel: JournalComposeCopy.label(action),
        onAction: () => _onCompose(
          action,
          entryPoint: AnalyticsEvents.composeEntryEmptyState,
        ),
      );
    }

    // D1: filter by `source`. The chips render even when one side is empty —
    // an empty "Nightly" tab is itself the answer to "where are my muḥāsabah
    // entries", and hiding the chip would leave the question unanswered.
    final List<SavedReflection> visible;
    switch (_reflectionFilter) {
      case 1:
        visible = reflections.where((r) => r.isMuhasabah).toList();
      case 2:
        visible = reflections.where((r) => !r.isMuhasabah).toList();
      default:
        visible = reflections;
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 96),
      // +1 for the filter row, which scrolls with the list rather than pinning
      // above it (matching the Duas tab).
      itemCount: visible.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _filterChip('All', 0, _reflectionFilter,
                    (i) => setState(() => _reflectionFilter = i),
                    group: 'reflection'),
                const SizedBox(width: 8),
                // *"Muḥāsabah"*, not *"Nightly"* (2026-08-07).
                //
                // The muḥāsabah is NOT night-gated and never has been. It is
                // keyed on `entry_local_day` with a one-per-local-day unique
                // index, and nothing in the daily loop consults the clock to
                // decide whether it may be done — `MuhasabahCompletionCopy`
                // carries the whole note, and swaps its own header to *"Today
                // is written down"* before 17:00 for exactly this reason. A
                // filter labelled "Nightly" told a morning journaller their
                // 9am accounting was filed under the wrong word.
                //
                // It also now matches the chip on the cards it filters to,
                // which reads MUHĀSABAH. A filter and the thing it selects
                // should use one name.
                _filterChip('Muhāsabah', 1, _reflectionFilter,
                    (i) => setState(() => _reflectionFilter = i),
                    group: 'reflection'),
                const SizedBox(width: 8),
                // Matches its chip too — the cards read REFLECTION, and this
                // said "Reflect", which is the name of the SCREEN they are made
                // on rather than of the entry.
                _filterChip('Reflection', 2, _reflectionFilter,
                    (i) => setState(() => _reflectionFilter = i),
                    group: 'reflection'),
              ],
            ),
          );
        }
        final r = visible[index - 1];
        return _animatedCard(index - 1, _buildReflectionCard(r));
      },
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

    // Built lazily per index (D5) rather than materialised up front, so the
    // Duas tab windows exactly like the other two.
    final List<Widget Function()> duaBuilders;
    switch (_duaFilter) {
      case 1:
        duaBuilders = [for (final d in builtDuas) () => _buildBuiltDuaCard(d)];
      case 2:
        duaBuilders = [for (final d in savedDuas) () => _buildSavedDuaCard(d)];
      default:
        duaBuilders = [
          for (final d in builtDuas) () => _buildBuiltDuaCard(d),
          for (final d in savedDuas) () => _buildSavedDuaCard(d),
        ];
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 96),
      itemCount: duaBuilders.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _filterChip('All', 0, _duaFilter,
                    (i) => setState(() => _duaFilter = i),
                    group: 'dua'),
                const SizedBox(width: 8),
                _filterChip('Built', 1, _duaFilter,
                    (i) => setState(() => _duaFilter = i),
                    group: 'dua'),
                const SizedBox(width: 8),
                _filterChip('Saved', 2, _duaFilter,
                    (i) => setState(() => _duaFilter = i),
                    group: 'dua'),
              ],
            ),
          );
        }
        return _animatedCard(index - 1, duaBuilders[index - 1]());
      },
    );
  }

  /// One filter chip. Shared by the Duas tab and (D1) the Reflections tab, so
  /// the two rows cannot drift into looking like different controls.
  ///
  /// [group] keys the chip. The labels are NOT unique on this screen — both
  /// filter rows start with "All", the tab row has an "All" of its own, and
  /// `IndexedStack` builds every tab whether or not it is showing, so a
  /// `find.text('All')` in a test matches up to three widgets and taps
  /// whichever the tree happens to reach first. Same reasoning as the
  /// `journal-tab-$i` keys.
  Widget _filterChip(
    String label,
    int index,
    int selectedIndex,
    ValueChanged<int> onSelect, {
    required String group,
  }) {
    final selected = selectedIndex == index;
    return GestureDetector(
      key: ValueKey('journal-filter-$group-$index'),
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect(index);
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
              AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 96),
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
                      .fadeIn(
                          delay: context.stagger(i),
                          duration: context.motion(AppMotion.item))
                      .slideY(
                          begin: 0.04,
                          end: 0,
                          delay: context.stagger(i),
                          duration: context.motion(AppMotion.item),
                          curve: AppMotion.enter);
                }),
              ];
            }),
          ],
        );
      },
    );
  }

  // ── Entry card dispatcher ───────────────────────────────────────────────────

  /// [origin] is where the card is being rendered, and it travels with the tap
  /// into `journal_entry_opened`. The feed's own value is the default because
  /// that is where every card was rendered before search existed; passing it
  /// explicitly from search is what keeps "people find things and read them"
  /// separable from "people scroll and read things".
  Widget _buildEntryCard(
    _JournalEntry entry, {
    String origin = AnalyticsEvents.originJournalFeed,
  }) {
    switch (entry.type) {
      case _EntryType.reflection:
        return _buildReflectionCard(entry.data as SavedReflection,
            origin: origin);
      case _EntryType.builtDua:
        return _buildBuiltDuaCard(entry.data as SavedBuiltDua);
      case _EntryType.savedDua:
        return _buildSavedDuaCard(entry.data as SavedRelatedDua);
    }
  }

  // ── Reflection card ─────────────────────────────────────────────────────────

  /// Opens an entry the way the archive is meant to be read (D2): the
  /// tap-through story flow when the entry has beats to render, the detail page
  /// otherwise.
  ///
  /// The detail page is not superseded — it owns share and delete, and it is
  /// still where the card's "View full" goes. This is the second door, not a
  /// replacement for the first.
  void _openReflectionStory(SavedReflection r, {required String origin}) {
    HapticFeedback.lightImpact();
    _trackEntryOpened(r, origin: origin, format: AnalyticsEvents.entryFormatStory);
    Navigator.of(context, rootNavigator: true).push(
      fadeThroughRoute(
        context,
        ReflectionStoryPage(reflection: r),
        name: 'ReflectionStoryPage',
      ),
    );
  }

  void _openReflectionDetail(SavedReflection r, {required String origin}) {
    HapticFeedback.lightImpact();
    _trackEntryOpened(r, origin: origin, format: AnalyticsEvents.entryFormatDetail);
    Navigator.of(context, rootNavigator: true).push(
      fadeThroughRoute(
          context,
          ReflectionDetailPage(
                reflection: r,
                onRemove: () =>
                    ref.read(reflectProvider.notifier).deleteReflection(r.id),
              )),
    );
  }

  /// Wave H — the re-read, which is the whole of Wave D's thesis and was
  /// unmeasurable before it.
  ///
  /// One event with an [origin] rather than one event per door: a story opened
  /// from the feed, from the calendar and from "On This Night" is the same act
  /// reached three ways, and three event names would have made the total
  /// require a union forever after.
  ///
  /// **Nothing derived from [r]'s text.** `source` is the row's own column and
  /// the format is a property of the entry's *shape*, not its content.
  void _trackEntryOpened(
    SavedReflection r, {
    required String origin,
    required String format,
  }) {
    ref.read(analyticsProvider).track(
      AnalyticsEvents.journalEntryOpened,
      properties: {
        AnalyticsEvents.propOrigin: origin,
        AnalyticsEvents.propFormat: format,
        AnalyticsEvents.propSource: r.isMuhasabah
            ? AnalyticsEvents.journalSourceMuhasabah
            : AnalyticsEvents.journalSourceReflect,
      },
    );
  }

  /// The calendar's destination for a lit night: the story when there is one,
  /// the detail page when the row is only the user's own words.
  void _openReflection(SavedReflection r, {required String origin}) {
    if (ReflectionStoryPage.canRenderAsStory(r)) {
      _openReflectionStory(r, origin: origin);
    } else {
      _openReflectionDetail(r, origin: origin);
    }
  }

  Widget _buildReflectionCard(
    SavedReflection r, {
    String origin = AnalyticsEvents.originJournalFeed,
  }) {
    final date = DateTime.parse(r.date);
    final canReadAsStory = ReflectionStoryPage.canRenderAsStory(r);
    return _ExpandableCard(
      // **The story IS the entry (2026-08-06).** Tapping a card used to open the
      // detail page, with the story behind a "Read as story" link on the card's
      // footer — so the format the archive was rebuilt around was the one you
      // had to opt into, and the two lines of grey text D2 was written to fix
      // stayed the default. The tap now opens the story and the link is gone.
      //
      // An entry with no beats still opens the detail page: for it the story
      // would be a cover card and nothing else, which is a worse read than the
      // page. `canRenderAsStory` is the same check that used to gate the link.
      onTap: () => canReadAsStory
          ? _openReflectionStory(r, origin: origin)
          : _openReflectionDetail(r, origin: origin),
      // The detail page is not orphaned by that swap, and it must not be: it is
      // the only home of share, delete and edit. The footer's "View full ›"
      // hint — already on every card, so this adds no control — becomes its
      // door. On an entry with no story it is inert, because the card's own tap
      // already goes there.
      onViewFull: !canReadAsStory
          ? null
          : () => _openReflectionDetail(r, origin: origin),
      // D1: the chip tells the two sources apart. A nightly accounting and an
      // ad-hoc Reflect save land in the same table and used to render with the
      // same word on them.
      topLeft: r.isMuhasabah
          ? _typeChip('Muhāsabah', AppColors.primary)
          : _typeChip('Reflection', AppColors.goldInk),
      topRight: _dateLabel(date),
      // The entry, unquoted. The quotation marks were there to mark 15px grey
      // italic as the user's voice; at 19px near-black leading the card, the
      // voice is unambiguous and the marks are two glyphs of chrome on the one
      // line that should have none.
      summary: _FadingText(
        r.userText,
        style: _entryWordsStyle,
        maxLines: 3,
      ),
      // The Name, on the footer rather than above the words.
      //
      // Reading order is now *what you carried* → *the Name you met*, which is
      // the order the night actually happened in. The badge used to sit first,
      // so every card opened with the app's answer before the user's question.
      leadingAction: _nameLine(r),
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
          fadeThroughRoute(
              context,
              name: 'DuaDetailPage',
              DuaDetailPage.fromBuiltDua(
                    d,
                    onRemove: () => ref
                        .read(duasProvider.notifier)
                        .removeSavedBuiltDua(d.id),
                  )),
        );
      },
      // E3's undo, and it lives HERE rather than only in the snackbar that
      // follows the mark: a mis-tap noticed a day later still has to be
      // reversible, and a toast is gone in four seconds.
      //
      // `leadingAction` and NOT the `expanded` block below, which on this card
      // is unreachable: `_ExpandableCard` renders `expanded` only when `onTap`
      // is null, and all three card builders on this screen pass one. That is a
      // pre-existing dead branch (the Remove buttons in all three `expanded`
      // blocks are unreachable too) — noted, not fixed here, because reviving it
      // changes the tap behaviour of every card in the archive.
      leadingAction: !d.isAnswered
          ? null
          : _cardTextAction(
              icon: Icons.undo_rounded,
              label: JournalResurfacingCopy.answeredUndo,
              onTap: () => ref
                  .read(duasProvider.notifier)
                  .setBuiltDuaAnswered(d.id, answered: false),
            ),
      // The chip is the only permanent trace of the answer, and it is a
      // statement, not a score: no date arithmetic, no "answered in 4 months",
      // nothing that turns a duʿā into a case that closed.
      topLeft: d.isAnswered
          ? _typeChip(
              JournalResurfacingCopy.answeredChip, AppColors.primary)
          : _typeChip('Personal Dua', AppColors.goldInk),
      topRight: _dateLabel(date),
      summary: _FadingText(
        d.need,
        style: _entryWordsStyle.copyWith(fontSize: 18),
        maxLines: 3,
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
          fadeThroughRoute(
              context,
              name: 'DuaDetailPage',
              DuaDetailPage.fromRelatedDua(
                    d,
                    onRemove: () => ref
                        .read(duasProvider.notifier)
                        .removeSavedRelatedDua(d.id),
                  )),
        );
      },
      topLeft: _typeChip('Saved Dua', AppColors.goldInk),
      topRight: Text(
        d.source,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiaryLight,
          letterSpacing: 0.2,
        ),
      ),
      summary: _FadingText(
        d.title,
        style: _entryWordsStyle.copyWith(fontSize: 18),
        maxLines: 3,
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
    ).animate().fadeIn(duration: context.motion(AppMotion.layer)).slideY(
          begin: 0.1,
          end: 0,
          duration: context.motion(AppMotion.layer),
          curve: AppMotion.enter,
        );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Feed entrance for one card.
  ///
  /// The delay used to be a raw `index * 50` with **no ceiling**, applied from
  /// three call sites with the list index. Item 20 waited 950ms, item 40 waited
  /// 1,950ms, item 100 waited 4,950ms. Because these are `ListView.builder`s
  /// the delay is keyed to the LIST index and not to when the item was built,
  /// so scrolling quickly into a long journal showed blank cards that faded in
  /// seconds later — worse the longer someone had been journaling, which is
  /// exactly backwards. `AppMotion`'s own doc names the ceiling it broke: *"a
  /// staggered reveal should settle inside ~800-900ms total."*
  ///
  /// `context.stagger` clamps at six steps (a seven-item span in 240ms) and
  /// returns zero under reduced motion, where a stagger is delay with no
  /// movement to justify it.
  Widget _animatedCard(int index, Widget child) {
    final delay = context.stagger(index);
    return child
        .animate()
        .fadeIn(delay: delay, duration: context.motion(AppMotion.item))
        .slideY(
          begin: 0.05,
          end: 0,
          delay: delay,
          duration: context.motion(AppMotion.item),
          curve: AppMotion.enter,
        );
  }

  /// A small text+icon control that lives inside a card without stealing the
  /// card's own tap: the inner [GestureDetector] wins the arena for its own
  /// bounds, so tapping the label opens the story and tapping anywhere else on
  /// the card still opens the detail page.
  Widget _cardTextAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Compose (D3) ────────────────────────────────────────────────────────────

  /// Reads the day's state off the daily loop and resolves the one control's
  /// meaning. See [resolveJournalComposeAction] for the rule.
  JournalComposeAction get _composeAction => ref.watch(
        dailyLoopProvider.select(
          (s) => resolveJournalComposeAction(
            tonightEntry: s.tonightEntry,
            checkinDone: s.checkinDone,
          ),
        ),
      );

  /// Everything the compose control may offer right now.
  List<JournalComposeAction> get _composeOptions => ref.watch(
        dailyLoopProvider.select(
          (s) => journalComposeOptions(
            tonightEntry: s.tonightEntry,
            checkinDone: s.checkinDone,
          ),
        ),
      );

  /// A permanent `+`.
  ///
  /// It used to be an extended FAB whose label and icon were resolved from the
  /// day — "Begin Muhāsabah", then "Add to today", then "Free write" — so the
  /// screen's one primary control changed identity three times a day without
  /// moving. This does one thing: it opens the chooser. What the chooser holds
  /// is allowed to vary; the control is not.
  Widget _buildComposeButton() {
    return FloatingActionButton(
      key: const ValueKey('journal-compose-fab'),
      onPressed: _openComposeSheet,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      tooltip: 'Write',
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  void _openComposeSheet() {
    HapticFeedback.lightImpact();
    final options = _composeOptions;
    // The denominator. `journal_compose_tapped` still fires per CHOSEN action,
    // so that series is unbroken — but with a sheet in between, "opened the
    // composer" and "composed" are now different numbers, and without this one
    // an abandoned sheet is indistinguishable from a FAB nobody pressed.
    ref.read(analyticsProvider).track(
      AnalyticsEvents.journalComposeOpened,
      properties: {AnalyticsEvents.propOptionCount: options.length},
    );

    showRadialComposeMenu(
      context,
      options: options,
      // Resolved here rather than inside the menu so the menu stays a dumb
      // widget. `valueOrNull ?? false` while the future is in flight: the free
      // copy names a cost, and briefly over-stating a cost is a much smaller
      // error than briefly hiding one.
      isPremium: ref.read(premiumStateProvider).valueOrNull?.isPremium ?? false,
      // Only fires on a CHOICE. A scrim tap, the ×, or the back gesture closes
      // the menu and calls nothing — a dismissed chooser is not a compose, so
      // it gets no event and no navigation.
      onPick: (action) {
        if (!mounted) return;
        _onCompose(action, entryPoint: AnalyticsEvents.composeEntryFab);
      },
    );
  }

  void _onCompose(
    JournalComposeAction action, {
    required String entryPoint,
  }) {
    HapticFeedback.lightImpact();
    // One control, three meanings (D3) — so the meaning is a property, not
    // three events. `entry_point` separates the FAB from the empty-state
    // rendering: the empty state is aimed at a user with nothing in the archive
    // yet, and whether THAT one converts is a different question.
    ref.read(analyticsProvider).track(
      AnalyticsEvents.journalComposeTapped,
      properties: {
        AnalyticsEvents.propAction: switch (action) {
          JournalComposeAction.startTonight =>
            AnalyticsEvents.composeActionStartTonight,
          JournalComposeAction.addToTonight =>
            AnalyticsEvents.composeActionAddToTonight,
          JournalComposeAction.newReflection =>
            AnalyticsEvents.composeActionNewReflection,
        },
        AnalyticsEvents.propEntryPoint: entryPoint,
      },
    );
    switch (action) {
      case JournalComposeAction.startTonight:
        context.go('/muhasabah?$questionEntryQueryParam='
          '$questionEntryHomeCta');
      case JournalComposeAction.newReflection:
        context.go('/reflect');
      case JournalComposeAction.addToTonight:
        _showAddToTonightSheet();
    }
  }

  /// The append sheet.
  ///
  /// Reuses `AddToTonightCard` and `DailyLoopNotifier.appendToTonight`
  /// unchanged — the same widget and the same write the completion screen uses.
  /// **This is the whole reason the append is safe from here:** `appendToTonight`
  /// is a pure text write against a row that already exists. It does not reveal
  /// a Name, mark the streak, claim the reward ladder, unseal the queue, engage
  /// a card or consume an allowance, and reaching it from a second surface adds
  /// no new way for any of that to fire.
  void _showAddToTonightSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.surfaceLight,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 4,
          bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final entry = ref.watch(
              dailyLoopProvider.select((s) => s.tonightEntry),
            );
            if (entry == null) {
              // The day rolled over while the sheet was open, or the entry went
              // away underneath it. Never leave a field that writes nowhere.
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  MuhasabahCompletionCopy.addFailed,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondaryLight),
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MuhasabahCompletionCopy.addToCtaFor(DateTime.now().hour),
                  style: AppTypography.headlineMedium
                      .copyWith(color: AppColors.textPrimaryLight),
                ),
                const SizedBox(height: AppSpacing.md),
                AddToTonightCard(
                  thread: entry.thread,
                  onAppend: (text) =>
                      ref.read(dailyLoopProvider.notifier).appendToTonight(
                            text,
                            surface: AnalyticsEvents.surfaceJournal,
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The entry's kind, as a caption on the background above its card.
  ///
  /// Was a filled 9px pill inside the card. Out on the page it needs no fill to
  /// be legible, so [color] survives only as a 6px dot — enough to tell the two
  /// sources apart at a glance down the feed, and the one thing the deleted
  /// 4px gold rail was supposed to be doing but could not, because every card
  /// got the same rail.
  ///
  /// Gold callers pass [AppColors.goldInk], not [AppColors.secondary]: at 6px
  /// the dot has no area to carry a tint, and `C8985E` sits at about 2.1:1 on
  /// this page. The dot is never the ONLY cue — the word next to it says the
  /// same thing — but a cue too faint to see is not worth the 13px it costs.
  Widget _typeChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  /// The Name, on a reflection card's footer.
  ///
  /// Two [Text]s, never one: Arabic and Latin in a single widget is banned
  /// (CLAUDE.md), and they need different faces anyway.
  Widget _nameLine(SavedReflection r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          r.nameArabic,
          // `AppTypography.quranArabic`, NOT a raw `fontFamily: 'Amiri'`
          // string. The app bundles no font assets at all — every face is
          // loaded at runtime by `google_fonts`, which registers Amiri under
          // the family name **`Amiri_regular`**. A literal `'Amiri'` therefore
          // matched nothing and fell back to the system font, so the Name on
          // every journal card rendered in SF/Roboto instead of Amiri. Same bug
          // class DESIGN.md §3 recorded for the hardcoded `'DM Sans'` in the
          // coachmark.
          style: AppTypography.quranArabic.copyWith(
            fontSize: 19,
            color: AppColors.primary,
            height: 1.1,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            r.name,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiaryLight,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable expandable card
// ---------------------------------------------------------------------------

/// Softer than [AppSpacing.cardRadius] (14), which is the app's radius for
/// dense controls. A journal card is the largest surface on its screen and 14
/// reads as tight at that size.
const double _cardRadius = 20;

/// The entry's own words, as the headline of its card.
///
/// This is the whole redesign in one style. The words used to render at
/// `bodyMedium` (15) in `textSecondaryLight` grey, italic, clamped to two lines
/// with an ellipsis — the smallest, faintest, most truncated thing on a card
/// whose only subject they are. The Name badge above them was larger and had a
/// filled background. On a journal, the entry outranks the app's label for it.
TextStyle get _entryWordsStyle => AppTypography.bodyLarge.copyWith(
      fontSize: 19,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryLight,
      height: 1.45,
      letterSpacing: -0.15,
    );

/// [Text] that fades out at the bottom when it overflows, instead of ellipsing.
///
/// An ellipsis reports that the string was cut; a fade reports that the entry
/// continues, which is the true thing and the one that invites the tap. It is
/// applied ONLY when the text actually overflows — an unconditional
/// [ShaderMask] would wash out the last line of every short entry, which is
/// most of them.
class _FadingText extends StatelessWidget {
  const _FadingText(this.text, {required this.style, required this.maxLines});

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measured with the SAME text scaler the paint will use, so a user at
        // 200% type does not get a fade over text that fits (or none over text
        // that does not).
        final probe = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = probe.didExceedMaxLines;
        probe.dispose();

        final child = Text(
          text,
          style: style,
          maxLines: maxLines,
          overflow: overflows ? TextOverflow.clip : TextOverflow.visible,
        );
        if (!overflows) return child;

        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Opaque until well into the last line, so only the final ~third
            // of it dissolves.
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.72, 1],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

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
    this.leadingAction,
    this.onViewFull,
  });

  final Widget topLeft;
  final Widget topRight;
  final Widget summary;
  final Widget expanded;
  final VoidCallback? onTap;

  /// A second control on the card's footer row, left of the "View full" hint.
  /// Only meaningful alongside [onTap] — the expand-toggle variant has no
  /// footer row to put it on.
  final Widget? leadingAction;

  /// Makes the footer's "View full ›" hint a real target, going somewhere other
  /// than [onTap].
  ///
  /// Added when a reflection card's tap became the story: the hint was already
  /// drawn on every card, so wiring it is the only way to keep the detail page
  /// — share, delete and edit — reachable WITHOUT putting another control on
  /// the card. Null leaves it what it has always been, a label describing where
  /// the card's own tap goes.
  final VoidCallback? onViewFull;

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _open = false;

  /// The footer's "View full ›".
  ///
  /// Inert unless [_ExpandableCard.onViewFull] is set, and then wrapped the way
  /// [_cardTextAction] wraps its own: an inner [GestureDetector] wins the arena
  /// for its own bounds, so this opens the detail page while a tap anywhere
  /// else on the card still opens the story.
  Widget _viewFullHint() {
    final hint = Row(
      mainAxisSize: MainAxisSize.min,
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
    );
    final onViewFull = widget.onViewFull;
    if (onViewFull == null) return hint;
    return Semantics(
      button: true,
      label: 'View full entry',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onViewFull();
        },
        // Padding, not a bigger font: the hint has to keep looking like a hint
        // while being large enough to hit.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: hint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: GestureDetector(
        onTap: widget.onTap ??
            () {
              HapticFeedback.selectionClick();
              setState(() => _open = !_open);
            },
        // Opaque so the gap between the metadata row and the card face is still
        // part of the card's target rather than a dead strip.
        //
        // The 26px separating one card from the next is NOT part of it, which is
        // why that space is a `Padding` outside this detector rather than a
        // `margin` inside it: an opaque detector hits its own margin box, so a
        // margin here would make the gap below every card open the card above it.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Metadata, OUTSIDE the card ──
            //
            // Type and date used to be the first row inside the card, at full
            // contrast, above the user's own words. That put the app's labels
            // ahead of the entry on the entry's own card. Out here they read as
            // what they are — a caption on the thing below — and the card face
            // is left for content only.
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
              child: Row(
                children: [
                  widget.topLeft,
                  const Spacer(),
                  widget.topRight,
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_cardRadius),
                // No border. The cream page behind these cards (#FBF7F2)
                // already separates a white surface from the background —
                // which is the job the reference art gets from its tints — so
                // the 1px outline was drawing a boundary that was already
                // visible, on every card, twice per gap.
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimaryLight.withValues(alpha: 0.045),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary (always visible)
                  widget.summary,
                  if (widget.onTap != null) ...[
                    // A hairline, not a gap: it separates the entry from the
                    // Name without spending another 12px on a screen whose
                    // whole complaint was density.
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(top: 18, bottom: 12),
                      color: AppColors.dividerLight,
                    ),
                    Row(
                      children: [
                        if (widget.leadingAction != null)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: widget.leadingAction!,
                            ),
                          )
                        else
                          const Spacer(),
                        _viewFullHint(),
                      ],
                    ),
                  ] else ...[
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
          ],
        ),
      ),
    );
  }
}
