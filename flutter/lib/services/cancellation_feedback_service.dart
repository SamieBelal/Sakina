import 'package:flutter/foundation.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';
import 'supabase_sync_service.dart';

/// Structured cancellation reasons. The string [code] is the single source of
/// truth shared by the Supabase `reason_code` column and the Mixpanel property,
/// so the taxonomy can never drift between storage and analytics.
enum CancellationReason {
  tooExpensive('too_expensive'),
  notUsing('not_using'),
  missingFeature('missing_feature'),
  foundAlternative('found_alternative'),
  technicalIssues('technical_issues'),
  justBreak('just_break'),
  other('other');

  const CancellationReason(this.code);

  final String code;
}

/// How a cancellation was detected. Recorded on the feedback row so we can tell
/// instant (Customer Center) responses from reactive (next-open) and push ones.
enum CancellationSource {
  /// Detected right after the in-app Customer Center sheet closed.
  inAppInstant('in_app_instant'),

  /// Detected from the server row on a later app open.
  inAppReactive('in_app_reactive'),

  /// Reached via the cancellation push deep-link.
  push('push');

  const CancellationSource(this.value);

  final String value;
}

/// Everything needed to identify and describe a single cancellation episode.
/// [expiresAt] is the dedupe key — it is identical whether read from the
/// client `EntitlementInfo.expirationDate` (instant path) or the server
/// `user_subscriptions.expires_at` (reactive path), so both paths land on the
/// same `(user_id, expires_at)` row.
@immutable
class CancellationContext {
  const CancellationContext({
    required this.expiresAt,
    required this.source,
    this.canceledAt,
    this.periodType,
    this.productId,
    this.store,
  });

  final DateTime expiresAt;
  final CancellationSource source;
  final DateTime? canceledAt;
  final String? periodType;
  final String? productId;
  final String? store;

  bool get isTrial => periodType == 'trial';
}

/// Writes cancellation-feedback records and decides whether to prompt.
///
/// Detection is funnel-agnostic and deduped on the `(user_id, expires_at)`
/// episode key, so a cancellation is surveyed exactly once regardless of how
/// it was detected (instant after Customer Center, reactive on next open, or
/// via push). Billing-issue (involuntary) churn is never surveyed.
class CancellationFeedbackService {
  CancellationFeedbackService({
    SupabaseSyncService? sync,
    AnalyticsService? analytics,
  })  : _sync = sync ?? supabaseSyncService,
        _analytics = analytics ?? AnalyticsService();

  final SupabaseSyncService _sync;
  final AnalyticsService _analytics;

  static const String table = 'cancellation_feedback';

  /// Resolves a voluntary, not-yet-surveyed cancellation from the server
  /// `user_subscriptions` row (the source of truth for the reactive path).
  /// Returns null when there is nothing to survey.
  Future<CancellationContext?> resolveReactiveCancellation() async {
    final userId = _sync.currentUserId;
    if (userId == null) return null;

    final List<Map<String, dynamic>> rows;
    try {
      rows = await _sync.fetchRows('user_subscriptions', userId);
    } catch (_) {
      return null; // Fail closed: a query error must never block app open.
    }

    for (final row in rows) {
      if (row['entitlement'] != 'premium') continue;

      final canceledAt = _parseTime(row['canceled_at']);
      final billingIssueAt = _parseTime(row['billing_issue_detected_at']);
      final expiresAt = _parseTime(row['expires_at']);

      // Voluntary cancel only: canceled, not a billing failure, with a known
      // period end to key on.
      if (canceledAt == null || billingIssueAt != null || expiresAt == null) {
        continue;
      }

      if (await _alreadySurveyed(userId, expiresAt)) continue;

      return CancellationContext(
        expiresAt: expiresAt,
        canceledAt: canceledAt,
        periodType: row['period_type'] as String?,
        productId: row['product_id'] as String?,
        store: row['store'] as String?,
        source: CancellationSource.inAppReactive,
      );
    }
    return null;
  }

  /// For the instant (Customer Center) and push paths, where the caller already
  /// has a candidate [context]: returns it only if that episode has not been
  /// surveyed yet, otherwise null.
  Future<CancellationContext?> resolveUnsurveyed(
    CancellationContext context,
  ) async {
    final userId = _sync.currentUserId;
    if (userId == null) return null;
    if (await _alreadySurveyed(userId, context.expiresAt)) return null;
    return context;
  }

  /// Records a completed survey. [reason] and [reasonText] are both optional.
  Future<void> submit(
    CancellationContext context, {
    CancellationReason? reason,
    String? reasonText,
  }) async {
    await _write(
      context,
      status: 'submitted',
      reason: reason,
      reasonText: reasonText,
    );

    _analytics.track(
      AnalyticsEvents.cancellationFeedbackSubmitted,
      properties: <String, dynamic>{
        'reason_code': reason?.code,
        'period_type': context.periodType,
        'has_text': (reasonText != null && reasonText.trim().isNotEmpty),
        'source': context.source.value,
        'is_trial': context.isTrial,
      },
    );
  }

  /// Records that the user skipped the survey, so we never re-ask for this
  /// episode.
  Future<void> dismiss(CancellationContext context) async {
    await _write(context, status: 'dismissed');
    _analytics.track(
      AnalyticsEvents.cancellationFeedbackDismissed,
      properties: <String, dynamic>{
        'period_type': context.periodType,
        'source': context.source.value,
      },
    );
  }

  Future<void> _write(
    CancellationContext context, {
    required String status,
    CancellationReason? reason,
    String? reasonText,
  }) async {
    final userId = _sync.currentUserId;
    if (userId == null) return;

    final trimmed = reasonText?.trim();
    try {
      // upsert on the composite episode key. Naming the conflict columns
      // explicitly is mandatory — the SDK otherwise defaults to PK-conflict
      // resolution, inserts a fresh uuid, hits the unique violation, and
      // silently fails.
      await _sync.upsertRow(
        table,
        userId,
        <String, dynamic>{
          'expires_at': _episodeKey(context.expiresAt).toIso8601String(),
          'canceled_at': context.canceledAt?.toUtc().toIso8601String(),
          'reason_code': reason?.code,
          'reason_text': (trimmed != null && trimmed.isNotEmpty) ? trimmed : null,
          'period_type': context.periodType,
          'product_id': context.productId,
          'store': context.store,
          'platform': _platform,
          'source': context.source.value,
          'status': status,
        },
        onConflict: 'user_id,expires_at',
      );
    } catch (_) {
      // Feedback must never interrupt or error in the user's face.
    }
  }

  Future<bool> _alreadySurveyed(String userId, DateTime expiresAt) async {
    final List<Map<String, dynamic>> rows;
    try {
      rows = await _sync.fetchRows(table, userId);
    } catch (_) {
      // On a read failure, assume surveyed → fail closed, never double-prompt.
      return true;
    }
    final target = _episodeKey(expiresAt);
    for (final row in rows) {
      final rowExpires = _parseTime(row['expires_at']);
      if (rowExpires != null && _episodeKey(rowExpires).isAtSameMomentAs(target)) {
        return true;
      }
    }
    return false;
  }

  /// Normalizes an expiration timestamp to a whole-second UTC instant — the
  /// dedupe key. The instant path reads `expirationDate` (client) and the
  /// reactive path reads `expires_at` (server); they describe the same period
  /// end but could differ by sub-second jitter. Truncating to the second makes
  /// the "survey exactly once" invariant robust to that jitter, both for the
  /// stored value (so the DB unique constraint collides) and the local check.
  static DateTime _episodeKey(DateTime dt) {
    final utc = dt.toUtc();
    return DateTime.fromMillisecondsSinceEpoch(
      (utc.millisecondsSinceEpoch ~/ 1000) * 1000,
      isUtc: true,
    );
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static String get _platform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return defaultTargetPlatform.name;
    }
  }
}
