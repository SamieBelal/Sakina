import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/referral_service.dart';
import '../../../widgets/subpage_header.dart';

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

  /// Set true when the user taps one of our own CTAs (back / start trial)
  /// before we trigger a programmatic pop. PopScope.onPopInvokedWithResult
  /// reads this to distinguish "user used an in-screen button" (we fired
  /// analytics already) from "user used the iOS back-swipe / Android back
  /// button" (we need to fire back-to-paywall analytics + onClose).
  bool _explicitlyExiting = false;

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
    if (!mounted) return;
    // Share-text + iPad popover-origin logic factored into
    // ReferralService.shareMyCode so both this screen and the My Referrals
    // screen stay in lockstep. The widget-level shareOverride test seam is
    // forwarded as the override arg.
    await ref.read(referralServiceProvider).shareMyCode(
          context,
          myCode,
          override: widget.shareOverride,
        );
  }

  void _onStartTrial() {
    ref.read(analyticsProvider).track(AnalyticsEvents.referUnlockStartTrialTapped);
    _explicitlyExiting = true;
    widget.onStartTrial();
  }

  Future<void> _onWillPop() async {
    ref.read(analyticsProvider).track(AnalyticsEvents.referUnlockBackToPaywall);
    _explicitlyExiting = true;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: true so programmatic pops from our own CTAs go through
      // (PopScope with canPop:false silently blocks Navigator.pop calls,
      // which is what made Start Trial freeze the screen). We still want
      // to fire back-to-paywall analytics when the user uses a SYSTEM
      // back gesture (iOS edge-swipe, Android back) — distinguish via
      // [_explicitlyExiting], which our own buttons set before popping.
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) return;
        if (_explicitlyExiting) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                SubpageHeader(
                  title: 'Two paths forward',
                  subtitle: 'Both unlock everything. Pick what feels right.',
                  onBack: _onWillPop,
                ),
                const SizedBox(height: AppSpacing.xl),
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
                // Bottom card — Send a dua to 3 friends. The hadith body is
                // the canonical English from sunnah.com Sahih Muslim 2732b
                // (narrator Umm Darda'); the mutual-reward mechanic of this
                // PR is literally the hadith ("Amen, and it is for you also")
                // so we cite it directly instead of restating in our own
                // voice. Do NOT paraphrase — see CLAUDE.md "NEVER generate
                // or fabricate Quran verses, hadith, or scholarly content."
                _PathCard(
                  badge: 'OPTION 2',
                  title: 'Send a dua to 3 friends',
                  body:
                      'You unlock 30 days + a Gold card. They each get 7 days free.',
                  quote:
                      'He who supplicates for his brother behind his back (in his absence), '
                      'the Angel commissioned (for carrying supplication to his Lord) says: '
                      'Amen, and it is for you also.',
                  quoteCitation: 'Sahih Muslim 2732b',
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
    this.quote,
    this.quoteCitation,
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

  /// Optional scripture block rendered beneath [body] with a thin warm
  /// divider above. Italicized, with [quoteCitation] right-aligned in gold
  /// beneath. Used on the share card to render the Sahih Muslim 2732b
  /// hadith that literally describes the mutual-reward mechanic. Both must
  /// be non-null to render — passing only one is a no-op.
  final String? quote;
  final String? quoteCitation;

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
          if (quote != null && quoteCitation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 1,
              color: AppColors.dividerLight,
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              '\u201C$quote\u201D',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
                height: 1.45,
                fontStyle: FontStyle.italic,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '\u2014 $quoteCitation',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            // 54 (was 48) to give descenders breathing room — at 48 the
            // "p" in "Start free trial" was visibly grazing the bottom
            // edge on physical iPhone. Matches the paywall main CTA.
            height: 54,
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
