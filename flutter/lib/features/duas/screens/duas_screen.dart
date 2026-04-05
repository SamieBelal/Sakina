import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/token_gate_sheet.dart';

class DuasScreen extends ConsumerStatefulWidget {
  const DuasScreen({super.key});

  @override
  ConsumerState<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends ConsumerState<DuasScreen>
    with TickerProviderStateMixin {
  late final List<AnimationController> _rippleControllers;
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _buildController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rippleControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      );
    });
  }

  void _startRipple() {
    for (var i = 0; i < _rippleControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 530), () {
        if (mounted) _rippleControllers[i].repeat();
      });
    }
  }

  void _stopRipple() {
    for (final c in _rippleControllers) {
      c.stop();
      c.reset();
    }
  }

  @override
  void dispose() {
    for (final c in _rippleControllers) {
      c.dispose();
    }
    _findController.dispose();
    _buildController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duasProvider);
    final notifier = ref.read(duasProvider.notifier);

    // Show token gate sheet when build-a-dua hits free limit
    ref.listen<DuasState>(duasProvider, (prev, next) {
      if (next.buildNeedsToken && !(prev?.buildNeedsToken ?? false)) {
        showTokenGateSheet(
          context,
          featureName: 'Build a Dua',
          cost: tokenCostBuiltDua,
        ).then((approved) {
          if (approved) notifier.submitBuildWithToken();
        });
      }
    });

    if (state.findLoading || state.buildLoading) {
      _startRipple();
    } else {
      _stopRipple();
    }

    // Ameen screen has primary background
    final isAmeen =
        state.activeTab == DuasTab.build && state.buildCurrentSection == 4;

    return Scaffold(
      backgroundColor:
          isAmeen ? AppColors.primary : const Color(0xFFFBF7F2),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(DuasState state, DuasNotifier notifier) {
    if (state.activeTab == null) return _buildLanding(notifier);

    switch (state.activeTab!) {
      case DuasTab.browse:
        return _buildBrowseTab(state, notifier);
      case DuasTab.find:
        return _buildFindTab(state, notifier);
      case DuasTab.build:
        return _buildBuildTab(state, notifier);
    }
  }

  // ===========================================================================
  // LANDING
  // ===========================================================================

  Widget _buildLanding(DuasNotifier notifier) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Stack(
          children: [
            // Arabic watermark
            Positioned(
              right: -8,
              top: 60,
              child: Text(
                'بِسْمِ اللَّهِ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 72,
                  color: AppColors.secondary.withValues(alpha: 0.10),
                  height: 1,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Hero crescent icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBD9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.brightness_3,
                      color: AppColors.secondary,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Duas',
                  style: AppTypography.displayLarge
                      .copyWith(color: AppColors.textPrimaryLight),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover, find, and build your duas',
                  style: AppTypography.bodyLarge
                      .copyWith(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 12),
                // Gold divider
                Container(
                  width: 48,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 28),
                _landingCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Browse Duas',
                  subtitle: '~100 authentic duas by category',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.setActiveTab(DuasTab.browse);
                  },
                ),
                const SizedBox(height: 12),
                _landingCard(
                  icon: Icons.travel_explore,
                  title: 'Find a Dua',
                  subtitle: 'Describe your need, get authentic duas',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.setActiveTab(DuasTab.find);
                  },
                ),
                const SizedBox(height: 12),
                _landingCard(
                  icon: Icons.auto_awesome,
                  title: 'Build a Dua',
                  subtitle: 'AI constructs a personal dua for you',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.setActiveTab(DuasTab.build);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _landingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBD9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBD9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BROWSE TAB
  // ===========================================================================

  Widget _buildBrowseTab(DuasState state, DuasNotifier notifier) {
    final filteredDuas = notifier.filteredBrowseDuas;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, 16, AppSpacing.pagePadding, 0,
            ),
            child: _tabHeader('Browse Duas', notifier),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              child: Row(
                children: duaCategories.map((cat) {
                  final selected = cat == state.selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        notifier.setCategory(cat);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.secondary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.secondary
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          cat[0].toUpperCase() + cat.substring(1),
                          style: AppTypography.bodyMedium.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondaryLight,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              itemCount: filteredDuas.length,
              itemBuilder: (context, index) {
                return _browseDuaCard(
                    filteredDuas[index], state, notifier);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _browseDuaCard(
      BrowseDua dua, DuasState state, DuasNotifier notifier) {
    final isSaved = state.savedDuaIds.contains(dua.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Stack(
        children: [
          // Gold book icon top-left
          Positioned(
            top: 12,
            left: 12,
            child: Icon(
              Icons.menu_book_rounded,
              size: 14,
              color: AppColors.secondary.withValues(alpha: 0.5),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(36, 8, 48, 0),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dua.title, style: AppTypography.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    dua.arabic,
                    style: AppTypography.quranArabic,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              children: [
                Divider(color: AppColors.secondary.withValues(alpha: 0.15)),
                const SizedBox(height: 8),
                Text(
                  dua.transliteration,
                  style: AppTypography.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(dua.translation, style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  dua.source,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiaryLight),
                ),
                if (dua.whenToRecite != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    dua.whenToRecite!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                notifier.toggleSavedDua(dua.id);
              },
              child: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? AppColors.primary : AppColors.textTertiaryLight,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FIND TAB
  // ===========================================================================

  Widget _buildFindTab(DuasState state, DuasNotifier notifier) {
    if (state.findLoading) return _buildFindLoading();
    if (state.findResult != null) return _buildFindResults(state, notifier);
    return _buildFindInput(state, notifier);
  }

  Widget _buildFindInput(DuasState state, DuasNotifier notifier) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _tabHeader('Find a Dua', notifier),
            const SizedBox(height: 8),
            Text(
              'Describe what you need and we\'ll find authentic duas from Quran and Sunnah.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _findController,
              maxLines: 3,
              onChanged: notifier.setFindNeed,
              decoration: _inputDecoration('What do you need a dua for...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.findNeed.trim().isEmpty
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        notifier.submitFind();
                      },
                style: _primaryButtonStyle(),
                child: const Text('Find Duas'),
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              _errorBox(state.error!),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildFindLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _rippleWidget(),
          const SizedBox(height: 32),
          Text('Finding duas...', style: AppTypography.headlineMedium),
        ],
      ),
    );
  }

  Widget _buildFindResults(DuasState state, DuasNotifier notifier) {
    final result = state.findResult!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _tabHeader('Find a Dua', notifier),
            const SizedBox(height: 24),
            if (result.names.isNotEmpty) ...[
              Text(
                'Names to Call Upon',
                style: AppTypography.headlineMedium
                    .copyWith(color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 12),
              ...result.names.map(_nameCard),
              const SizedBox(height: 24),
            ],
            Text(
              'Duas to Recite',
              style: AppTypography.headlineMedium
                  .copyWith(color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 12),
            ...result.duas.map(_foundDuaCard),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _findController.clear();
                  notifier.resetFind();
                },
                child: Text(
                  'Search again',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _nameCard(FindDuasNameEntry name) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border(
          bottom: BorderSide(
            color: AppColors.secondary.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 6),
              Text(
                name.name,
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name.nameArabic,
            style: AppTypography.quranArabic.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 22,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            name.why,
            style: AppTypography.bodyMedium
                .copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _foundDuaCard(FindDuasDuaEntry dua) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Stack(
        children: [
          // Gold crescent icon top-left
          Positioned(
            top: 14,
            left: 12,
            child: Icon(
              Icons.brightness_3,
              size: 13,
              color: AppColors.secondary.withValues(alpha: 0.55),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(34, 0, 16, 0),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(dua.title, style: AppTypography.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    dua.arabic,
                    style: AppTypography.quranArabic,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
              children: [
                Divider(color: AppColors.secondary.withValues(alpha: 0.15)),
                const SizedBox(height: 8),
                Text(
                  dua.transliteration,
                  style: AppTypography.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(dua.translation, style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  dua.source,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD TAB
  // ===========================================================================

  Widget _buildBuildTab(DuasState state, DuasNotifier notifier) {
    if (state.buildLoading) return _buildBuildLoading();
    if (state.buildResult != null && state.buildCurrentSection < 4) {
      return _buildStepViewer(state, notifier);
    }
    if (state.buildResult != null && state.buildCurrentSection == 4) {
      return _buildAmeenScreen(state, notifier);
    }
    return _buildBuildInput(state, notifier);
  }

  Widget _buildBuildInput(DuasState state, DuasNotifier notifier) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _tabHeader('Build a Dua', notifier),
            const SizedBox(height: 8),
            Text(
              'Describe your specific need and we\'ll construct a personal dua following authentic prophetic etiquette.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            // Elegant stepped indicator
            Row(
              children: [
                _elegantStepPill('1', 'Praise'),
                _goldStepLine(),
                _elegantStepPill('2', 'Salawat'),
                _goldStepLine(),
                _elegantStepPill('3', 'Ask'),
                _goldStepLine(),
                _elegantStepPill('4', 'Close'),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _buildController,
              maxLines: 3,
              onChanged: notifier.setBuildNeed,
              decoration: _inputDecoration('What do you need a dua for...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.buildNeed.trim().isEmpty
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        notifier.submitBuild();
                      },
                style: state.buildNeed.trim().isEmpty
                    ? _primaryButtonStyle()
                    : _primaryButtonStyleGold(),
                child: const Text('Build My Dua'),
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              _errorBox(state.error!),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _elegantStepPill(String number, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EBD9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              number,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _goldStepLine() {
    return Container(
      width: 16,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.secondary.withValues(alpha: 0.35),
    );
  }

  Widget _buildBuildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _rippleWidget(),
          const SizedBox(height: 32),
          Text('Constructing your dua...',
              style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Praise \u00b7 Salawat \u00b7 Your ask \u00b7 Closing',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStepViewer(DuasState state, DuasNotifier notifier) {
    final section = state.buildResult!.breakdown[state.buildCurrentSection];
    final isLast = state.buildCurrentSection == 3;

    final sectionIcons = [
      Icons.volunteer_activism,
      Icons.favorite_rounded,
      Icons.record_voice_over_rounded,
      Icons.spa_rounded,
    ];
    final sectionIcon = state.buildCurrentSection < sectionIcons.length
        ? sectionIcons[state.buildCurrentSection]
        : Icons.auto_awesome;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _tabHeader('Build a Dua', notifier),
            const SizedBox(height: 24),
            // Gold progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i <= state.buildCurrentSection;
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? AppColors.secondary
                        : AppColors.borderLight,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Section label with gold dot + icon
            Row(
              children: [
                const Text(
                  '●',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(sectionIcon, color: AppColors.secondary, size: 16),
                const SizedBox(width: 6),
                Text(
                  section.label,
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Arabic card with gold shimmer border + left accent bar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Gold left accent bar
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.cardRadius),
                        bottomLeft: Radius.circular(AppSpacing.cardRadius),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        section.arabic,
                        style: AppTypography.quranArabic
                            .copyWith(color: Colors.white),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Transliteration',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textSecondaryLight),
                ),
                children: [
                  Text(
                    section.transliteration,
                    style: AppTypography.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Translation',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textSecondaryLight),
                ),
                children: [
                  Text(section.translation, style: AppTypography.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.nextBuildSection();
                },
                style: _primaryButtonStyle(),
                child: Text(isLast ? 'Complete' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAmeenScreen(DuasState state, DuasNotifier notifier) {
    final result = state.buildResult!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Radial gold glow behind آمين
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.18),
                        AppColors.secondary.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '\u0622\u0645\u064a\u0646',
                      style: AppTypography.nameOfAllahDisplay
                          .copyWith(color: Colors.white, fontSize: 64),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ameen',
                      style: AppTypography.displayLarge
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Save built dua button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: notifier.isBuiltDuaSaved()
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        notifier.saveCurrentBuiltDua();
                      },
                icon: Icon(
                  notifier.isBuiltDuaSaved()
                      ? Icons.check_circle
                      : Icons.bookmark_add_outlined,
                ),
                label: Text(
                  notifier.isBuiltDuaSaved() ? 'Dua Saved' : 'Save This Dua',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.8),
                  disabledForegroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Names Called Upon card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Names Called Upon',
                    style: AppTypography.headlineMedium
                        .copyWith(color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 12),
                  ...result.namesUsed.map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: AppColors.secondary),
                                const SizedBox(width: 6),
                                Text(n.name,
                                    style: AppTypography.labelLarge),
                                const SizedBox(width: 8),
                                Text(
                                  n.nameArabic,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.why,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Related Duas card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Related Duas',
                    style: AppTypography.headlineMedium
                        .copyWith(color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 12),
                  ...result.relatedDuas.map((d) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF7F2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border(
                            left: BorderSide(
                              color: AppColors.secondary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      notifier.toggleSaveRelatedDua(d);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          right: 12, top: 4),
                                      child: Icon(
                                        notifier.isRelatedDuaSaved(d)
                                            ? Icons.favorite
                                            : Icons.favorite_outline,
                                        color: notifier.isRelatedDuaSaved(d)
                                            ? AppColors.primary
                                            : AppColors.textTertiaryLight,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      d.arabic,
                                      style: AppTypography.quranArabic
                                          .copyWith(fontSize: 20),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  d.transliteration,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: Text(d.translation,
                                    style: AppTypography.bodyMedium),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  d.source,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _buildController.clear();
                  notifier.resetBuild();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: const Text('Build another dua'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ===========================================================================
  // SHARED HELPERS
  // ===========================================================================

  Widget _tabHeader(String title, DuasNotifier notifier) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.setActiveTab(null);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EBD9),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(Icons.arrow_back_ios,
                size: 16, color: AppColors.secondary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTypography.headlineLarge
              .copyWith(color: AppColors.textPrimaryLight),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: AppTypography.bodyMedium
          .copyWith(color: AppColors.textTertiaryLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
    );
  }

  ButtonStyle _primaryButtonStyleGold() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        side: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
    );
  }

  Widget _rippleWidget() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _rippleControllers[index],
              builder: (context, child) {
                final value = _rippleControllers[index].value;
                final scale = 0.3 + (2.2 - 0.3) * value;
                final opacity = (0.6 - 0.6 * value).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          const Icon(
            Icons.auto_awesome,
            color: AppColors.secondary,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.error)),
    );
  }
}
