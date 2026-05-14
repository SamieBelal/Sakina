import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/referral_service.dart';

/// Full-screen route shown after the user dismisses the onboarding paywall
/// for the FIRST time (subsequent dismisses go to the WinbackScreen). Reframes
/// the moment from "pay vs walk away" to "pay vs send a dua to 3 friends".
///
/// Spiritual-native framing per
/// docs/superpowers/plans/2026-05-14-refer-unlock.md — the share copy is
/// "I made a dua for you", NOT generic "join me on Sakina". The verb is
/// "send a dua to 3 friends", NOT "invite 3 friends". This is the brand moat.
///
/// Custom-scheme share link only in v1 (`sakina://r/<code>`). Universal-link
/// path is Phase 2 (post-sakina.app-domain-acquisition). The link is dead
/// on devices without Sakina installed — accepted v1 trade-off.
class ReferUnlockScreen extends ConsumerStatefulWidget {
  const ReferUnlockScreen({
    required this.onStartTrial,
    required this.onClose,
    this.paywallDwellSeconds,
    this.shareOverride,
    super.key,
  });

  /// Called when the user picks "Start your 7-day free trial" — typically
  /// pops the screen and re-presents the paywall.
  final VoidCallback onStartTrial;

  /// Called when the user closes without taking either action (back gesture,
  /// dismiss button, etc.).
  final VoidCallback onClose;

  /// Time the user spent on the paywall before dismissing — passed as a
  /// property on `refer_unlock_shown` for forward-instrumentation. May be
  /// null if the caller doesn't have a wall clock.
  final int? paywallDwellSeconds;

  /// Test seam — swap [Share.share] for a deterministic side-effect-free
  /// recorder. In production this is null and the real share sheet opens.
  final Future<void> Function(String text)? shareOverride;

  @override
  ConsumerState<ReferUnlockScreen> createState() => _ReferUnlockScreenState();
}

class _ReferUnlockScreenState extends ConsumerState<ReferUnlockScreen> {
  String? _myCode;
  int _confirmedCount = 0;
  bool _loadingCode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final props = <String, dynamic>{};
      if (widget.paywallDwellSeconds != null) {
        props['paywall_dwell_seconds'] = widget.paywallDwellSeconds;
      }
      ref
          .read(analyticsProvider)
          .track(AnalyticsEvents.referUnlockShown, properties: props);
      _loadCodeAndCount();
    });
  }

  Future<void> _loadCodeAndCount() async {
    final String? uid;
    try {
      uid = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // Supabase not initialized (e.g. in widget tests). Bail safely.
      return;
    }
    if (uid == null || uid.isEmpty) return;
    setState(() => _loadingCode = true);
    final svc = ref.read(referralServiceProvider);
    // Ensure the code exists (idempotent) before reading it.
    await svc.ensureReferralCode(uid);
    final code = await svc.getMyReferralCode(uid);
    final count = await svc.confirmedCount(uid);
    if (!mounted) return;
    setState(() {
      _myCode = code;
      _confirmedCount = count;
      _loadingCode = false;
    });
  }

  Future<void> _onShare() async {
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.referUnlockShareTapped);
    // Universal links are out of scope v1 — fire this event on every share
    // so Phase 2 dashboards can compare the install-funnel before/after the
    // domain rollout.
    analytics.track(AnalyticsEvents.referUnlockShareNoUniversalLinks);

    final code = _myCode;
    if (code == null || code.isEmpty) {
      // Code not loaded yet — try once more synchronously.
      await _loadCodeAndCount();
      if (_myCode == null) return;
    }
    final myCode = _myCode!;
    final shareText =
        "I made a dua for you. Sakina helped me reflect on Allah's Names "
        '— open this to join me: sakina://r/$myCode';
    final shareFn = widget.shareOverride ?? Share.share;
    await shareFn(shareText);
  }

  void _onStartTrial() {
    ref.read(analyticsProvider).track(AnalyticsEvents.referUnlockStartTrialTapped);
    widget.onStartTrial();
  }

  Future<bool> _onWillPop() async {
    ref.read(analyticsProvider).track(AnalyticsEvents.referUnlockBackToPaywall);
    widget.onClose();
    return false; // We handle the pop ourselves.
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: _onWillPop,
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimaryLight),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Two paths forward',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Both unlock everything. Pick what feels right.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 500.ms, delay: 80.ms),
                const SizedBox(height: AppSpacing.lg),
                // Top card — Start trial.
                _PathCard(
                  badge: 'OPTION 1',
                  title: 'Start your 7-day free trial',
                  body: 'Full access today. Cancel anytime before day 3, '
                      'no charge. After that, the annual plan unlocks '
                      'everything for one low yearly price.',
                  ctaLabel: 'Start free trial',
                  onTap: _onStartTrial,
                  badgeColor: AppColors.secondary,
                  primary: true,
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 160.ms)
                    .slideY(begin: 0.04, end: 0),
                const SizedBox(height: AppSpacing.md),
                // Bottom card — Send a dua to 3 friends.
                _PathCard(
                  badge: 'OPTION 2',
                  title: 'Send a dua to 3 friends',
                  body:
                      'You unlock 30 days + a Gold card. They each get 7 days free.\n\n'
                      'The act of sending the link is itself a dua for your friend — '
                      'a gift, not a transaction.',
                  ctaLabel: _loadingCode
                      ? 'Loading…'
                      : 'Send to friends ($_confirmedCount / 3 joined)',
                  onTap: _loadingCode ? null : _onShare,
                  badgeColor: AppColors.primary,
                  primary: false,
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 240.ms)
                    .slideY(begin: 0.04, end: 0),
                const Spacer(),
                Text(
                  _myCode != null
                      ? 'Your code: $_myCode'
                      : 'Generating your code…',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.badge,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onTap,
    required this.badgeColor,
    required this.primary,
  });

  final String badge;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback? onTap;
  final Color badgeColor;

  /// `true` for the trial card — emerald-filled CTA. `false` for the share
  /// card — outlined emerald CTA. The visual hierarchy is intentional: the
  /// trial is the paid path (most lift), the share path is the social path
  /// (most reach). Both must feel viable; neither is the "obvious wrong
  /// choice".
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: AppTypography.labelSmall.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
              fontSize: 22,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: primary
                ? ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Text(
                      ctaLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textOnPrimary,
                        fontSize: 15,
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Text(
                      ctaLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
