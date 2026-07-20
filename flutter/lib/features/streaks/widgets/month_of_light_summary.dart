import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/streaks/providers/month_of_light_provider.dart';
import 'package:sakina/features/streaks/widgets/month_of_light.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';

/// The collapsed one-line "month of light" summary for the Home hero (T3 / S3).
///
/// Zero history this month → "Your month begins today ›" (never a wall of empty
/// cells). Otherwise "{N} days lit this month ›". Tapping opens the full grid in
/// a bottom sheet. Loading/error degrade gracefully via `.valueOrNull` — the row
/// shows "begins today" rather than crashing (mirrors pendingFreezeBurnProvider).
class MonthOfLightSummary extends ConsumerWidget {
  const MonthOfLightSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(monthOfLightProvider).valueOrNull;
    final litCount = data?.litCount ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final label = litCount == 0
        ? 'Your month begins today'
        : '$litCount ${litCount == 1 ? 'day' : 'days'} lit this month';

    final semanticLabel = litCount == 0
        ? 'Your month begins today, opens calendar'
        : '$litCount days lit this month, opens calendar';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: () {
          ref
              .read(analyticsProvider)
              .track(AnalyticsEvents.chainCalendarExpanded);
          showMonthOfLightSheet(context);
        },
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
