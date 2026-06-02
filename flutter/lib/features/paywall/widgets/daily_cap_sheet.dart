import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:sakina/services/gating_service.dart';

import 'warmup_exhausted_sheet.dart' show GatedFeature, PaywallSheetScaffold;

/// Bottom sheet shown to a free user who has already used their 1/day Reflect
/// / Built Dua / Discover Name allotment, OR for narrative high-point
/// triggers (post-streak-milestone, post-card-collected) — in which case the
/// caller passes [headlineOverride] for context-specific copy.
///
/// Adds a middle "AI bypass" CTA when [onBypassRequested] is supplied (PR 2
/// of the AI bypass plan, 2026-05-23). The bypass slot renders in one of
/// three states depending on [tokenBalance], [bypassesUsedToday], and
/// [isPremium]:
///
///   STATE A — enough tokens + bypasses_today < cap: enabled "Use 25 tokens
///             for one more (you have N)"
///   STATE B — tokens < 25 + bypasses_today < cap:   disabled, hint
///             "You have N tokens. Need 25."
///   STATE C — bypasses_today >= cap:                disabled, hint
///             "Bypass cap reached. Resets tomorrow."
///   isPremium == true:                              bypass slot hidden
///             entirely (premium uses fair-use ceiling, not this sheet).
///
/// When [onBypassRequested] is null, the sheet renders the legacy two-CTA
/// layout (primary + tertiary) so existing callers without the bypass props
/// stay backward-compatible.
class DailyCapSheet extends StatelessWidget {
  final GatedFeature feature;
  final String? headlineOverride;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  /// Required for the bypass slot. When null, the bypass CTA is hidden.
  final ValueChanged<GatedFeature>? onBypassRequested;
  final int? tokenBalance;
  final int? bypassesUsedToday;
  final bool isPremium;

  /// Day-1 freebie variant (STATE D). When [firstBypassAvailable] is true and
  /// [onFirstBypassRequested] is wired, the sheet renders gold-themed copy +
  /// "X one more time, free" primary CTA INSTEAD of the standard "Unlock
  /// unlimited" + token-bypass layout. EXP-2 of plan 2026-05-23 — the point
  /// is product discovery of the bypass mechanic, not monetization, so the
  /// "Unlock unlimited" CTA is intentionally hidden in this state.
  final bool firstBypassAvailable;
  final ValueChanged<GatedFeature>? onFirstBypassRequested;
  final String? userDisplayName;

  const DailyCapSheet({
    super.key,
    required this.feature,
    required this.onUpgrade,
    required this.onDismiss,
    this.headlineOverride,
    this.onBypassRequested,
    this.tokenBalance,
    this.bypassesUsedToday,
    this.isPremium = false,
    this.firstBypassAvailable = false,
    this.onFirstBypassRequested,
    this.userDisplayName,
  });

  /// Telemetry hook for `ai_bypass_offered` (PR 3 of plan 2026-05-23).
  /// Set once at app startup in `main.dart` to bridge to `AnalyticsService`.
  /// Fires inside [show] whenever the bypass middle slot will actually
  /// render (`!isPremium && onBypassRequested != null && counters supplied`).
  /// Matching `ai_bypass_purchased` / `ai_bypass_rejected` fire from the
  /// `GatingService.reserveBypass` hook.
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  static Future<void> show(
    BuildContext context, {
    required GatedFeature feature,
    required VoidCallback onUpgrade,
    String? headlineOverride,
    ValueChanged<GatedFeature>? onBypassRequested,
    int? tokenBalance,
    int? bypassesUsedToday,
    bool isPremium = false,
    bool firstBypassAvailable = false,
    ValueChanged<GatedFeature>? onFirstBypassRequested,
    String? userDisplayName,
  }) {
    // STATE D takes precedence over the token-bypass slot — when the user
    // qualifies for the Day-1 freebie, the sheet shows ONLY the freebie CTA
    // (the paid-bypass slot is hidden so we don't ask someone to spend
    // tokens 1ms before offering them the same thing for free).
    final willRenderStateD = firstBypassAvailable &&
        !isPremium &&
        onFirstBypassRequested != null;
    final willRenderBypassSlot = !willRenderStateD &&
        !isPremium &&
        onBypassRequested != null &&
        tokenBalance != null &&
        bypassesUsedToday != null;
    if (willRenderStateD) {
      onAnalyticsEvent?.call(AnalyticsEvents.firstBypassOffered, {
        'feature': _featureKey(feature),
      });
    } else if (willRenderBypassSlot) {
      onAnalyticsEvent?.call(AnalyticsEvents.aiBypassOffered, {
        'feature': _featureKey(feature),
        'token_balance': tokenBalance,
        'bypasses_used_today': bypassesUsedToday,
      });
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return DailyCapSheet(
          feature: feature,
          headlineOverride: headlineOverride,
          onBypassRequested: onBypassRequested,
          tokenBalance: tokenBalance,
          bypassesUsedToday: bypassesUsedToday,
          isPremium: isPremium,
          firstBypassAvailable: firstBypassAvailable,
          onFirstBypassRequested: onFirstBypassRequested,
          userDisplayName: userDisplayName,
          onUpgrade: () {
            Navigator.of(sheetContext).pop();
            onUpgrade();
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  /// Mirrors `GatingService._bypassFeatureKey` — kept duplicated rather than
  /// exported because (a) the gating service version is private to that
  /// file's RPC contract and (b) this is the analytics-side string, which
  /// we want frozen against accidental renames in either layer. Tests pin
  /// both values to the same 3 literals.
  static String _featureKey(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return 'reflect';
      case GatedFeature.builtDua:
        return 'built_dua';
      case GatedFeature.discoverName:
        return 'discover_name';
    }
  }

  String get _defaultHeadline {
    switch (feature) {
      case GatedFeature.reflect:
        return "You've reflected today";
      case GatedFeature.builtDua:
        return "You've built today's dua";
      case GatedFeature.discoverName:
        return "You've discovered today's Name";
    }
  }

  String get _body {
    switch (feature) {
      case GatedFeature.reflect:
        return "Tomorrow's reflection is on us. Or unlock unlimited now.";
      case GatedFeature.builtDua:
        return "Tomorrow's dua is on us. Or unlock unlimited now.";
      case GatedFeature.discoverName:
        return "Tomorrow's discovery is on us. Or unlock unlimited now.";
    }
  }

  bool get _isStateD =>
      firstBypassAvailable && !isPremium && onFirstBypassRequested != null;

  /// STATE D headline. Uses the user's display_name when set and not the
  /// default "Friend" placeholder — greeting someone by a generic
  /// placeholder is worse than no greeting at all.
  String get _stateDHeadline {
    final name = userDisplayName;
    if (name == null ||
        name.isEmpty ||
        name == AuthService.defaultDisplayName) {
      return 'One more on us';
    }
    return 'One more on us, $name';
  }

  String get _stateDBody {
    switch (feature) {
      case GatedFeature.reflect:
        return "We saved you an extra reflection for today. "
            "Tomorrow you'll get one a day.";
      case GatedFeature.builtDua:
        return "We saved you an extra dua for today. "
            "Tomorrow you'll get one a day.";
      case GatedFeature.discoverName:
        return "We saved you an extra Name discovery for today. "
            "Tomorrow you'll get one a day.";
    }
  }

  String get _stateDPrimaryLabel {
    switch (feature) {
      case GatedFeature.reflect:
        return 'Reflect one more time, free';
      case GatedFeature.builtDua:
        return 'Build one more dua, free';
      case GatedFeature.discoverName:
        return 'Discover one more Name, free';
    }
  }

  /// True when the sheet should render the AI-bypass middle CTA at all.
  /// Hidden for premium users (defense-in-depth — premium should never
  /// reach this sheet, but if they do, never offer the bypass CTA) and
  /// when the caller didn't wire the callback.
  bool get _shouldRenderBypassSlot {
    return !isPremium &&
        onBypassRequested != null &&
        tokenBalance != null &&
        bypassesUsedToday != null;
  }

  bool get _bypassEnabled {
    if (!_shouldRenderBypassSlot) return false;
    final balance = tokenBalance ?? 0;
    final used = bypassesUsedToday ?? 0;
    return balance >= GatingService.bypassTokenCost &&
        used < GatingService.maxBypassesPerDayPerFeature;
  }

  String get _bypassLabel {
    final balance = tokenBalance ?? 0;
    return 'Use ${GatingService.bypassTokenCost} tokens for one more '
        '(you have $balance)';
  }

  String? get _bypassDisabledHint {
    if (!_shouldRenderBypassSlot) return null;
    final balance = tokenBalance ?? 0;
    final used = bypassesUsedToday ?? 0;
    if (used >= GatingService.maxBypassesPerDayPerFeature) {
      return "You've used today's bypasses. They reset tomorrow.";
    }
    if (balance < GatingService.bypassTokenCost) {
      return 'You have $balance tokens. Need ${GatingService.bypassTokenCost}.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isStateD) {
      return PaywallSheetScaffold(
        icon: Icons.workspace_premium,
        headline: _stateDHeadline,
        body: _stateDBody,
        // STATE D collapses to a single gold primary + tertiary dismiss.
        // "Unlock unlimited" is intentionally hidden — the freebie's job is
        // product discovery, not sub upsell. Token-bypass slot also hidden
        // because asking someone to pay 1ms after offering a freebie would
        // be insulting.
        primaryLabel: _stateDPrimaryLabel,
        primaryColor: AppColors.secondary,
        secondaryLabel: 'Maybe later',
        onPrimary: () {
          Navigator.of(context).pop();
          onFirstBypassRequested!(feature);
        },
        onSecondary: onDismiss,
      );
    }
    return PaywallSheetScaffold(
      icon: Icons.wb_sunny_outlined,
      headline: headlineOverride ?? _defaultHeadline,
      body: _body,
      primaryLabel: 'Unlock unlimited',
      secondaryLabel: 'Maybe later',
      onPrimary: onUpgrade,
      onSecondary: onDismiss,
      middleLabel: _shouldRenderBypassSlot ? _bypassLabel : null,
      middleEnabled: _bypassEnabled,
      middleDisabledHint: _bypassDisabledHint,
      onMiddle: _shouldRenderBypassSlot
          ? () {
              // Sheet closes synchronously; provider takes over the
              // reserve → AI → commit/cancel flow. If reserve fails, the
              // provider surfaces a toast or re-opens the sheet.
              Navigator.of(context).pop();
              onBypassRequested!(feature);
            }
          : null,
    );
  }
}
