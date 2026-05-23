import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/referral_service.dart';
import '../../../widgets/referral_code_field.dart';

/// Modal bottom-sheet content for Settings → Redeem a referral code.
///
/// Surfaced from `SettingsScreen._openRedeemCodeSheet`. Drives the
/// settings-path redeem funnel:
///   1. User types/pastes the code into a [ReferralCodeField].
///   2. Tapping "Redeem" calls `ReferralService.redeemCodeNow` (which hits
///      apply_referral with source='settings_redeem').
///   3. The sheet body swaps to a result panel based on the structured
///      result's reason string (verified against the SQL contract in
///      supabase/migrations/20260514000000_referrals.sql + the
///      20260523000001 reason-split patch).
///
/// Test pin: `test/features/settings/redeem_code_sheet_test.dart`. The
/// [userId] is constructor-injected so tests don't need to mock
/// `Supabase.instance.client.auth.currentUser` — production callers read
/// `Supabase.instance.client.auth.currentUser?.id ?? ''` at the
/// `showModalBottomSheet` site.
class RedeemCodeSheet extends ConsumerStatefulWidget {
  const RedeemCodeSheet({
    super.key,
    required this.userId,
  });

  /// Authenticated user id. Required so this sheet stays trivially
  /// testable (no Supabase mocks). Production passes
  /// `Supabase.instance.client.auth.currentUser?.id ?? ''`.
  final String userId;

  @override
  ConsumerState<RedeemCodeSheet> createState() => _RedeemCodeSheetState();
}

class _RedeemCodeSheetState extends ConsumerState<RedeemCodeSheet> {
  String _code = '';
  ReferralCodeValidationState _validation = ReferralCodeValidationState.empty;
  bool _isRedeeming = false;

  // Null while no submission has resolved. Once set, the sheet body swaps
  // to the result panel.
  ({bool ok, bool granted7d, String? reason})? _result;

  Timer? _autoDismissTimer;

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  bool get _canRedeem =>
      !_isRedeeming &&
      _code.length >= 8 &&
      _validation != ReferralCodeValidationState.validating;

  Future<void> _onRedeemTap() async {
    if (!_canRedeem) return;
    setState(() => _isRedeeming = true);

    // Fire submitted analytics regardless of outcome — paired in funnel
    // dashboards with refereeSignedUpWithReferral (success cases).
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.referralSettingsRedeemSubmitted);

    try {
      final result = await ref
          .read(referralServiceProvider)
          .redeemCodeNow(widget.userId, _code);
      if (!mounted) return;
      setState(() {
        _result = result;
        // Only re-enable the button for retryable cases (invalid_code +
        // network_error). Other outcomes leave the result panel mounted.
        final reason = result.reason;
        final isRetryable =
            reason == 'invalid_code' || reason == 'network_error';
        if (isRetryable) {
          _isRedeeming = false;
        }
      });

      // Auto-dismiss only for the success cases AND the idempotent same-code
      // re-redeem (user has had a moment to read the confirmation).
      final shouldAutoDismiss = (result.ok && result.granted7d) ||
          (result.ok && result.reason == 'idempotent_same_code');
      if (shouldAutoDismiss) {
        _autoDismissTimer?.cancel();
        _autoDismissTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = (ok: false, granted7d: false, reason: 'network_error');
        _isRedeeming = false;
      });
    }
  }

  void _resetForRetry() {
    setState(() {
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        // Sheet content is short but ReferralCodeField + keyboard +
        // dynamic result panel can push past the modal's natural height
        // on small devices — wrap to avoid layout overflow.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle for sheet affordance.
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_result == null) ..._buildEntry() else ..._buildResult(_result!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEntry() {
    return [
      Text(
        "Redeem your friend's gift",
        style: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimaryLight,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Enter the code a friend shared with you to unlock 7 days of Sakina.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      ReferralCodeField(
        autofocus: true,
        onCodeChanged: (code, state) {
          setState(() {
            _code = code;
            _validation = state;
          });
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canRedeem ? _onRedeemTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor:
                AppColors.primary.withValues(alpha: 0.35),
            disabledForegroundColor:
                AppColors.textOnPrimary.withValues(alpha: 0.75),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          child: _isRedeeming
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Text(
                  'Redeem',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
        ),
      ),
    ];
  }

  List<Widget> _buildResult(
      ({bool ok, bool granted7d, String? reason}) result) {
    if (result.ok && result.granted7d) {
      return _resultBody(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.primary,
        arabic: 'جزاك الله خيرًا',
        message: 'Your friend just gave you 7 days of Sakina.',
        showRetry: false,
        showClose: false,
      );
    }
    if (result.ok && result.reason == 'idempotent_same_code') {
      return _resultBody(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.textSecondaryLight,
        message: "You've already used this code.",
        showRetry: false,
        showClose: false,
      );
    }
    if (result.ok && result.reason == 'already_referred_other_code') {
      // Hard lockout — no auto-dismiss, user must explicitly close.
      return _resultBody(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.textSecondaryLight,
        message:
            "You've already redeemed a code on this account — only one per account.",
        showRetry: false,
        showClose: true,
      );
    }
    final reason = result.reason;
    if (reason == 'invalid_code') {
      return _resultBody(
        icon: Icons.help_outline_rounded,
        iconColor: AppColors.textTertiaryLight,
        message: "We couldn't find that code. Double-check it and try again.",
        showRetry: true,
        showClose: false,
      );
    }
    if (reason == 'self_referral') {
      return _resultBody(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.textTertiaryLight,
        message: "You can't redeem your own code.",
        showRetry: false,
        showClose: true,
      );
    }
    if (reason == 'chain_referral') {
      return _resultBody(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.textTertiaryLight,
        message: "This account isn't eligible.",
        showRetry: false,
        showClose: true,
      );
    }
    if (reason == 'network_error') {
      return _resultBody(
        icon: Icons.wifi_off_rounded,
        iconColor: AppColors.textTertiaryLight,
        message:
            "We couldn't apply that code. Check your connection and try again.",
        showRetry: true,
        showClose: false,
      );
    }
    // Fallback for any unrecognized reason — keep the sheet open so the
    // user can close manually.
    return _resultBody(
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.textTertiaryLight,
      message: 'Something went wrong. Please try again later.',
      showRetry: false,
      showClose: true,
    );
  }

  List<Widget> _resultBody({
    required IconData icon,
    required Color iconColor,
    String? arabic,
    required String message,
    required bool showRetry,
    required bool showClose,
  }) {
    return [
      Center(
        child: Icon(icon, size: 48, color: iconColor),
      ),
      const SizedBox(height: AppSpacing.md),
      if (arabic != null) ...[
        // Arabic must NEVER share a Text with English (CLAUDE.md). Keep
        // it in its own widget with explicit RTL direction.
        Center(
          child: Text(
            arabic,
            textDirection: TextDirection.rtl,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              fontSize: 28,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
      ),
      if (showRetry) ...[
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _resetForRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(
              'Try again',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
      if (showClose) ...[
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(
              'Close',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ],
    ];
  }
}
