import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/utils/keyboard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/dua_loading.dart';
import 'package:sakina/widgets/share_card.dart';
import 'package:sakina/widgets/token_gate_sheet.dart';

class DuasScreen extends ConsumerStatefulWidget {
  const DuasScreen({super.key});

  @override
  ConsumerState<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends ConsumerState<DuasScreen>
    with TickerProviderStateMixin {
  late final List<AnimationController> _rippleControllers;
  final TextEditingController _buildController = TextEditingController();
  final ScrollController _buildScrollController = ScrollController();
  final GlobalKey _textFieldKey = GlobalKey();
  bool _hasFocus = false;

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
    _buildController.dispose();
    _buildScrollController.dispose();
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

    if (state.buildLoading) {
      _startRipple();
    } else {
      _stopRipple();
    }

    final isAmeen = state.buildCurrentSection == 4 && state.buildResult != null;

    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: isAmeen ? AppColors.primary : const Color(0xFFFBF7F2),
        body: _buildBuildTab(state, notifier),
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
    final enabled = state.buildNeed.trim().isNotEmpty;
    return SafeArea(
      child: SingleChildScrollView(
        controller: _buildScrollController,
        padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 32,
            AppSpacing.pagePadding, AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tabHeader('Build a Dua', notifier),
            const SizedBox(height: 8),
            Text(
              'Describe your specific need and we\'ll construct a personal dua following authentic prophetic etiquette.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
            const SizedBox(height: 24),
            // Header illustration
            Center(
              child: SvgPicture.asset(
                'assets/illustrations/main_screens/duas_header.svg',
                height: 140,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.05, end: 0, duration: 600.ms, delay: 300.ms),
            const SizedBox(height: 24),
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
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
            const SizedBox(height: 24),
            // Text field with focus feedback
            Focus(
              onFocusChange: (focused) {
                setState(() => _hasFocus = focused);
                if (focused) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (!mounted) return;
                    if (_buildScrollController.hasClients) {
                      _buildScrollController.animateTo(
                        _buildScrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  color: _hasFocus
                      ? AppColors.primaryLight
                      : AppColors.surfaceLight,
                  border: Border.all(
                    color:
                        _hasFocus ? AppColors.primary : AppColors.borderLight,
                    width: _hasFocus ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  key: _textFieldKey,
                  controller: _buildController,
                  minLines: 6,
                  maxLines: 8,
                  onChanged: notifier.setBuildNeed,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    hintText: 'What do you need a dua for...',
                    hintStyle: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiaryLight),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 600.ms)
                .slideY(begin: 0.02, end: 0, duration: 400.ms, delay: 600.ms),
            const SizedBox(height: 16),
            // Submit button — AnimatedOpacity + shadow
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: enabled ? 1.0 : 0.5,
              child: GestureDetector(
                onTap: enabled
                    ? () {
                        HapticFeedback.mediumImpact();
                        notifier.submitBuild();
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Build My Dua',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              _errorBox(state.error!),
            ],
          ],
        ),
      ),
    );
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
    final progress = ref.watch(duasProvider.select((s) => s.buildProgress));
    return DuaLoading(progress: progress);
  }

  Widget _buildStepViewer(DuasState state, DuasNotifier notifier) {
    final breakdown = state.buildResult!.breakdown;
    if (breakdown.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_outline,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'This place is for your heart',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please describe a sincere need or intention for your dua.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondaryLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    notifier.resetBuild();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final section =
        breakdown[state.buildCurrentSection.clamp(0, breakdown.length - 1)];
    final isLast = state.buildCurrentSection >= breakdown.length - 1;
    final currentStep = state.buildCurrentSection;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: KeyedSubtree(
            key: ValueKey(currentStep),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Gold sparkles
                    Center(
                      child: Row(
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
                                delay: (i * 80).ms,
                              )
                              .fadeIn(duration: 400.ms, delay: (i * 80).ms);
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Gold progress dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final filled = i <= currentStep;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? AppColors.secondary
                                : AppColors.borderLight,
                          ),
                        );
                      }),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: 28),
                    // Section label with gold accent bar
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ).animate().scaleY(
                            begin: 0,
                            end: 1,
                            duration: 300.ms,
                            delay: 200.ms,
                            curve: Curves.easeOut),
                        const SizedBox(width: 8),
                        Text(
                          section.label,
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.primary),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Arabic card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        section.arabic,
                        style: AppTypography.quranArabic
                            .copyWith(color: Colors.white),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(duration: 800.ms, delay: 300.ms).scaleXY(
                        begin: 0.95,
                        end: 1.0,
                        duration: 800.ms,
                        delay: 300.ms,
                        curve: Curves.easeOutBack),
                    const SizedBox(height: 16),
                    // Transliteration
                    Text(
                      section.transliteration,
                      style: AppTypography.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondaryLight,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.dividerLight),
                    const SizedBox(height: 12),
                    // Translation
                    Text(
                      section.translation,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                        height: 1.6,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
                    const SizedBox(height: 24),
                    // Next/Complete button
                    if (isLast)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          notifier.nextBuildSection();
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Ameen',
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 700.ms)
                          .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 500.ms,
                              delay: 700.ms)
                    else
                      _buildActionButtonDua('Next', () {
                        HapticFeedback.mediumImpact();
                        notifier.nextBuildSection();
                      }).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (currentStep > 0)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                notifier.previousBuildSection();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
          ),
      ],
    );
  }

  Widget _buildActionButtonDua(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAmeenScreen(DuasState state, DuasNotifier notifier) {
    final result = state.buildResult!;

    // Auto-save on first render. Built duas are auto-saved into the journal,
    // so the "save" quest fires from related-dua hearts only — not here.
    if (!notifier.isBuiltDuaSaved()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.saveCurrentBuiltDua();
        ref.read(questsProvider.notifier).onBuiltDuaCompleted();
        checkAchievements(ref);
        flushQuestNotifications(ref);
      });
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          children: [
            // Share button top-right
            Align(
              alignment: Alignment.centerRight,
              child: Builder(
                  builder: (btnContext) => GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final box =
                              btnContext.findRenderObject() as RenderBox;
                          final origin =
                              box.localToGlobal(Offset.zero) & box.size;
                          try {
                            await shareBuiltDuaCard(
                              context: context,
                              need: state.buildNeed,
                              sections: duaSectionsForShare(result.breakdown),
                              translation: result.translation,
                              sharePositionOrigin: origin,
                            );
                          } catch (e) {
                            debugPrint('[SHARE ERROR] $e');
                          }
                        },
                        child: Icon(Icons.share_outlined,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 22),
                      )),
            ),
            const SizedBox(height: 8),
            // Pulsing radial gold glow behind آمين + sparkles
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.15),
                        AppColors.secondary.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.9, end: 1.1, duration: 2000.ms),
                Column(
                  children: [
                    // White sparkles
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.auto_awesome,
                          color: Colors.white
                              .withValues(alpha: i == 2 ? 0.9 : 0.5),
                          size: i == 2 ? 20 : 14,
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              curve: Curves.elasticOut,
                              duration: 600.ms,
                              delay: (i * 80).ms,
                            )
                            .fadeIn(duration: 400.ms, delay: (i * 80).ms);
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\u0622\u0645\u064a\u0646',
                      style: AppTypography.nameOfAllahDisplay
                          .copyWith(color: Colors.white, fontSize: 64),
                      textDirection: TextDirection.rtl,
                    ).animate().fadeIn(duration: 800.ms).scaleXY(
                        begin: 0.85,
                        end: 1.0,
                        duration: 800.ms,
                        curve: Curves.easeOutBack),
                    const SizedBox(height: 8),
                    Text(
                      'Ameen',
                      style: AppTypography.displayLarge
                          .copyWith(color: Colors.white),
                    ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                    const SizedBox(height: 8),
                    Text(
                      'May Allah accept your dua',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Build Another Dua
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _buildController.clear();
                notifier.resetBuild();
              },
              child: Container(
                width: double.infinity,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Build Another Dua',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
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
                        'Names Called Upon',
                        style: AppTypography.headlineMedium
                            .copyWith(color: AppColors.textPrimaryLight),
                      ),
                    ],
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
                                Text(n.name, style: AppTypography.labelLarge),
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
            ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
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
                        'Related Duas',
                        style: AppTypography.headlineMedium
                            .copyWith(color: AppColors.textPrimaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save to view full dua in Journal',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.relatedDuas.map((d) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF7F2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: const Border(
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
                                      HapticFeedback.mediumImpact();
                                      final wasSaved =
                                          notifier.isRelatedDuaSaved(d);
                                      notifier.toggleSaveRelatedDua(d);
                                      if (!wasSaved) {
                                        ref
                                            .read(questsProvider.notifier)
                                            .onDuaSaved();
                                        flushQuestNotifications(ref);
                                      }
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
            ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
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
    return Text(
      title,
      style: AppTypography.displayLarge
          .copyWith(color: AppColors.textPrimaryLight),
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
          style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
    );
  }
}
