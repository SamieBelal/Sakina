import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/services/app_config_service.dart';

/// W2-E1 / review P2-5 — the reel kill switch on a FIRST install.
///
/// `AppConfigService.getBool` answers cache-or-fallback immediately, and
/// `main.dart`'s `primeCache` is fire-and-forget, so a cold cache reads the
/// `true` fallback: a REVERTED flag would still hand that launch the reel flow,
/// which is the one launch where the revert matters. `resolveOnboardingFlow`
/// therefore awaits one bounded fresh read of that ONE key — and only when
/// nothing is cached, so a normal launch pays nothing.
class _StubConfig extends AppConfigService {
  _StubConfig({
    required this.cached,
    required this.values,
    this.primeDelay = Duration.zero,
  }) : super.forTest();

  final bool cached;

  /// What `getBool` answers AFTER the prime completes; before that it answers
  /// the fallback, exactly as the cache-miss path does.
  final Map<String, bool> values;
  final Duration primeDelay;

  bool primed = false;
  int primeCalls = 0;

  @override
  Future<bool> hasCachedValue(String key) async => cached;

  @override
  Future<void> primeCache(List<String> keys) async {
    primeCalls++;
    await Future<void>.delayed(primeDelay);
    primed = true;
  }

  @override
  Future<bool> getBool(String key, {required bool fallback}) async {
    if (!cached && !primed) return fallback;
    return values[key] ?? fallback;
  }
}

void main() {
  test('a cold cache waits for the fresh read, then honours it', () async {
    final config = _StubConfig(
      cached: false,
      values: {
        reelFirstOnboardingFlag: false,
        'onboarding_trim_enabled': true,
      },
      primeDelay: const Duration(milliseconds: 20),
    );

    final flow = await resolveOnboardingFlow(
      config,
      freshReadTimeout: const Duration(seconds: 5),
    );

    expect(flow, OnboardingFlowKind.trimmed,
        reason: 'the reverted flag landed before the deadline, so this install '
            'must NOT get the reel flow');
    expect(config.primeCalls, 1);
  });

  test('a cold cache with a dead network falls back to reel after the timeout',
      () async {
    // Never completes: the flag read has to give up, not hang the screen on
    // an unresolved future.
    final hang = Completer<void>();
    addTearDown(hang.complete);
    final config = _HangingConfig(hang.future);

    final stopwatch = Stopwatch()..start();
    final flow = await resolveOnboardingFlow(
      config,
      freshReadTimeout: const Duration(milliseconds: 80),
    );
    stopwatch.stop();

    expect(flow, OnboardingFlowKind.reel,
        reason: 'reel is the documented fallback — the shipping experience');
    expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(70));
    expect(stopwatch.elapsedMilliseconds, lessThan(2000),
        reason: 'bounded by the timeout, not by the dead request');
  });

  test('a cached value decides immediately — no prime, no wait', () async {
    final config = _StubConfig(
      cached: true,
      values: {
        reelFirstOnboardingFlag: false,
        'onboarding_trim_enabled': false,
      },
      primeDelay: const Duration(seconds: 30),
    );

    final stopwatch = Stopwatch()..start();
    final flow = await resolveOnboardingFlow(config);
    stopwatch.stop();

    expect(flow, OnboardingFlowKind.legacy);
    expect(config.primeCalls, 0,
        reason: 'the normal cold launch must not pay for the probe');
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });

  test('a cached reel flag short-circuits the trim decision', () async {
    final config = _StubConfig(
      cached: true,
      values: {
        reelFirstOnboardingFlag: true,
        'onboarding_trim_enabled': false,
      },
    );

    expect(await resolveOnboardingFlow(config), OnboardingFlowKind.reel);
  });

  test('the default timeout is the shipping one', () {
    expect(reelFlagFreshReadTimeout, const Duration(seconds: 2));
  });

  test('a throwing config still resolves — the screen hangs off this future',
      () async {
    // The flow field, the `onboarding_flow` write and the funnel-entry events
    // all ride the continuation. An unresolved future means none of them ever
    // happen, which is strictly worse than answering with the fallback.
    expect(await resolveOnboardingFlow(_ThrowingConfig()),
        OnboardingFlowKind.reel);
  });
}

/// A config whose fresh read never returns and whose cache is empty.
class _HangingConfig extends AppConfigService {
  _HangingConfig(this.never) : super.forTest();

  final Future<void> never;

  @override
  Future<bool> hasCachedValue(String key) async => false;

  @override
  Future<void> primeCache(List<String> keys) => never;

  @override
  Future<bool> getBool(String key, {required bool fallback}) async => fallback;
}

/// Every read fails — a broken SharedPreferences plugin, say.
class _ThrowingConfig extends AppConfigService {
  _ThrowingConfig() : super.forTest();

  @override
  Future<bool> hasCachedValue(String key) async => throw StateError('no prefs');

  @override
  Future<void> primeCache(List<String> keys) async =>
      throw StateError('no prefs');

  @override
  Future<bool> getBool(String key, {required bool fallback}) async =>
      throw StateError('no prefs');
}
