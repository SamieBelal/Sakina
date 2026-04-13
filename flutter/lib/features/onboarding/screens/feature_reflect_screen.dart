import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

enum _ReflectPhase { input, loading, name, reflection, story, dua }

class FeatureReflectScreen extends StatefulWidget {
  const FeatureReflectScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<FeatureReflectScreen> createState() => _FeatureReflectScreenState();
}

class _FeatureReflectScreenState extends State<FeatureReflectScreen> {
  static const _fullText = "I've been feeling anxious lately...";
  static const _typeInterval = Duration(milliseconds: 80);
  static const _cursorInterval = Duration(milliseconds: 500);

  _ReflectPhase _phase = _ReflectPhase.input;
  String _typedText = '';
  bool _showCursor = true;
  double _loadingProgress = 0.0;

  Timer? _typeTimer;
  Timer? _cursorTimer;
  Timer? _loadingTimer;
  Timer? _phaseTimer;

  static const _loadingSteps = [
    (threshold: 0.0, label: 'Reading'),
    (threshold: 0.33, label: 'Connecting'),
    (threshold: 0.66, label: 'Crafting'),
  ];

  @override
  void initState() {
    super.initState();
    _startCursor();
    _startTyping();
  }

  void _startCursor() {
    _cursorTimer = Timer.periodic(_cursorInterval, (_) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });
  }

  void _startTyping() {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      var index = 0;
      _typeTimer = Timer.periodic(_typeInterval, (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (index < _fullText.length) {
          setState(() => _typedText = _fullText.substring(0, ++index));
        } else {
          timer.cancel();
          _phaseTimer = Timer(const Duration(milliseconds: 700), _startLoading);
        }
      });
    });
  }

  void _startLoading() {
    if (!mounted) return;
    setState(() { _phase = _ReflectPhase.loading; _loadingProgress = 0.0; });
    const tickInterval = Duration(milliseconds: 30);
    const totalTicks = 60;
    var tick = 0;
    _loadingTimer = Timer.periodic(tickInterval, (timer) {
      if (!mounted) { timer.cancel(); return; }
      tick++;
      setState(() => _loadingProgress = (tick / totalTicks).clamp(0.0, 1.0));
      if (tick >= totalTicks) {
        timer.cancel();
        _phaseTimer = Timer(const Duration(milliseconds: 300),
            () => _advanceTo(_ReflectPhase.name));
      }
    });
  }

  void _advanceTo(_ReflectPhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
    final next = switch (phase) {
      _ReflectPhase.name => _ReflectPhase.reflection,
      _ReflectPhase.reflection => _ReflectPhase.story,
      _ReflectPhase.story => _ReflectPhase.dua,
      _ReflectPhase.dua => null,
      _ => null,
    };
    if (next != null) {
      _phaseTimer = Timer(const Duration(milliseconds: 2500), () => _advanceTo(next));
    } else {
      // Loop back to input
      _phaseTimer = Timer(const Duration(milliseconds: 2500), _resetToInput);
    }
  }

  void _resetToInput() {
    if (!mounted) return;
    setState(() { _phase = _ReflectPhase.input; _typedText = ''; _loadingProgress = 0.0; });
    _startTyping();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    _loadingTimer?.cancel();
    _phaseTimer?.cancel();
    super.dispose();
  }

  int get _dotIndex => switch (_phase) {
    _ReflectPhase.input => 0,
    _ReflectPhase.loading => 1,
    _ReflectPhase.name => 2,
    _ReflectPhase.reflection => 3,
    _ReflectPhase.story => 4,
    _ReflectPhase.dua => 5,
  };

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 2,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: switch (_phase) {
                      _ReflectPhase.input => _buildInputMock(),
                      _ReflectPhase.loading => _buildLoadingMock(),
                      _ReflectPhase.name => _buildNameCard(),
                      _ReflectPhase.reflection => _buildReflectionCard(),
                      _ReflectPhase.story => _buildStoryCard(),
                      _ReflectPhase.dua => _buildDuaCard(),
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Phase dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final active = i == _dotIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: active ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.featureReflectHeadline,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.featureReflectSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                const Spacer(),
                OnboardingContinueButton(
                  label: AppStrings.continueButton,
                  onPressed: widget.onNext,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------
  Widget _buildInputMock() {
    final typed = _typedText;
    final isReady = typed.length == _fullText.length;
    return Column(
      key: const ValueKey('input'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'How are you feeling?',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: typed.isEmpty ? AppColors.surfaceLight : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: typed.isEmpty ? AppColors.borderLight : AppColors.primary,
              width: typed.isEmpty ? 1.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$typed${_showCursor ? '|' : ' '}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
        const SizedBox(height: AppSpacing.md),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: isReady ? 1.0 : 0.35,
          child: Container(
            width: double.infinity,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(100),
              boxShadow: isReady
                  ? [BoxShadow(color: AppColors.primary.withAlpha(76), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Text(
              'Reflect',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 450.ms),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------
  Widget _buildLoadingMock() {
    final percentage = (_loadingProgress * 100).toInt();
    return Column(
      key: const ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            return Icon(
              Icons.auto_awesome,
              color: AppColors.secondary.withAlpha(i == 2 ? 255 : 153),
              size: i == 2 ? 20 : 14,
            )
                .animate()
                .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms, delay: (i * 80).ms)
                .fadeIn(duration: 400.ms, delay: (i * 80).ms);
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$percentage%',
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Finding your Name…',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _loadingProgress,
            minHeight: 6,
            backgroundColor: AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_loadingSteps.length, (i) {
            final step = _loadingSteps[i];
            final isActive = _loadingProgress >= step.threshold;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.primaryLight : AppColors.surfaceLight,
                  ),
                  child: Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: isActive ? AppColors.primary : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isActive ? AppColors.textPrimaryLight : AppColors.textTertiaryLight,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 11,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: (i * 100).ms);
          }),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // ---------------------------------------------------------------------------
  // Name of Allah
  // ---------------------------------------------------------------------------
  Widget _buildNameCard() {
    return Container(
      key: const ValueKey('name'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'A Name for your heart',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withAlpha(180),
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ٱلسَّلَامُ',
            style: AppTypography.arabicClassical.copyWith(
              fontSize: 38,
              color: Colors.white,
            ),
            textDirection: TextDirection.rtl,
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .scaleXY(begin: 0.9, end: 1.0, duration: 600.ms, delay: 200.ms, curve: Curves.easeOut),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'As-Salām',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
          Text(
            'The Source of Peace',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withAlpha(180),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 420.ms),
          const SizedBox(height: AppSpacing.md),
          // Related names chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: ['Ar-Raḥīm', 'Al-Wadūd', 'Al-Laṭīf'].map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(60)),
                ),
                child: Text(
                  name,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scaleXY(begin: 0.96, end: 1.0, duration: 600.ms, curve: Curves.easeOut);
  }

  // ---------------------------------------------------------------------------
  // Reflection
  // ---------------------------------------------------------------------------
  Widget _buildReflectionCard() {
    return Container(
      key: const ValueKey('reflection'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              ).animate().scaleY(begin: 0, end: 1, duration: 300.ms, delay: 100.ms, curve: Curves.easeOut),
              const SizedBox(width: 8),
              Text(
                'Reflection',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"Your anxiety is a sign that you care deeply. As-Salām reminds us that peace is not the absence of difficulty — it is the presence of Allah."',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0, duration: 600.ms);
  }

  // ---------------------------------------------------------------------------
  // Story
  // ---------------------------------------------------------------------------
  Widget _buildStoryCard() {
    return Container(
      key: const ValueKey('story'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              ).animate().scaleY(begin: 0, end: 1, duration: 300.ms, delay: 100.ms, curve: Curves.easeOut),
              const SizedBox(width: 8),
              Text(
                'A Prophetic Story',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The Prophet ﷺ used to say after every prayer: "Allāhumma anta s-salāmu wa minka s-salām." He taught us that peace is not something we find — it is Someone we return to.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.6,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0, duration: 600.ms);
  }

  // ---------------------------------------------------------------------------
  // Dua
  // ---------------------------------------------------------------------------
  Widget _buildDuaCard() {
    return Container(
      key: const ValueKey('dua'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.secondary.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withAlpha(30), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)),
              ).animate().scaleY(begin: 0, end: 1, duration: 300.ms, delay: 100.ms, curve: Curves.easeOut),
              const SizedBox(width: 8),
              Text(
                'Dua',
                style: AppTypography.labelMedium.copyWith(color: AppColors.secondary),
              ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ',
            style: AppTypography.quranArabic.copyWith(
              color: AppColors.textPrimaryLight,
              fontSize: 20,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms, delay: 250.ms),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Allāhumma anta s-salāmu wa minka s-salām',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'O Allah, You are Peace and from You comes peace.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0, duration: 600.ms);
  }
}
