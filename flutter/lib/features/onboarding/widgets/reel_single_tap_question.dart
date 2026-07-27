import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'onboarding_page_wrapper.dart';
import 'reel_option_card.dart';
import 'reel_question_header.dart';
import 'reel_skip_link.dart';

/// One selectable answer: a stable [key] and the sentence shown for it.
class ReelOption {
  const ReelOption({required this.key, required this.label});

  final String key;
  final String label;
}

/// The reel flow's question surface (One Ship W2-D1/D3) — tap IS the answer.
///
/// The legacy quiz screens select on tap and commit on a Continue button
/// (`OnboardingQuestionScaffold`); the reel flow commits on the tap itself,
/// after a short selected-state beat, the way the hook screen does. Two taps to
/// answer a one-answer question is the friction the reel rebuild removes.
///
/// State lives in the caller: [onCommitted] fires with the chosen key from the
/// tap handler's continuation — never during build — so a Riverpod mutation
/// inside it is safe.
class ReelSingleTapQuestion extends StatefulWidget {
  const ReelSingleTapQuestion({
    required this.headline,
    required this.subline,
    required this.options,
    required this.onCommitted,
    this.onBack,
    this.onSkip,
    this.skipLabel,
    this.initialKey,
    this.progressSegment,
    this.commitBeat = const Duration(milliseconds: 450),
    super.key,
  });

  final String headline;
  final String subline;
  final List<ReelOption> options;

  /// Fired once per commit with [ReelOption.key], after the beat.
  final ValueChanged<String> onCommitted;

  /// Omitted (no affordance rendered) when this is the flow's first page.
  final VoidCallback? onBack;

  /// The quiet decline path. Rendered only when both this and [skipLabel] are
  /// set; advances without committing an answer.
  final VoidCallback? onSkip;
  final String? skipLabel;

  /// Pre-selects an option — how a returning user sees their own answer.
  final String? initialKey;

  /// When set, the screen wears the shared onboarding chrome (back affordance +
  /// progress bar) instead of a bare header. Wave E owns the reel flow's
  /// segment numbering, so it stays null until then.
  final int? progressSegment;

  /// The pause between the selected state and [onCommitted]; zero in tests.
  final Duration commitBeat;

  @override
  State<ReelSingleTapQuestion> createState() => _ReelSingleTapQuestionState();
}

class _ReelSingleTapQuestionState extends State<ReelSingleTapQuestion> {
  String? _selectedKey;
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialKey;
  }

  /// The beat is a held breath, not a spinner: the card shows itself chosen,
  /// then the flow moves. Taps during it are swallowed (one commit per beat);
  /// the guard is released afterwards so a user who navigates back can change
  /// their answer.
  Future<void> _commit(String key) async {
    if (_committing) return;
    setState(() {
      _committing = true;
      _selectedKey = key;
    });
    HapticFeedback.selectionClick();
    await Future<void>.delayed(widget.commitBeat);
    if (!mounted) {
      _committing = false;
      return;
    }
    setState(() => _committing = false);
    widget.onCommitted(key);
  }

  @override
  Widget build(BuildContext context) {
    final segment = widget.progressSegment;
    if (segment != null) {
      // The wrapper brings its own back affordance and the progress bar.
      return OnboardingPageWrapper(
        progressSegment: segment,
        onBack: widget.onBack ?? () {},
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [..._titleBlock(withBack: false), ..._body()],
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [..._titleBlock(withBack: true), ..._body()],
        ),
      ),
    );
  }

  List<Widget> _titleBlock({required bool withBack}) => [
        ReelQuestionHeader(
          headline: widget.headline,
          subline: widget.subline,
          onBack: withBack ? widget.onBack : null,
        ),
        const SizedBox(height: AppSpacing.lg),
      ];

  List<Widget> _body() {
    final children = <Widget>[];
    for (var i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];
      if (i > 0) children.add(const SizedBox(height: 12));
      children.add(
        ReelOptionCard(
          label: option.label,
          selected: _selectedKey == option.key,
          onTap: () => _commit(option.key),
        )
            // The hook screen's 60ms/card stagger, so the questions after it
            // arrive the same way.
            .animate()
            .fadeIn(duration: 300.ms, delay: (120 + i * 60).ms)
            .slideY(
              begin: 0.06,
              end: 0,
              duration: 300.ms,
              delay: (120 + i * 60).ms,
            ),
      );
    }
    final skip = _skipLink();
    if (skip != null) {
      children
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(skip);
    }
    return children;
  }

  Widget? _skipLink() {
    final label = widget.skipLabel;
    final onSkip = widget.onSkip;
    if (label == null || onSkip == null) return null;
    // Disabled mid-beat for the same reason a second card tap is: the commit
    // that is already running owns the navigation.
    return ReelSkipLink(label: label, onTap: _committing ? null : onSkip);
  }
}
