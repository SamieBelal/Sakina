import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/cancellation_feedback_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

class _SpyAnalytics extends AnalyticsService {
  final List<({String event, Map<String, dynamic>? props})> tracked = [];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event: event, props: properties));
  }
}

/// Seeds a user_subscriptions row into the fake, mirroring what the webhook
/// upsert writes.
void _seedSubscription(
  FakeSupabaseSyncService fake, {
  required String userId,
  String entitlement = 'premium',
  String? canceledAt,
  String? billingIssueAt,
  String? expiresAt,
  String? periodType,
  String productId = 'sakina_annual',
  String store = 'app_store',
}) {
  fake.rowLists.putIfAbsent('user_subscriptions', () => []).add({
    'user_id': userId,
    'entitlement': entitlement,
    'canceled_at': canceledAt,
    'billing_issue_detected_at': billingIssueAt,
    'expires_at': expiresAt,
    'period_type': periodType,
    'product_id': productId,
    'store': store,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'user-1';
  final expires = DateTime.utc(2026, 6, 15, 10);
  final canceled = DateTime.utc(2026, 6, 1, 9);

  late FakeSupabaseSyncService fake;
  late _SpyAnalytics analytics;
  late CancellationFeedbackService service;

  setUp(() {
    fake = FakeSupabaseSyncService(userId: userId);
    SupabaseSyncService.debugSetInstance(fake);
    analytics = _SpyAnalytics();
    service = CancellationFeedbackService(sync: fake, analytics: analytics);
  });

  tearDown(SupabaseSyncService.debugReset);

  group('resolveReactiveCancellation', () {
    test('null when unauthenticated', () async {
      fake.userId = null;
      _seedSubscription(fake,
          userId: userId,
          canceledAt: canceled.toIso8601String(),
          expiresAt: expires.toIso8601String());
      expect(await service.resolveReactiveCancellation(), isNull);
    });

    test('null when there is no premium subscription row', () async {
      expect(await service.resolveReactiveCancellation(), isNull);
    });

    test('null when not cancelled (canceled_at null)', () async {
      _seedSubscription(fake,
          userId: userId, expiresAt: expires.toIso8601String());
      expect(await service.resolveReactiveCancellation(), isNull);
    });

    test('null for involuntary churn (billing issue set)', () async {
      _seedSubscription(fake,
          userId: userId,
          canceledAt: canceled.toIso8601String(),
          billingIssueAt: DateTime.utc(2026, 6, 2).toIso8601String(),
          expiresAt: expires.toIso8601String());
      expect(await service.resolveReactiveCancellation(), isNull);
    });

    test('null when expires_at is missing', () async {
      _seedSubscription(fake,
          userId: userId, canceledAt: canceled.toIso8601String());
      expect(await service.resolveReactiveCancellation(), isNull);
    });

    test('returns context for a voluntary cancellation', () async {
      _seedSubscription(fake,
          userId: userId,
          canceledAt: canceled.toIso8601String(),
          expiresAt: expires.toIso8601String(),
          periodType: 'trial');
      final ctx = await service.resolveReactiveCancellation();
      expect(ctx, isNotNull);
      expect(ctx!.expiresAt.isAtSameMomentAs(expires), isTrue);
      expect(ctx.canceledAt!.isAtSameMomentAs(canceled), isTrue);
      expect(ctx.periodType, 'trial');
      expect(ctx.isTrial, isTrue);
      expect(ctx.source, CancellationSource.inAppReactive);
      expect(ctx.productId, 'sakina_annual');
    });

    test('null when this episode was already surveyed', () async {
      _seedSubscription(fake,
          userId: userId,
          canceledAt: canceled.toIso8601String(),
          expiresAt: expires.toIso8601String());
      final ctx = await service.resolveReactiveCancellation();
      await service.submit(ctx!, reason: CancellationReason.tooExpensive);
      // Same episode → no re-prompt.
      expect(await service.resolveReactiveCancellation(), isNull);
    });
  });

  group('resolveUnsurveyed (instant/push paths)', () {
    CancellationContext candidate() => CancellationContext(
          expiresAt: expires,
          canceledAt: canceled,
          periodType: 'normal',
          source: CancellationSource.inAppInstant,
        );

    test('returns the context when not yet surveyed', () async {
      expect(await service.resolveUnsurveyed(candidate()), isNotNull);
    });

    test('null once surveyed for that episode', () async {
      await service.submit(candidate());
      expect(await service.resolveUnsurveyed(candidate()), isNull);
    });

    test('null when unauthenticated', () async {
      fake.userId = null;
      expect(await service.resolveUnsurveyed(candidate()), isNull);
    });
  });

  group('submit', () {
    CancellationContext ctx() => CancellationContext(
          expiresAt: expires,
          canceledAt: canceled,
          periodType: 'normal',
          productId: 'sakina_annual',
          store: 'app_store',
          source: CancellationSource.inAppInstant,
        );

    test('writes one submitted row with the composite onConflict key',
        () async {
      await service.submit(ctx(),
          reason: CancellationReason.notUsing, reasonText: '  too busy  ');

      final call = fake.upsertCalls.single;
      expect(call['table'], CancellationFeedbackService.table);
      expect(call['onConflict'], 'user_id,expires_at');
      final data = call['data'] as Map<String, dynamic>;
      expect(data['status'], 'submitted');
      expect(data['reason_code'], 'not_using');
      expect(data['reason_text'], 'too busy'); // trimmed
      expect(data['source'], 'in_app_instant');
      expect(data['period_type'], 'normal');

      final rows = fake.rowLists['cancellation_feedback']!;
      expect(rows, hasLength(1));
      expect(rows.single['user_id'], userId);
    });

    test('fires the submitted analytics event with properties', () async {
      await service.submit(ctx(),
          reason: CancellationReason.tooExpensive, reasonText: 'pricey');
      final ev = analytics.tracked.single;
      expect(ev.event, AnalyticsEvents.cancellationFeedbackSubmitted);
      expect(ev.props!['reason_code'], 'too_expensive');
      expect(ev.props!['has_text'], true);
      expect(ev.props!['source'], 'in_app_instant');
    });

    test('blank free-text stores null and reports has_text=false', () async {
      await service.submit(ctx(), reasonText: '   ');
      final data = fake.upsertCalls.single['data'] as Map<String, dynamic>;
      expect(data['reason_text'], isNull);
      expect(analytics.tracked.single.props!['has_text'], false);
    });

    test('reason and text are both optional (submit with nothing)', () async {
      await service.submit(ctx());
      final data = fake.upsertCalls.single['data'] as Map<String, dynamic>;
      expect(data['reason_code'], isNull);
      expect(data['reason_text'], isNull);
      expect(data['status'], 'submitted');
    });

    test('deduped to a single row for the same episode', () async {
      await service.submit(ctx(), reason: CancellationReason.tooExpensive);
      await service.submit(ctx(), reason: CancellationReason.other);
      expect(fake.rowLists['cancellation_feedback'], hasLength(1));
    });

    test('no write when unauthenticated', () async {
      fake.userId = null;
      await service.submit(ctx());
      expect(fake.upsertCalls, isEmpty);
    });
  });

  group('dismiss', () {
    test('writes a dismissed row with null reason', () async {
      await service.dismiss(CancellationContext(
        expiresAt: expires,
        source: CancellationSource.inAppReactive,
      ));
      final data = fake.upsertCalls.single['data'] as Map<String, dynamic>;
      expect(data['status'], 'dismissed');
      expect(data['reason_code'], isNull);
      expect(analytics.tracked.single.event,
          AnalyticsEvents.cancellationFeedbackDismissed);
    });

    test('a dismissed episode is not re-prompted', () async {
      _seedSubscription(fake,
          userId: userId,
          canceledAt: canceled.toIso8601String(),
          expiresAt: expires.toIso8601String());
      final ctx = await service.resolveReactiveCancellation();
      await service.dismiss(ctx!);
      expect(await service.resolveReactiveCancellation(), isNull);
    });
  });
}
