import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import 'intake_chip.dart';

/// A chip in an [IntakeChipCloud]: a stable key and the word shown for it.
class IntakeChipData {
  const IntakeChipData({required this.key, required this.label});

  final String key;
  final String label;
}

/// The wrapping, capped multi-select cloud behind H5 (One Ship W2-H, spec §5).
///
/// Seven full-width multi-select rows would have reintroduced the exact "seven
/// stacked rectangles" failure the hook screen was redesigned on 2026-07-27 to
/// escape. A cloud keeps every option visible at a glance and reads materially
/// lighter than a stack — and the [maxSelections] cap is the design, not a
/// guard: the cognitive-load literature puts the mitigations at *categorisation
/// and constraint*, not at fewer options.
///
/// State lives in the caller. [onToggle] fires from the tap handler — never
/// during build — so a Riverpod mutation inside it is safe, and the caller is
/// free to refuse a tap (which is what the cap does).
///
/// The chips arrive on the hook screen's stagger rather than appearing as a
/// wall, and [MediaQuery.disableAnimations] flattens the travel to a plain fade.
class IntakeChipCloud extends StatelessWidget {
  const IntakeChipCloud({
    required this.chips,
    required this.selectedKeys,
    required this.onToggle,
    required this.maxSelections,
    super.key,
  });

  final List<IntakeChipData> chips;

  /// Ordered — the H5 blend weights by selection order, so the caller keeps a
  /// list rather than a set and this widget never reorders it.
  final List<String> selectedKeys;

  final ValueChanged<String> onToggle;

  /// At this many held chips the unselected ones dim and stop responding.
  final int maxSelections;

  @override
  Widget build(BuildContext context) {
    final atCap = selectedKeys.length >= maxSelections;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Wrap(
      spacing: AppSpacing.sm + 2,
      runSpacing: AppSpacing.sm + 2,
      children: [
        for (var i = 0; i < chips.length; i++)
          Builder(
            builder: (_) {
              final chip = chips[i];
              final selected = selectedKeys.contains(chip.key);
              return IntakeChip(
                label: chip.label,
                selected: selected,
                dimmed: atCap && !selected,
                onTap: () => onToggle(chip.key),
              )
                  .animate(delay: AppMotion.listStart + AppMotion.stagger * i)
                  .fadeIn(duration: AppMotion.item, curve: AppMotion.enter)
                  .moveY(
                    begin: reduceMotion ? 0 : AppMotion.riseSmall,
                    end: 0,
                    duration: AppMotion.item,
                    curve: AppMotion.enter,
                  );
            },
          ),
      ],
    );
  }
}
