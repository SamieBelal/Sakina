import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'onboarding_continue_button.dart';
import 'onboarding_page_wrapper.dart';
import 'reel_question_header.dart';
import 'reel_skip_link.dart';

/// The reel flow's question surface for answers a tap cannot finish (One Ship
/// W2-H).
///
/// [ReelSingleTapQuestion] commits on the tap itself, because two taps to answer
/// a one-answer question is friction. Wave H adds two questions where the tap
/// genuinely is not the answer — H5 holds up to three chips, H7 is typed — so
/// they need a Continue. Everything else is shared with the single-tap surface:
/// the same header, the same wrapper-or-bare-Scaffold branch on
/// [progressSegment], the same quiet skip link.
///
/// Only the action stays pinned. Header and body scroll together, so at the
/// accessibility text scales the content is reachable instead of being squeezed
/// into whatever the fixed chrome left over — the same call
/// `QueuePlanScreen` made.
class ReelContinueQuestion extends StatefulWidget {
  const ReelContinueQuestion({
    required this.headline,
    required this.subline,
    required this.body,
    required this.continueLabel,
    required this.onContinue,
    this.onBack,
    this.onSkip,
    this.skipLabel,
    this.progressSegment,
    this.totalSegments,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final String headline;
  final String subline;

  /// The answer surface itself — a chip cloud, a text field.
  final Widget body;

  final String continueLabel;

  /// Null renders the button in its disabled state (H5 gates it at one
  /// selection). Disabled rather than absent: a button that appears on the first
  /// tap moves the thing the user is about to press.
  final VoidCallback? onContinue;

  /// Omitted (no affordance rendered) when the flow cannot go back from here.
  final VoidCallback? onBack;

  /// The quiet decline path. Rendered only when both this and [skipLabel] are
  /// set; advances without committing an answer.
  final VoidCallback? onSkip;
  final String? skipLabel;

  /// When set, the screen wears the shared onboarding chrome (back affordance +
  /// progress bar) instead of a bare header.
  final int? progressSegment;

  /// Length of that bar; null keeps the wrapper's default.
  final int? totalSegments;

  /// False on a screen whose keyboard should not resize the body.
  final bool resizeToAvoidBottomInset;

  @override
  State<ReelContinueQuestion> createState() => _ReelContinueQuestionState();
}

class _ReelContinueQuestionState extends State<ReelContinueQuestion> {
  /// Held from the first commit until a rebuild after it has been handed off.
  /// While set, Continue AND the skip link do nothing.
  ///
  /// W6 Wave F review, P1. Wave F put an analytics emit inside these callbacks,
  /// and this widget had no re-entry guard while its sibling
  /// `ReelSingleTapQuestion` has had one since it was written. The window is
  /// invisible to the user and not to Mixpanel: the first tap emits and starts
  /// a 300ms page transition, during which the outgoing page's button is still
  /// live; a second tap re-enters the same closure and emits a duplicate
  /// answer. `_goToPage`'s own `_navigating` flag stops the NAVIGATION, so
  /// nothing looks wrong — but it sits downstream of the emit and never
  /// protected it.
  ///
  /// The guard covers the skip link too: a Continue-then-Skip double tap would
  /// otherwise record the answer AND the decline for one visit, which are two
  /// mutually exclusive facts about the same user.
  bool _committing = false;

  /// The commit has run, so the next rebuild may release the guard.
  bool _committed = false;

  @override
  void didUpdateWidget(covariant ReelContinueQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Release point, mirroring ReelSingleTapQuestion. It must be a rebuild
    // AFTER the commit rather than the commit itself: this screen stays mounted
    // inside the PageView, so a guard that never lifted would silently swallow
    // the answer of anyone who navigated back to change it.
    if (_committed) {
      _committing = false;
      _committed = false;
    }
  }

  void _runOnce(VoidCallback? action) {
    if (action == null || _committing) return;
    _committing = true;
    _committed = true;
    action();
  }

  @override
  Widget build(BuildContext context) {
    final segment = widget.progressSegment;
    if (segment != null) {
      return OnboardingPageWrapper(
        progressSegment: segment,
        totalSegments: widget.totalSegments,
        showBack: widget.onBack != null,
        onBack: widget.onBack ?? () {},
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        contentTopPadding: AppSpacing.xl,
        child: _column(withBack: false),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: _column(withBack: true),
        ),
      ),
    );
  }

  Widget _column({required bool withBack}) {
    final skip = _skipLink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReelQuestionHeader(
                  headline: widget.headline,
                  subline: widget.subline,
                  onBack: withBack ? widget.onBack : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                widget.body,
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OnboardingContinueButton(
          label: widget.continueLabel,
          onPressed: () => _runOnce(widget.onContinue),
          enabled: widget.onContinue != null,
        ),
        if (skip != null) skip,
      ],
    );
  }

  Widget? _skipLink() {
    final label = widget.skipLabel;
    final skip = widget.onSkip;
    if (label == null || skip == null) return null;
    // Through the guard too: a Continue-then-Skip double tap would otherwise
    // record the answer AND the decline for a single visit.
    return ReelSkipLink(label: label, onTap: () => _runOnce(skip));
  }
}
