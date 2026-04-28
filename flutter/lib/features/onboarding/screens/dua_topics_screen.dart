import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';
import '../widgets/struggle_chip.dart';

class DuaTopicsScreen extends ConsumerStatefulWidget {
  const DuaTopicsScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<DuaTopicsScreen> createState() => _DuaTopicsScreenState();
}

class _DuaTopicsScreenState extends ConsumerState<DuaTopicsScreen> {
  static const _topics = <(String, String)>[
    ('health', 'Health'),
    ('family', 'Family'),
    ('forgiveness', 'Forgiveness'),
    ('guidance', 'Guidance'),
    ('peace', 'Peace'),
    ('success', 'Success'),
    ('provision', 'Provision'),
  ];

  late final TextEditingController _otherController;
  late final FocusNode _otherFocusNode;
  final _otherFieldKey = GlobalKey();
  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(
      text: ref.read(onboardingProvider).duaTopicsOther ?? '',
    );
    _otherFocusNode = FocusNode();
    _otherController.addListener(_onOtherChanged);
    _otherFocusNode.addListener(_handleOtherFocusChange);
  }

  void _onOtherChanged() {
    // Rebuild so continueEnabled reflects free-text presence.
    setState(() {});
  }

  void _handleOtherFocusChange() {
    if (_otherFocusNode.hasFocus) {
      _scheduleOtherFieldScroll();
    }
  }

  void _scheduleOtherFieldScroll() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollOtherFieldIntoView());
  }

  void _scrollOtherFieldIntoView() {
    final fieldContext = _otherFieldKey.currentContext;
    if (fieldContext == null) return;

    Scrollable.ensureVisible(
      fieldContext,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void dispose() {
    _otherFocusNode.removeListener(_handleOtherFocusChange);
    _otherController.removeListener(_onOtherChanged);
    _otherFocusNode.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final hasFreeText = _otherController.text.trim().isNotEmpty;
    final canContinue = state.duaTopics.isNotEmpty || hasFreeText;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    if (keyboardInset == 0) {
      _lastKeyboardInset = 0;
    } else if (_otherFocusNode.hasFocus &&
        keyboardInset != _lastKeyboardInset) {
      _lastKeyboardInset = keyboardInset;
      _scheduleOtherFieldScroll();
    }

    return OnboardingQuestionScaffold(
      progressSegment: 8,
      headline: 'What would you most want to dua for?',
      subtitle: 'Pick as many as feel true.',
      onBack: widget.onBack,
      continueEnabled: canContinue,
      resizeToAvoidBottomInset: false,
      onContinue: () {
        ref
            .read(onboardingProvider.notifier)
            .setDuaTopicsOther(_otherController.text);
        final after = ref.read(onboardingProvider);
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswerWithRef(ref, 'dua_topics', after.duaTopics);
        ref.read(analyticsProvider).trackOnboardingAnswerWithRef(
            ref, 'dua_topics_other', after.duaTopicsOther);
        widget.onNext();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _topics
                .map(
                  (t) => StruggleChip(
                    label: t.$2,
                    isSelected: state.duaTopics.contains(t.$1),
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleDuaTopic(t.$1),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            height: 1,
            color: AppColors.dividerLight,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Something else on your heart?',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            key: _otherFieldKey,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: TextField(
              controller: _otherController,
              focusNode: _otherFocusNode,
              maxLength: 280,
              minLines: 1,
              maxLines: 3,
              scrollPadding: const EdgeInsets.only(bottom: AppSpacing.md),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'A quiet intention, a name, a worry…',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                counterText: '',
              ),
            ),
          ),
          if (hasFreeText)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs, right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_otherController.text.characters.length}/280',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
