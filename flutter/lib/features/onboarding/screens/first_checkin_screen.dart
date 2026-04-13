import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/keyboard.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/demo_result_card.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';
import '../../daily/widgets/name_reveal_overlay.dart';

class FirstCheckinScreen extends ConsumerStatefulWidget {
  const FirstCheckinScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<FirstCheckinScreen> createState() => _FirstCheckinScreenState();
}

class _FirstCheckinScreenState extends ConsumerState<FirstCheckinScreen> {
  late final TextEditingController _controller;
  final _scrollController = ScrollController();
  final _textFieldKey = GlobalKey();
  bool _hasShownReveal = false;

  static const _chips = [
    AppStrings.chipAnxious,
    AppStrings.chipSad,
    AppStrings.chipGrateful,
    AppStrings.chipFrustrated,
    AppStrings.chipLost,
    AppStrings.chipHopeful,
  ];

  @override
  void initState() {
    super.initState();
    final initial = ref.read(onboardingProvider).demoFeelingInput ?? '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      behavior: HitTestBehavior.translucent,
      child: OnboardingPageWrapper(
        progressSegment: 14,
        onBack: () {
          dismissKeyboard(context);
          widget.onBack();
        },
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: state.isLoadingDemoResult
            ? _buildLoading()
            : state.demoCheckinCompleted
                ? _buildResult(state, notifier)
                : _buildInput(state, notifier),
        ),
      ),
    );
  }

  Widget _buildInput(OnboardingState state, OnboardingNotifier notifier) {
    final hasInput =
        state.demoFeelingInput != null && state.demoFeelingInput!.isNotEmpty;
    final currentInput = state.demoFeelingInput ?? '';

    return LayoutBuilder(
      key: const ValueKey('input'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppStrings.checkinTitle,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.left,
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.05, end: 0, duration: 500.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.checkinSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.left,
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: SvgPicture.asset(
                    'assets/illustrations/onboarding_checkin.svg',
                    height: (MediaQuery.sizeOf(context).height * 0.19)
                        .clamp(120, 180),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideY(
                        begin: 0.05, end: 0, duration: 600.ms, delay: 300.ms),
                const SizedBox(height: AppSpacing.lg),
                _FocusAwareTextField(
                  key: _textFieldKey,
                  controller: _controller,
                  onChanged: (value) => notifier.setDemoFeelingInput(value),
                  onFocused: () {
                    // Delay to let the keyboard animate in
                    Future.delayed(const Duration(milliseconds: 400), () {
                      final ctx = _textFieldKey.currentContext;
                      if (ctx != null) {
                        Scrollable.ensureVisible(
                          ctx,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          alignmentPolicy:
                              ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                        );
                      }
                    });
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideY(
                        begin: 0.02, end: 0, duration: 400.ms, delay: 500.ms),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _chips.asMap().entries.map((entry) {
                    final index = entry.key;
                    final chip = entry.value;
                    final isSelected =
                        currentInput.isNotEmpty && currentInput == chip;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _controller.text = chip;
                        notifier.setDemoFeelingInput(chip);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.surfaceAltLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          chip,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(
                        duration: 300.ms, delay: (600 + index * 60).ms);
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                OnboardingContinueButton(
                  label: AppStrings.checkinReflectButton,
                  onPressed: () => notifier.completeDemoCheckin(),
                  enabled: hasInput,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Three pulsing dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 600.ms, delay: (i * 200).ms)
                  .then()
                  .fadeOut(duration: 600.ms);
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Decorative Arabic text at low opacity
          Opacity(
            opacity: 0.75,
            child: Text(
              '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650',
              style: AppTypography.nameOfAllahDisplay.copyWith(
                color: AppColors.secondary,
                fontSize: 36,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.checkinLoadingTitle,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.checkinLoadingSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showRevealOverlay(DemoResultData data) {
    if (_hasShownReveal) return;
    _hasShownReveal = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigator.push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => NameRevealOverlay(
            nameArabic: data.nameArabic,
            nameEnglish: data.nameTransliteration,
            nameEnglishMeaning: data.nameEnglish,
            teaching: data.verseTranslation,
            card: null,
            engageResult: null,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  Widget _buildResult(OnboardingState state, OnboardingNotifier notifier) {
    final data = DemoResultData.forEmotion(state.demoFeelingInput ?? '');
    _showRevealOverlay(data);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.mediumImpact();
    });
    return SingleChildScrollView(
      key: const ValueKey('result'),
      child: Column(
        children: [
          Text(
            AppStrings.checkinResultLabel,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DemoResultCard(
            data: data,
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.05, end: 0, duration: 600.ms),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Icon(
                Icons.auto_awesome,
                size: 16 + (i == 2 ? 8 : 0),
                color: AppColors.secondary.withAlpha(180 + (i == 2 ? 75 : 0)),
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
          Text(
            AppStrings.checkinResultFooter,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.checkinResultUnlockCopy,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: widget.onNext,
          ),
        ],
      ),
    );
  }
}

class _FocusAwareTextField extends StatefulWidget {
  const _FocusAwareTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFocused,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFocused;

  @override
  State<_FocusAwareTextField> createState() => _FocusAwareTextFieldState();
}

class _FocusAwareTextFieldState extends State<_FocusAwareTextField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _hasFocus = focused);
        if (focused) {
          widget.onFocused?.call();
        }
      },
      child: TextField(
        controller: widget.controller,
        maxLines: 3,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: AppStrings.typeYourFeeling,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          filled: true,
          fillColor:
              _hasFocus ? AppColors.primaryLight : AppColors.surfaceLight,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
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
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
