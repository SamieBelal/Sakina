import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class DailyCommitmentScreen extends ConsumerStatefulWidget {
  const DailyCommitmentScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<DailyCommitmentScreen> createState() =>
      _DailyCommitmentScreenState();
}

class _DailyCommitmentScreenState extends ConsumerState<DailyCommitmentScreen> {
  static const _presets = [1, 3, 5, 10];

  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocus = FocusNode();
  bool _customMode = false;
  bool _customValid = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingProvider).dailyCommitmentMinutes;
    if (existing != null && !_presets.contains(existing)) {
      _customMode = true;
      _customValid = true;
      _customController.text = '$existing';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _customFocus.dispose();
    super.dispose();
  }

  void _selectPreset(int m) {
    setState(() {
      _customMode = false;
      _customValid = false;
    });
    _customController.clear();
    ref.read(onboardingProvider.notifier).setDailyCommitmentMinutes(m);
  }

  void _enterCustom() {
    setState(() {
      _customMode = true;
      _customValid = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customFocus.requestFocus();
    });
  }

  void _onCustomChanged(String raw) {
    final parsed = int.tryParse(raw.trim());
    final valid = parsed != null && parsed > 0 && parsed <= 120;
    setState(() => _customValid = valid);
    if (valid) {
      ref.read(onboardingProvider.notifier).setDailyCommitmentMinutes(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final selected = state.dailyCommitmentMinutes;
    final canContinue = _customMode
        ? _customValid
        : selected != null && _presets.contains(selected);

    return Stack(
      children: [
        OnboardingQuestionScaffold(
          progressSegment: 11,
          headline: 'How much time a day feels right?',
          subtitle: 'You can change this later.',
          onBack: widget.onBack,
          continueEnabled: canContinue,
          onContinue: () {
            FocusManager.instance.primaryFocus?.unfocus();
            ref.read(analyticsProvider).trackOnboardingAnswerWithRef(
                  ref,
                  'daily_commitment_minutes',
                  selected,
                );
            widget.onNext();
          },
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final m in _presets) ...[
                _PresetTile(
                  minutes: m,
                  selected: !_customMode && selected == m,
                  onTap: () => _selectPreset(m),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _CustomTile(
                active: _customMode,
                controller: _customController,
                focusNode: _customFocus,
                onActivate: _enterCustom,
                onChanged: _onCustomChanged,
              ),
            ],
          ),
        ),
        _KeyboardDoneBar(focusNode: _customFocus),
      ],
    );
  }
}

class _KeyboardDoneBar extends StatefulWidget {
  const _KeyboardDoneBar({required this.focusNode});
  final FocusNode focusNode;

  @override
  State<_KeyboardDoneBar> createState() => _KeyboardDoneBarState();
}

class _KeyboardDoneBarState extends State<_KeyboardDoneBar> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    if (!widget.focusNode.hasFocus || viewInsets <= 0) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: viewInsets,
      child: Material(
        color: const Color(0xFFD1D4DB),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Text(
                'Done',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$minutes min',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}

class _CustomTile extends StatelessWidget {
  const _CustomTile({
    required this.active,
    required this.controller,
    required this.focusNode,
    required this.onActivate,
    required this.onChanged,
  });

  final bool active;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onActivate;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active ? null : onActivate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderLight,
            width: active ? 1.5 : 1,
          ),
        ),
        child: active
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                      decoration: const InputDecoration(
                        hintText: '—',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                  Text(
                    ' min',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Custom',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
