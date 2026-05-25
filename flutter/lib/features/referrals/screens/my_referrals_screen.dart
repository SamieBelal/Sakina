import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/referral_service.dart';
import '../../../widgets/sakina_loader.dart';
import '../../../widgets/subpage_header.dart';

/// Permanent post-onboarding surface for the referrer-side of the refer-to-
/// unlock loop. Lets the user see their code, re-share it, and watch grants
/// land. Reachable from Settings → "Refer a friend" via `/my-referrals`.
///
/// Spec: docs/superpowers/plans/2026-05-23-my-referrals-screen.md.
class MyReferralsScreen extends ConsumerStatefulWidget {
  const MyReferralsScreen({super.key});

  @override
  ConsumerState<MyReferralsScreen> createState() => _MyReferralsScreenState();
}

class _MyReferralsScreenState extends ConsumerState<MyReferralsScreen> {
  MyReferralsState? _state;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final String? uid;
    try {
      uid = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // Supabase not initialized (widget tests). Leave state untouched if
      // a fake has already been injected via an override + populated _state;
      // otherwise surface as error.
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = Exception('Not signed in');
      });
      return;
    }
    try {
      final svc = ref.read(referralServiceProvider);
      // Ensure the code exists (idempotent) before fetching state.
      await svc.ensureReferralCode(uid);
      final s = await svc.getMyReferralsState(uid);
      if (!mounted) return;
      setState(() {
        _state = s;
        _loading = false;
      });
      ref.read(analyticsProvider).track(
        AnalyticsEvents.myReferralsShown,
        properties: <String, dynamic>{
          'confirmed_count': s.confirmedCount,
          'grants_count': s.grants.length,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// Test seam: lets widget tests seed [_state] directly without round-
  /// tripping through Supabase auth. Production callers use [_load].
  @visibleForTesting
  void debugSeedState(MyReferralsState seeded) {
    setState(() {
      _state = seeded;
      _loading = false;
      _error = null;
    });
    ref.read(analyticsProvider).track(
      AnalyticsEvents.myReferralsShown,
      properties: <String, dynamic>{
        'confirmed_count': seeded.confirmedCount,
        'grants_count': seeded.grants.length,
      },
    );
  }

  Future<void> _onCopyCode(String code) async {
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    await HapticFeedback.selectionClick();
    ref.read(analyticsProvider).track(AnalyticsEvents.myReferralsCodeCopied);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onShare(String code) async {
    ref.read(analyticsProvider).track(AnalyticsEvents.myReferralsShareTapped);
    await ref.read(referralServiceProvider).shareMyCode(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              const SubpageHeader(
                title: 'Refer a friend',
                subtitle:
                    'Send a dua to 3 friends to unlock 30 days + a Gold card.',
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: SakinaLoader());
    }
    if (_error != null) {
      return _ErrorRetry(onRetry: _load);
    }
    final s = _state;
    if (s == null) {
      return _ErrorRetry(onRetry: _load);
    }
    final hasGrants = s.grants.isNotEmpty;
    final isEmpty = s.confirmedCount == 0 && !hasGrants;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CodeCard(
                            code: s.code,
                            onCopy: () => _onCopyCode(s.code),
                          ),
                          const SizedBox(height: 14),
                          _ShareButton(onTap: () => _onShare(s.code)),
                        ],
                      ),
                    ),
                  ),
                  _ProgressSection(state: s),
                  if (hasGrants) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const _SectionLabel('Rewards earned'),
                    const SizedBox(height: AppSpacing.sm),
                    ...s.grants.map((g) => _GrantRow(grant: g)),
                  ],
                  if (isEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "No one's joined yet. Share your code with a friend who'd love this.",
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 4),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 174),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 30,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 4),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Your code',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontSize: 15,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  code.isEmpty ? '— — — —' : code,
                  maxLines: 1,
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontSize: 38,
                    height: 1.12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 4.8,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap to copy',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.ios_share, size: 18),
        label: Text(
          'Share your code',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textOnPrimary,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.state});

  final MyReferralsState state;

  String _formatExpiry(DateTime when) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[when.month - 1]} ${when.day}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = state.progressTowardNext;
    final hasGrants = state.grants.isNotEmpty;

    // Headline count — when the user is mid-cycle after a grant we want the
    // "X of 3" to reflect the NEW progress, not their lifetime confirmed.
    final headlineCount =
        hasGrants ? progress : state.confirmedCount.clamp(0, 3);

    final caption = (progress == 0 && hasGrants)
        ? 'Your last reward is active until ${_formatExpiry(state.grants.first.expiresAt)}. Send to 3 more to earn another.'
        : 'Sending love means a dua for them too — the Angel says Ameen for you in return.';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 4),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$headlineCount of 3 friends joined',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
              fontSize: 19,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(3, (i) {
              final filled = i < progress;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: _ProgressDot(filled: filled),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : AppColors.surfaceLight,
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.borderLight,
          width: 2,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _GrantRow extends StatelessWidget {
  const _GrantRow({required this.grant});

  final MyReferralGrant grant;

  String _relative(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inHours < 24 && when.day == now.day) return 'Earned today';
    if (diff.inDays == 1) return 'Earned yesterday';
    if (diff.inDays < 7) return 'Earned ${diff.inDays} days ago';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Earned ${months[when.month - 1]} ${when.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryLight,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '30 days + Gold card',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _relative(grant.grantedAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Couldn't load your referrals right now.",
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm + 2,
              ),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
