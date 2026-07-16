import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/adjusted_arabic_display.dart';
import '../models/dua_window.dart';
import '../models/dua_window_type.dart';
import '../providers/dua_window_provider.dart';
import 'dua_times_copy.dart';

/// The visual body of the duʿā-times card (spec §8/§9.1), on the emerald sacred
/// canvas. Pure presentation — all state resolution + analytics live in
/// `DuaTimesCard`. Split out so the stateful card stays lean (<200 lines each).
///
/// Layout: a small crescent + `دُعَاء` Arabic accent hero on the left, the verb
/// + why + cue/countdown + gold CTA pill on the right. Under 15m the accent
/// switches to amber (the same amber as the streak at-risk state).
class DuaTimesCardBody extends StatelessWidget {
  const DuaTimesCardBody({
    required this.state,
    required this.onTap,
    required this.onCta,
    this.onEnablePrecise,
    this.onDismissPrecise,
    super.key,
  });

  final DuaWindowState state;
  final VoidCallback onTap;
  final VoidCallback onCta;

  /// Non-null only when location is absent and we can nudge for precise times.
  final VoidCallback? onEnablePrecise;

  /// Non-null alongside [onEnablePrecise] — the banner's ✕ (7-day snooze).
  final VoidCallback? onDismissPrecise;

  bool get _isLastCall => state.urgency == UrgencyState.lastCall;
  bool get _isBetween => state.active == null;

  /// The accent colour: amber for last-call, gold otherwise. Gold is a non-text
  /// accent on this canvas (WCAG note in app_colors) — used for the crescent +
  /// CTA fill only, never body text.
  Color get _accent =>
      _isLastCall ? AppColors.streakAmber : AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    final active = state.active;
    final next = state.next;

    final verb = _isBetween
        ? DuaTimesCopy.betweenVerb
        : DuaTimesCopy.activeVerb(lastCall: _isLastCall);
    final kicker = _isLastCall
        ? DuaTimesCopy.beforeItClosesKicker
        : (_isBetween
            ? DuaTimesCopy.comingUpKicker
            : DuaTimesCopy.bebelovedTimeKicker);
    final why = _whyLine(active, next);
    final cue = _cueLine(active, next);

    return Semantics(
      button: true,
      label: '$verb. $cue',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppColors.sacredCanvasGradient,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: _accent.withValues(alpha: _isLastCall ? 0.5 : 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sacredCanvasTop.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AccentHero(accent: _accent, lastCall: _isLastCall),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: _accent,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Verb — Outfit bold on cream ink (spec §9.1: Outfit-only).
                    Text(
                      verb,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.sacredInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (why != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        why,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.sacredInkSoft,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _Footer(
                      cue: cue,
                      accent: _accent,
                      ctaLabel: DuaTimesCopy.ctaLabel(between: _isBetween),
                      onCta: onCta,
                    ),
                    if (onEnablePrecise != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _EnablePreciseBanner(
                        onTap: onEnablePrecise!,
                        onDismiss: onDismissPrecise,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _whyLine(DuaWindow? active, DuaWindow? next) {
    final window = active ?? next;
    if (window == null) return null;
    return DuaTimesCopy.why(window.type);
  }

  /// The supporting cue line: a live countdown for closing/last-call, "today
  /// only" for an active all-day window, a static deadline for a comfortable
  /// window, or a relative "{window} · {day}" for the between state.
  String _cueLine(DuaWindow? active, DuaWindow? next) {
    switch (state.urgency) {
      case UrgencyState.closing:
      case UrgencyState.lastCall:
        final remaining = active!.endUtc.difference(state.now.toUtc());
        return '${formatCountdown(remaining)} left';
      case UrgencyState.comfortable:
        return 'until it closes';
      case UrgencyState.allDay:
        return 'today only';
      case UrgencyState.upcoming:
        if (next == null) return 'coming soon';
        final daysUntil = _localDaysUntil(state.now, next.startUtc.toLocal());
        return '${DuaTimesCopy.windowName(next.type)} · '
            '${DuaTimesCopy.relativeDay(daysUntil)}';
    }
  }

  static int _localDaysUntil(DateTime now, DateTime target) {
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(target.year, target.month, target.day);
    return b.difference(a).inDays;
  }
}

/// The left-hand crescent + `دُعَاء` Arabic accent hero.
class _AccentHero extends StatelessWidget {
  const _AccentHero({required this.accent, required this.lastCall});
  final Color accent;
  final bool lastCall;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          lastCall ? Icons.error_outline_rounded : Icons.nightlight_round,
          color: accent,
          size: 26,
        ),
        const SizedBox(height: 6),
        // Arabic accent — Aref Ruqaa, own RTL widget, never mixed with Latin
        // (CLAUDE.md). AdjustedArabicDisplay corrects the ascender bleed.
        AdjustedArabicDisplay(
          text: 'دُعَاء',
          style: AppTypography.nameOfAllahDisplay.copyWith(
            fontSize: 22,
            color: AppColors.sacredInk,
          ),
        ),
      ],
    );
  }
}

/// The countdown/cue line + gold CTA pill footer.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.cue,
    required this.accent,
    required this.ctaLabel,
    required this.onCta,
  });

  final String cue;
  final Color accent;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            cue,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.sacredInkSoft,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Gold (or amber last-call) CTA pill — a non-text accent fill; the label
        // sits on it at full contrast.
        GestureDetector(
          onTap: onCta,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              ctaLabel,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The prominent "Turn on precise times" banner (spec §10) shown when location
/// is unavailable. This is NOT a subtle nudge — it's the switch that unlocks the
/// whole feature: without location the card can't show a live countdown, and the
/// home/lock WIDGET can never show precise times (an extension can't request
/// location) until the app has computed a located schedule. So it's a full-width
/// gold-bordered banner with a clear "Turn on" action and a necessity subline,
/// not a faint link.
class _EnablePreciseBanner extends StatelessWidget {
  const _EnablePreciseBanner({required this.onTap, this.onDismiss});
  final VoidCallback onTap;

  /// The ✕ snooze action. Its own gesture wins over the banner-wide [onTap], so
  /// tapping ✕ dismisses while tapping anywhere else enables.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    // A solid CREAM panel on the emerald card — high contrast so it can't be
    // missed (location is the switch for the whole feature). Big title, one
    // short benefit line, a large gold "Turn on" button, and a ✕ snooze.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        decoration: BoxDecoration(
          color: AppColors.sacredInk,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.sacredCanvasTop.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.my_location_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      DuaTimesCopy.enablePreciseTitle,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 20,
                          color: AppColors.primary.withValues(alpha: 0.45)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6, right: 8),
              child: Text(
                DuaTimesCopy.enablePreciseSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimaryLight.withValues(alpha: 0.72),
                  fontSize: 13.5,
                  height: 1.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  DuaTimesCopy.enablePreciseCta,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
