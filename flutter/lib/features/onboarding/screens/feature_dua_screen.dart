import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';

import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

enum _DemoPhase { input, loading, result }

class FeatureDuaScreen extends StatefulWidget {
  const FeatureDuaScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<FeatureDuaScreen> createState() => _FeatureDuaScreenState();
}

class _FeatureDuaScreenState extends State<FeatureDuaScreen> {
  static const _fullText = "I'm feeling overwhelmed and need peace...";
  static const _typeInterval = Duration(milliseconds: 80);
  static const _cursorInterval = Duration(milliseconds: 500);

  static const _sections = [
    (
      label: 'Praise',
      arabic: 'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ',
      translit: 'Subhānakallāhumma wa bihamdik',
      translation: 'Glory be to You, O Allah, and all praise is Yours.',
      step: 0,
    ),
    (
      label: 'Salawāt',
      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
      translit: 'Allāhumma ṣalli ʿalā Muḥammad',
      translation: 'O Allah, send blessings upon Muhammad.',
      step: 1,
    ),
    (
      label: 'Your Ask',
      arabic: 'يَا رَبِّ ارْزُقْنِي السَّكِينَةَ',
      translit: 'Yā Rabbi, urzuqnī al-sakīnah',
      translation: 'O my Lord, grant me tranquility.',
      step: 2,
    ),
    (
      label: 'Closing',
      arabic: 'سُبْحَانَ رَبِّكَ رَبِّ الْعِزَّةِ',
      translit: 'Subhāna Rabbika Rabbi al-ʿizzah',
      translation: 'Glory be to your Lord, the Lord of honour.',
      step: 3,
    ),
  ];

  _DemoPhase _phase = _DemoPhase.input;
  String _typedText = '';
  bool _showCursor = true;
  double _loadingProgress = 0.0;
  int _resultIndex = 0;

  Timer? _typeTimer;
  Timer? _cursorTimer;
  Timer? _loadingTimer;
  Timer? _phaseTimer;

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
    setState(() {
      _phase = _DemoPhase.loading;
      _loadingProgress = 0.0;
    });
    const tickInterval = Duration(milliseconds: 30);
    const totalTicks = 60; // ~1.8s
    var tick = 0;
    _loadingTimer = Timer.periodic(tickInterval, (timer) {
      if (!mounted) { timer.cancel(); return; }
      tick++;
      setState(() => _loadingProgress = (tick / totalTicks).clamp(0.0, 1.0));
      if (tick >= totalTicks) {
        timer.cancel();
        _phaseTimer = Timer(const Duration(milliseconds: 300), () => _showResult(0));
      }
    });
  }

  void _showResult(int index) {
    if (!mounted) return;
    setState(() {
      _phase = _DemoPhase.result;
      _resultIndex = index;
    });
    // Show each section for 2.5s, then advance or loop
    _phaseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (index < _sections.length - 1) {
        _showResult(index + 1);
      } else {
        _resetToInput();
      }
    });
  }

  void _resetToInput() {
    if (!mounted) return;
    setState(() {
      _phase = _DemoPhase.input;
      _typedText = '';
      _loadingProgress = 0.0;
    });
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

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 3,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: switch (_phase) {
                  _DemoPhase.input => _buildInputMock(),
                  _DemoPhase.loading => _buildLoadingMock(),
                  _DemoPhase.result => _buildResultMock(),
                },
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
                  AppStrings.featureDuaHeadlinePostLoop,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.featureDuaSubtitlePostLoop,
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

  static const _loadingSteps = [
    (threshold: 0.0, label: 'Praise'),
    (threshold: 0.25, label: 'Salawat'),
    (threshold: 0.50, label: 'Your ask'),
    (threshold: 0.75, label: 'Closing'),
  ];

  Widget _buildLoadingMock() {
    final percentage = (_loadingProgress * 100).toInt();
    return Column(
      key: const ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gold sparkles
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            return Icon(
              Icons.auto_awesome,
              color: AppColors.secondary.withAlpha(i == 2 ? 255 : 153),
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
        const SizedBox(height: AppSpacing.sm),
        // Percentage
        Text(
          '$percentage%',
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Crafting your dua\u2026',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Progress bar
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
        // Step indicators
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

  Widget _buildInputMock() {
    final typed = _typedText;
    final isReady = typed.length == _fullText.length;

    return Column(
      key: const ValueKey('input'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _stepPill('1', 'Praise', 0),
            _goldLine(),
            _stepPill('2', 'Salawāt', 1),
            _goldLine(),
            _stepPill('3', 'Ask', 2),
            _goldLine(),
            _stepPill('4', 'Close', 3),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
                'What do you need a dua for?',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
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
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(76),
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
        ).animate().fadeIn(duration: 500.ms, delay: 450.ms),
      ],
    );
  }

  Widget _buildResultMock() {
    final section = _sections[_resultIndex];
    return Column(
      key: ValueKey('result-${section.step}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gold sparkles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.secondary.withAlpha(i == 2 ? 255 : 153),
                size: i == 2 ? 20 : 13,
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                    delay: (i * 80).ms,
                  )
                  .fadeIn(duration: 400.ms, delay: (i * 80).ms),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Gold progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i <= section.step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.secondary : AppColors.borderLight,
              ),
            );
          }),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        const SizedBox(height: AppSpacing.md),
        // Section label
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              section.label,
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        const SizedBox(height: AppSpacing.sm),
        // Arabic card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(76),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            section.arabic,
            style: AppTypography.quranArabic.copyWith(color: Colors.white, fontSize: 20),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        )
            .animate()
            .fadeIn(duration: 700.ms, delay: 300.ms)
            .scaleXY(
              begin: 0.95, end: 1.0, duration: 700.ms, delay: 300.ms,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          section.translit,
          style: AppTypography.bodySmall.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondaryLight,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
        const SizedBox(height: AppSpacing.xs),
        Text(
          section.translation,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
      ],
    );
  }

  Widget _stepPill(String number, String label, int index) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withAlpha(100)),
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
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (200 + index * 80).ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (200 + index * 80).ms);
  }

  Widget _goldLine() {
    return Container(
      width: 16,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.secondary.withAlpha(60),
    );
  }
}
