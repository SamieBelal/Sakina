import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/paywall_experiment.dart';
import 'package:sakina/features/paywall/reverse_trial_onboarding.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

const MethodChannel _channel = MethodChannel('purchases_flutter');

class _SpyAnalytics extends AnalyticsService {
  final events = <({String event, Map<String, dynamic>? props})>[];
  final superProps = <String, dynamic>{};
  final userProps = <String, dynamic>{};

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      events.add((event: event, props: properties));
  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      superProps.addAll(props);
  @override
  void setUserProperties(Map<String, dynamic> props) => userProps.addAll(props);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _SpyAnalytics analytics;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    analytics = _SpyAnalytics();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (_) async => null);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('experiment OFF → no arm assigned, no trial, no events', () async {
    await resolveAndApplyPaywallExperiment(
      experimentEnabled: false,
      userId: 'user-1',
      analytics: analytics,
    );
    expect(analytics.events, isEmpty);
    expect(fakeSync.rpcCalls.where((c) => c['fn'] == 'activate_trial'),
        isEmpty);
    // No arm super-property set for a pre-flag user.
    expect(analytics.superProps[AnalyticsEvents.paywallExpArm], isNull);
  });

  group('experiment ON', () {
    // Force a known arm by picking user ids that bucket to each side.
    String controlId() {
      for (var i = 0;; i++) {
        final id = 'ctl-$i';
        if (assignPaywallArm(id) == PaywallArm.controlNoTrial) return id;
      }
    }

    String treatmentId() {
      for (var i = 0;; i++) {
        final id = 'trt-$i';
        if (assignPaywallArm(id) == PaywallArm.treatmentReverseTrial) return id;
      }
    }

    test('CONTROL arm → records arm + experiment_assigned, NO trial RPC',
        () async {
      final id = controlId();
      fakeSync.userId = id;
      await resolveAndApplyPaywallExperiment(
        experimentEnabled: true,
        userId: id,
        analytics: analytics,
      );

      expect(analytics.superProps[AnalyticsEvents.paywallExpArm],
          'control_no_trial');
      expect(analytics.userProps[AnalyticsEvents.paywallExpArm],
          'control_no_trial');
      final assigned = analytics.events
          .where((e) => e.event == AnalyticsEvents.experimentAssigned)
          .toList();
      expect(assigned, hasLength(1));
      expect(assigned.single.props?[AnalyticsEvents.propArm], 'control_no_trial');
      expect(assigned.single.props?['experiment'], 'reverse_trial');
      // Control gets NO trial.
      expect(fakeSync.rpcCalls.where((c) => c['fn'] == 'activate_trial'),
          isEmpty);
      expect(
          analytics.events.where((e) => e.event == AnalyticsEvents.trialActivated),
          isEmpty);
    });

    test('TREATMENT arm → calls activate_trial(3) + fires trial_activated',
        () async {
      final id = treatmentId();
      fakeSync.userId = id;
      fakeSync.rpcHandlers['activate_trial'] =
          (params) async => {'ok': true};

      await resolveAndApplyPaywallExperiment(
        experimentEnabled: true,
        userId: id,
        analytics: analytics,
      );

      expect(analytics.superProps[AnalyticsEvents.paywallExpArm],
          'treatment_reverse_trial');
      final rpc = fakeSync.rpcCalls
          .where((c) => c['fn'] == 'activate_trial')
          .toList();
      expect(rpc, hasLength(1), reason: 'treatment activates the 3-day trial');
      expect((rpc.single['params'] as Map)['p_days'], 3,
          reason: 'trial length is hardcoded 3 days');

      final activated = analytics.events
          .where((e) => e.event == AnalyticsEvents.trialActivated)
          .toList();
      expect(activated, hasLength(1));
      expect(activated.single.props?[AnalyticsEvents.propDays], 3);
      expect(activated.single.props?[AnalyticsEvents.propArm],
          'treatment_reverse_trial');
      expect(activated.single.props?['source'], 'reverse_trial');
    });

    test(
        'TREATMENT arm: a hung activate_trial RPC times out, degrades to '
        'routing home (no trial_activated), and does not block (P2)', () async {
      final id = treatmentId();
      fakeSync.userId = id;
      // Simulate a hung network: the RPC future NEVER completes, so the only way
      // the hook returns is the 4s `.timeout` degrade path. A never-completing
      // Completer (vs. a long Future.delayed) leaves no leftover timer to leak.
      final hung = Completer<Map<String, dynamic>>();
      addTearDown(() {
        if (!hung.isCompleted) hung.complete({'ok': true});
      });
      fakeSync.rpcHandlers['activate_trial'] = (params) => hung.future;

      // The hook must return on its own (routed home) despite the hung RPC.
      // Bound the wait so a regression that re-blocks fails loudly instead of
      // hanging the suite. The internal timeout is 4s; allow generous slack.
      await resolveAndApplyPaywallExperiment(
        experimentEnabled: true,
        userId: id,
        analytics: analytics,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => fail(
            'a hung activate_trial must not stall onboarding routing (P2)'),
      );

      // The RPC was still issued (background activation continues server-side)…
      expect(fakeSync.rpcCalls.where((c) => c['fn'] == 'activate_trial'),
          hasLength(1));
      // …but trial_activated did NOT fire on the degrade path (premium is
      // picked up by refreshTrialPremiumCache on the next read instead).
      expect(
          analytics.events.where((e) => e.event == AnalyticsEvents.trialActivated),
          isEmpty);
      // The experiment was still assigned (denominator intact).
      expect(
          analytics.events
              .where((e) => e.event == AnalyticsEvents.experimentAssigned),
          hasLength(1));
    });

    test('idempotent: a second call does NOT re-fire experiment_assigned (G1)',
        () async {
      final id = treatmentId();
      fakeSync.userId = id;
      fakeSync.rpcHandlers['activate_trial'] = (params) async => {'ok': true};

      await resolveAndApplyPaywallExperiment(
        experimentEnabled: true,
        userId: id,
        analytics: analytics,
      );
      await resolveAndApplyPaywallExperiment(
        experimentEnabled: true,
        userId: id,
        analytics: analytics,
      );

      expect(
        analytics.events
            .where((e) => e.event == AnalyticsEvents.experimentAssigned),
        hasLength(1),
        reason: 'experiment_assigned dedupes on a stored flag across re-onboard',
      );
      // And the trial isn't re-activated on the second pass.
      expect(fakeSync.rpcCalls.where((c) => c['fn'] == 'activate_trial'),
          hasLength(1));
    });
  });
}
