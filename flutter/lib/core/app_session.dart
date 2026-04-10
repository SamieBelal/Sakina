import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/achievements_service.dart';
import '../services/auth_service.dart';
import '../services/daily_usage_service.dart';
import '../features/daily/providers/daily_question_provider.dart';
import '../features/discovery/providers/discovery_quiz_provider.dart';
import '../features/quests/providers/quests_provider.dart';
import '../services/supabase_sync_service.dart';
import '../services/user_data_batch_sync_service.dart';

/// Single source of truth for auth + onboarding state.
/// Used as GoRouter's refreshListenable — redirect reads from this.
class AppSessionNotifier extends ChangeNotifier {
  AppSessionNotifier({
    AuthService? authService,
    required bool initialOnboarded,
    Stream<AuthState>? authStateChanges,
    bool Function()? isAuthenticatedProvider,
    Future<void> Function()? hydrateEconomyCache,
    Future<bool> Function()? hasCompletedOnboarding,
    Future<void> Function()? syncFirstStepsCache,
  })  : _hasOnboarded = initialOnboarded,
        _isAuthenticatedProvider = isAuthenticatedProvider ??
            (() => Supabase.instance.client.auth.currentUser != null),
        _hydrateEconomyCache = hydrateEconomyCache ??
            (() => _defaultHydrate(
                  syncFirstStepsCache:
                      syncFirstStepsCache ?? syncFirstStepsFromSupabase,
                )),
        _hasCompletedOnboarding = hasCompletedOnboarding ??
            authService?.hasCompletedOnboarding ??
            (() async => false) {
    _subscription =
        (authStateChanges ?? Supabase.instance.client.auth.onAuthStateChange)
            .listen(_onAuthChange);
  }

  late final StreamSubscription<AuthState> _subscription;
  final bool Function() _isAuthenticatedProvider;
  final Future<void> Function() _hydrateEconomyCache;
  final Future<bool> Function() _hasCompletedOnboarding;
  bool _hasOnboarded;

  bool get isAuthenticated => _isAuthenticatedProvider();
  bool get hasOnboarded => _hasOnboarded;

  /// `true` while an economy hydration is in flight.
  bool _hydrating = false;

  /// Whether the economy cache has been hydrated at least once this session.
  bool get economyHydrated => _economyHydrated;
  bool _economyHydrated = false;

  void _onAuthChange(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.tokenRefreshed:
        if (isAuthenticated) {
          unawaited(_hydrateAndNotify());
        }
        if (isAuthenticated && !_hasOnboarded) {
          unawaited(_checkOnboardingStatus());
        }
        notifyListeners();
        break;
      case AuthChangeEvent.signedOut:
        _hasOnboarded = false;
        _economyHydrated = false;
        notifyListeners();
        break;
      default:
        notifyListeners();
        break;
    }
  }

  Future<void> _hydrateAndNotify() async {
    if (_hydrating) return; // Avoid overlapping hydrations
    _hydrating = true;
    try {
      await _hydrateEconomyCache();
      _economyHydrated = true;
      notifyListeners(); // Kick providers to re-read fresh cache
    } finally {
      _hydrating = false;
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final onboarded = await _hasCompletedOnboarding();
    if (onboarded && !_hasOnboarded) {
      _hasOnboarded = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      notifyListeners();
    }
  }

  /// Await this after sign-in to ensure hasOnboarded is resolved before navigating.
  Future<void> ensureOnboardingChecked() async {
    if (!isAuthenticated) return;
    if (_hasOnboarded) return;
    final onboarded = await _hasCompletedOnboarding();
    if (onboarded) {
      _hasOnboarded = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      notifyListeners();
    }
  }

  /// Called when a new user finishes onboarding (paywall dismiss).
  /// Sets local + in-memory flag; server flag is already set by saveOnboardingData().
  Future<void> markOnboarded() async {
    _hasOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    notifyListeners();
  }

  /// Called on sign-out or account deletion to clear local cache.
  /// [userId] must be captured BEFORE signOut() — after sign-out the auth
  /// user is null and scoped keys can't be resolved.
  Future<void> clearSession({String? userId}) async {
    _hasOnboarded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');

    // Clear user-scoped SharedPreferences keys to prevent cross-user data bleed.
    final uid = userId ?? supabaseSyncService.currentUserId;
    if (uid != null) {
      final allKeys = prefs.getKeys();
      final scopedSuffix = ':$uid';
      for (final key in allKeys) {
        if (key.endsWith(scopedSuffix)) {
          await prefs.remove(key);
        }
      }
    }
    // Don't call notifyListeners() — the auth stream's signedOut event will do that
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appSessionProvider = Provider<AppSessionNotifier>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

// ---------------------------------------------------------------------------
// Default hydration path
//
// Hydrates Wave 1-2 via the batch RPC, then runs the remaining Wave 3-4
// sync paths separately.
// ---------------------------------------------------------------------------

Future<void> _defaultHydrate({
  required Future<void> Function() syncFirstStepsCache,
}) async {
  await Future.wait([
    hydrateUserDataFromBatchRpc(),
    // Wave 3: First Steps eligibility + completion
    syncFirstStepsCache(),
    // Wave 4: Engagement systems
    syncAchievementsCacheFromSupabase(),
    syncDiscoveryResultsFromSupabase(),
    syncDailyUsageFromSupabase(),
    syncDailyAnswersFromSupabase(),
    syncQuestProgressFromSupabase(),
  ]);
}
