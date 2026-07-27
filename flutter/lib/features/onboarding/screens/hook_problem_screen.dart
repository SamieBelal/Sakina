import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../content/problem_chips.dart';
import '../widgets/hook_free_text_block.dart';
import '../widgets/hook_screen_header.dart';
import '../widgets/problem_chip_card.dart';
import '../widgets/scroll_more_fade.dart';

/// The reel flow's first screen (One Ship W2-B2) — "What's weighing on you
/// right now?" — built to the founder-approved UX spec of 2026-07-25.
///
/// Deliberately NOT a `ConsumerWidget` and NOT wrapped in
/// `OnboardingPageWrapper`: the wrapper always renders the progress bar, and
/// spec ③ bans a step counter here (it signals a long form and manufactures
/// hurry on screen one). State arrives through the constructor; Wave E does the
/// PageView assembly and the provider write inside [onCommitted].
class HookProblemScreen extends StatefulWidget {
  const HookProblemScreen({
    required this.onCommitted,
    this.onBack,
    this.initialChipKey,
    this.resolver,
    this.commitBeat = const Duration(milliseconds: 450),
    super.key,
  });

  static const String headerLabel = "What's weighing on you right now?";
  static const String sublineLabel = 'Take your time.';

  /// Fired once, after the selected-state beat, with everything the tap
  /// promised. Called from the tap handler's continuation — never during
  /// build — so a Riverpod mutation inside it is safe.
  final ValueChanged<ChipSelection> onCommitted;

  /// Omitted (no affordance rendered) when this is the flow's first page.
  final VoidCallback? onBack;

  /// Pre-selects a card — how Wave E's `sakina://feel/<emotion>` link lands.
  final String? initialChipKey;

  final ProblemChipResolver? resolver;

  /// The pause between the selected state and [onCommitted]; zero in tests.
  final Duration commitBeat;

  @override
  State<HookProblemScreen> createState() => _HookProblemScreenState();
}

class _HookProblemScreenState extends State<HookProblemScreen> {
  late final ProblemChipResolver _resolver =
      widget.resolver ?? ProblemChipResolver();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<bool> _moreBelow = ValueNotifier<bool>(false);

  String? _selectedKey;
  bool _committing = false;
  bool _freeTextExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialChipKey;
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    _scroll.dispose();
    _moreBelow.dispose();
    super.dispose();
  }

  Future<void> _commit(Future<ChipSelection> resolving, String? key) async {
    // Double-tap guard: the first tap owns the beat, later taps are ignored.
    if (_committing) return;
    setState(() {
      _committing = true;
      _selectedKey = key;
    });
    HapticFeedback.selectionClick();
    await Future<void>.delayed(widget.commitBeat);
    final selection = await resolving;
    if (!mounted) return;
    widget.onCommitted(selection);
  }

  void _openFreeText() {
    setState(() => _freeTextExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _textFocus.requestFocus();
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  bool _trackExtentAfter(Notification n) {
    if (n is ScrollMetricsNotification) {
      _moreBelow.value = n.metrics.extentAfter > 4;
    } else if (n is ScrollUpdateNotification) {
      _moreBelow.value = n.metrics.extentAfter > 4;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            NotificationListener<Notification>(
              onNotification: _trackExtentAfter,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  HookScreenHeader(
                    title: HookProblemScreen.headerLabel,
                    subline: HookProblemScreen.sublineLabel,
                    onBack: widget.onBack,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._cards(),
                  const SizedBox(height: AppSpacing.md - 2),
                  HookFreeTextBlock(
                    expanded: _freeTextExpanded,
                    controller: _textController,
                    focusNode: _textFocus,
                    enabled: !_committing,
                    onExpand: _openFreeText,
                    onSubmit: (text) {
                      if (text.trim().isEmpty) return;
                      _commit(_resolver.forFreeText(text), null);
                    },
                  ).animate().fadeIn(duration: 450.ms, delay: 650.ms),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ScrollMoreFade(visible: _moreBelow),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _cards() {
    final cards = <Widget>[];
    for (var i = 0; i < problemChips.length; i++) {
      final chip = problemChips[i];
      if (i > 0) cards.add(const SizedBox(height: 12));
      cards.add(
        ProblemChipCard(
          chip: chip,
          selected: _selectedKey == chip.chipKey,
          onTap: () => _commit(_resolver.forChip(chip.chipKey), chip.chipKey),
        )
            // Same 60ms/card stagger the shipped hook screen uses.
            .animate()
            .fadeIn(duration: 300.ms, delay: (150 + i * 60).ms)
            .slideY(
              begin: 0.06,
              end: 0,
              duration: 300.ms,
              delay: (150 + i * 60).ms,
            ),
      );
    }
    return cards;
  }
}
