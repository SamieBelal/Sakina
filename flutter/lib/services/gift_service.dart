import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_sync_service.dart';

/// Outcome of a [GiftService.claim] call.
///
/// `granted=true` paths carry both `expiresAt` (authoritative server value,
/// preserved verbatim — NOT recomputed client-side) and `reused`, which is
/// true when the user had already claimed this occasion and we're returning
/// the existing grant (idempotent).
///
/// `granted=false` paths carry a `reason`: `outside_window`,
/// `unknown_occasion`, `unauthorized`, or `unknown` (parse failure).
@immutable
class GiftClaim {
  const GiftClaim._({
    required this.granted,
    this.expiresAt,
    this.reused = false,
    this.reason,
  });

  const GiftClaim.granted({
    required DateTime expiresAt,
    required bool reused,
  }) : this._(granted: true, expiresAt: expiresAt, reused: reused);

  const GiftClaim.denied({required String reason})
      : this._(granted: false, reason: reason);

  final bool granted;
  final DateTime? expiresAt;
  final bool reused;
  final String? reason;
}

/// SharedPreferences base key for the cached gift-window expiry. Scoped per
/// user via [SupabaseSyncService.scopedKey] so a sign-out + sign-in as a
/// different user cannot inherit the previous user's window.
const String giftPremiumUntilPrefsBaseKey = 'gift_premium_until';

/// Client wrapper around the `claim_sakina_gift` SECURITY DEFINER RPC.
///
/// Responsibilities:
///
/// 1. Proxy the RPC and decode its jsonb payload to a typed [GiftClaim].
/// 2. Mirror the server-returned `expires_at` to a user-scoped
///    SharedPreferences key so [PurchaseService] can read the gift window
///    on cold launch without a network round-trip.
/// 3. Resolve "what occasion bracket are we in?" by reading
///    `islamic_occasions` and comparing against [debugGiftClock].
class GiftService {
  GiftService();

  /// Test seam — replace via `GiftService.debugGiftClock = ...` to drive
  /// occasion lookup + expiry checks at deterministic UTC instants.
  /// Mirrors `debugRewardsClock` (daily_rewards_service.dart) and
  /// `debugLaunchGateClock` (launch_gate_state.dart) per CLAUDE.md.
  ///
  /// Production callers always read `DateTime.now().toUtc()`. All occasion
  /// boundary checks use UTC so the seam agrees with server `now()` and
  /// the user_profiles.gift_premium_until column written by the SQL RPC.
  @visibleForTesting
  static DateTime Function() debugGiftClock = () => DateTime.now().toUtc();

  /// Calls the `claim_sakina_gift` RPC for the given occasion. On success
  /// (`granted=true`), persists the returned `expires_at` to a user-scoped
  /// SharedPreferences key so `PurchaseService._isGiftPremium()` can read
  /// the window without a network round-trip on subsequent launches.
  ///
  /// Returns a typed [GiftClaim] regardless of outcome. Server-returned
  /// `expiresAt` is preserved verbatim (no client-side recomputation —
  /// the server is the clock authority for entitlement windows).
  Future<GiftClaim> claim(String occasionId) async {
    final userId = supabaseSyncService.currentUserId;
    if (userId == null || userId.isEmpty) {
      return const GiftClaim.denied(reason: 'unauthorized');
    }

    final response = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'claim_sakina_gift',
      {'p_user': userId, 'p_occasion': occasionId},
    );
    if (response == null) {
      // RPC swallowed an error (network / Postgres). Treat as unknown so
      // the UI can retry next launch.
      return const GiftClaim.denied(reason: 'unknown');
    }

    final granted = response['granted'] == true;
    if (!granted) {
      final reason = response['reason'] as String? ?? 'unknown';
      return GiftClaim.denied(reason: reason);
    }

    final rawExpires = response['expires_at'];
    if (rawExpires is! String) {
      return const GiftClaim.denied(reason: 'unknown');
    }
    final expiresAt = DateTime.tryParse(rawExpires)?.toUtc();
    if (expiresAt == null) {
      return const GiftClaim.denied(reason: 'unknown');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(giftPremiumUntilPrefsBaseKey),
      expiresAt.toIso8601String(),
    );

    final reused = response['reused'] == true;
    return GiftClaim.granted(expiresAt: expiresAt, reused: reused);
  }

  /// Returns the id of whichever occasion brackets [debugGiftClock] (i.e.
  /// `starts_at <= now <= ends_at`), or null if the clock falls outside
  /// every seeded occasion's window.
  ///
  /// Reads `islamic_occasions` via [SupabaseSyncService.fetchPublicRows]
  /// — the table has a public-read RLS policy, so anon access is fine.
  ///
  /// Per CEO/eng feedback: the client checks the window only to decide
  /// whether to RENDER the gift card; the SQL RPC re-validates the window
  /// server-side at claim time. A client-clock skew at most causes the
  /// card to render or not render — never grants an out-of-window claim.
  Future<String?> currentOccasion() async {
    final rows = await supabaseSyncService.fetchPublicRows(
      'islamic_occasions',
      columns: 'id,starts_at,ends_at',
      orderBy: 'starts_at',
      ascending: true,
    );
    final now = debugGiftClock();
    for (final row in rows) {
      final startsAt = DateTime.tryParse(row['starts_at'] as String? ?? '')
          ?.toUtc();
      final endsAt = DateTime.tryParse(row['ends_at'] as String? ?? '')
          ?.toUtc();
      if (startsAt == null || endsAt == null) continue;
      if (!now.isBefore(startsAt) && !now.isAfter(endsAt)) {
        return row['id'] as String?;
      }
    }
    return null;
  }

  /// Looks up the locally cached expiry from SharedPreferences. Returns
  /// null when no claim has been made by the current user. Used by both
  /// the home card (to choose pre-claim vs. post-claim rendering) and
  /// [PurchaseService._isGiftPremium].
  Future<DateTime?> cachedExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      supabaseSyncService.scopedKey(giftPremiumUntilPrefsBaseKey),
    );
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}

/// Singleton getter mirroring the rest of the service layer. Tests can
/// construct their own `GiftService()` instance — the class holds no
/// mutable state besides the static [GiftService.debugGiftClock] seam.
final GiftService giftService = GiftService();
