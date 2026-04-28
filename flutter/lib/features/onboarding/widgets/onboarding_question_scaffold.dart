import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import 'onboarding_continue_button.dart';
import 'onboarding_page_wrapper.dart';

/// Shared scaffold for every quiz screen in the onboarding flow.
/// Headline + optional subtitle + body + Continue button, with
/// Continue disabled until the parent reports `continueEnabled`.
class OnboardingQuestionScaffold extends StatelessWidget {
  const OnboardingQuestionScaffold({
    super.key,
    required this.progressSegment,
    required this.headline,
    required this.body,
    required this.onContinue,
    required this.onBack,
    required this.continueEnabled,
    this.subtitle,
    this.continueLabel,
    this.resizeToAvoidBottomInset = true,
  });

  final int progressSegment;
  final String headline;
  final String? subtitle;
  final Widget body;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final bool continueEnabled;
  final String? continueLabel;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: progressSegment,
      onBack: onBack,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      child: resizeToAvoidBottomInset
          ? LayoutBuilder(
              builder: (context, constraints) => _ScrollableQuestionContent(
                minHeight: constraints.maxHeight,
                headline: headline,
                subtitle: subtitle,
                body: body,
                button: _buildContinueButton(),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        _ScrollableQuestionContent(
                      minHeight: constraints.maxHeight,
                      headline: headline,
                      subtitle: subtitle,
                      body: body,
                      bottomSpacer: 112,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.lg,
                  child: _buildContinueButton(),
                ),
              ],
            ),
    );
  }

  Widget _buildContinueButton() {
    return OnboardingContinueButton(
      label: continueLabel ?? AppStrings.continueButton,
      onPressed: onContinue,
      enabled: continueEnabled,
    );
  }
}

class _ScrollableQuestionContent extends StatelessWidget {
  const _ScrollableQuestionContent({
    required this.minHeight,
    required this.headline,
    required this.body,
    this.subtitle,
    this.button,
    this.bottomSpacer = 0,
  });

  final double minHeight;
  final String headline;
  final String? subtitle;
  final Widget body;
  final Widget? button;
  final double bottomSpacer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              body,
              if (button != null) ...[
                const Spacer(),
                button!,
                const SizedBox(height: AppSpacing.lg),
              ] else
                SizedBox(height: bottomSpacer),
            ],
          ),
        ),
      ),
    );
  }
}
