import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/env.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/gift_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';
import 'package:sakina/widgets/sakina_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Surface state for the home-screen gift card. The card's three rendered
/// states are:
///
/// 1. `loading` — `currentOccasion()` + cached-expiry lookup is in flight.
///    The home stack renders a skeleton until this resolves; we never show
///    a flicker of "no card → card appears" on cold launch. This mirrors
///    the `_rewardsLoaded` pattern from `daily_launch_overlay.dart` per PR #8.
/// 2. `inactive` — outside every seeded occasion window OR the kill switch
///    is tripped. Card renders nothing (consumers handle the empty case).
/// 3. `preClaim(occasionId)` — inside an occasion window, user has not yet
///    claimed. Show the welcome card with "Accept your gift" CTA.
/// 4. `postClaim(expiresAt)` — user has claimed (or had previously) and the
///    cached expiry is still in the future. Show a quieter status row so
///    premium feels rewarded; do not hide the card outright.
@immutable
sealed class _GiftCardState {
  const _GiftCardState();
}

class _GiftCardLoading extends _GiftCardState {
  const _GiftCardLoading();
}

class _GiftCardInactive extends _GiftCardState {
  const _GiftCardInactive();
}

class _GiftCardPreClaim extends _GiftCardState {
  const _GiftCardPreClaim(this.occasionId);
  final String occasionId;
}

class _GiftCardPostClaim extends _GiftCardState {
  const _GiftCardPostClaim(this.expiresAt);
  final DateTime expiresAt;
}

/// Home-screen Ramadan / Eid gift surface.
///
/// Render gating: shown only when ALL of these are true:
///
/// 1. `Env.ramadanGiftEnabled == true`
/// 2. `GiftService.currentOccasion()` returns non-null
/// 3. The user is signed in (we cannot meaningfully claim for a null UID)
///
/// If the user has already accepted the gift for the current occasion the
/// card switches to a quieter post-claim status row showing the expiry.
class RamadanGiftCard extends ConsumerStatefulWidget {
  const RamadanGiftCard({super.key, GiftService? giftService})
      : _giftService = giftService;

  /// Override for tests. Production callers omit this and the widget falls
  /// back to the module-level `giftService` singleton.
  final GiftService? _giftService;

  @override
  ConsumerState<RamadanGiftCard> createState() => _RamadanGiftCardState();
}

class _RamadanGiftCardState extends ConsumerState<RamadanGiftCard> {
  late final GiftService _gift = widget._giftService ?? giftService;

  _GiftCardState _state = const _GiftCardLoading();
  bool _claiming = false;
  bool _shownEventFired = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (!Env.ramadanGiftEnabled) {
      if (mounted) setState(() => _state = const _GiftCardInactive());
      return;
    }

    try {
      // Both lookups in parallel — neither depends on the other and combined
      // they should resolve well under the 10s budget. .timeout() so a hung
      // network can't trap the user in the loader (mirrors PR #8 loading-gate).
      final results = await Future.wait([
        _gift.currentOccasion(),
        _gift.cachedExpiresAt(),
      ]).timeout(const Duration(seconds: 10));
      final occasion = results[0] as String?;
      final cachedExpiry = results[1] as DateTime?;

      if (!mounted) return;

      // Post-claim takes precedence: if the cached window is still active
      // we surface the status row regardless of which occasion we're "in"
      // (the gift may have come from an earlier overlapping occasion).
      if (cachedExpiry != null &&
          GiftService.currentClock().isBefore(cachedExpiry)) {
        setState(() => _state = _GiftCardPostClaim(cachedExpiry));
        return;
      }

      if (occasion == null) {
        // Window expired? Fire the once-per-window analytics marker.
        await _maybeFireExpiredEvent(cachedExpiry);
        setState(() => _state = const _GiftCardInactive());
        return;
      }

      setState(() => _state = _GiftCardPreClaim(occasion));
      _fireShownEventOnce(occasion);
    } catch (_) {
      // Lookup failed (network, timeout). Render nothing rather than
      // trapping the user in a loader. Next cold launch retries.
      if (mounted) setState(() => _state = const _GiftCardInactive());
    }
  }

  /// Fire `ramadan_gift_window_expired` once per user per (cached) expiry —
  /// when the cached expiry has passed AND no active occasion is in window.
  /// Idempotent via a per-user SharedPrefs marker.
  Future<void> _maybeFireExpiredEvent(DateTime? cachedExpiry) async {
    if (cachedExpiry == null) return;
    if (!GiftService.currentClock().isAfter(cachedExpiry)) return;
    final prefs = await SharedPreferences.getInstance();
    final key = supabaseSyncService
        .scopedKey('ramadan_gift_expired_event_${cachedExpiry.toIso8601String()}');
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.ramadanGiftWindowExpired, properties: {
      'expired_at': cachedExpiry.toIso8601String(),
    });
  }

  void _fireShownEventOnce(String occasionId) {
    if (_shownEventFired) return;
    _shownEventFired = true;
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.ramadanGiftShown, properties: {
      'occasion_id': occasionId,
    });
  }

  Future<void> _acceptGift(String occasionId) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    HapticFeedback.lightImpact();

    final result = await _gift.claim(occasionId);
    if (!mounted) return;

    if (result.granted && result.expiresAt != null) {
      ref
          .read(analyticsProvider)
          .track(AnalyticsEvents.ramadanGiftClaimed, properties: {
        'occasion_id': occasionId,
        'reused': result.reused,
      });
      setState(() {
        _claiming = false;
        _state = _GiftCardPostClaim(result.expiresAt!);
      });
      return;
    }

    // Surface a soft snackbar on denial — outside_window happens rarely
    // (race vs server clock); unauthorized/unknown should both be quiet.
    setState(() => _claiming = false);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        content: Text(
          'We couldn\'t accept the gift just now. Please try again later.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _GiftCardLoading() => const _LoadingSkeleton(),
      _GiftCardInactive() => const SizedBox.shrink(),
      _GiftCardPreClaim(:final occasionId) => _PreClaimCard(
          occasionId: occasionId,
          claiming: _claiming,
          onAccept: () => _acceptGift(occasionId),
        ),
      _GiftCardPostClaim(:final expiresAt) =>
        _PostClaimStatus(expiresAt: expiresAt),
    };
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: SakinaLoader()),
    );
  }
}

class _PreClaimCard extends StatelessWidget {
  const _PreClaimCard({
    required this.occasionId,
    required this.claiming,
    required this.onAccept,
  });

  final String occasionId;
  final bool claiming;
  final VoidCallback onAccept;

  bool get _isEid => occasionId.startsWith('eid_') || occasionId.startsWith('mawlid_');
  String get _arabicHeader => _isEid ? 'عيد مبارك' : 'رمضان مبارك';
  String get _englishHeadline {
    if (occasionId.startsWith('ramadan_')) return 'A gift from Sakina for Ramadan';
    if (occasionId.startsWith('eid_fitr_')) return 'A gift from Sakina for Eid al-Fitr';
    if (occasionId.startsWith('eid_adha_')) return 'A gift from Sakina for Eid al-Adha';
    if (occasionId.startsWith('mawlid_')) return 'A gift from Sakina for Mawlid';
    return 'A gift from Sakina';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Arabic header — AdjustedArabicDisplay per CLAUDE.md font-metric fix.
          // 33px spacer above (for fontSize 36 → 36 * 0.92 ≈ 33), 20px below.
          const SizedBox(height: 33),
          AdjustedArabicDisplay(
            text: _arabicHeader,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              fontSize: 36,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            _englishHeadline,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            "We're celebrating with you. Enjoy 7 days of full Sakina, on us.",
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: claiming ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: claiming
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : Text(
                      'Accept your gift',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).moveY(begin: 8, end: 0, duration: 400.ms);
  }
}

class _PostClaimStatus extends StatelessWidget {
  const _PostClaimStatus({required this.expiresAt});
  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat.yMMMMd().format(expiresAt.toLocal());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your Sakina gift is active until $formatted',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
