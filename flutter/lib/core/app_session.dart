import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/launch_gate_service.dart';
import '../services/notification_service.dart';
import '../services/streak_service.dart';
import '../services/supabase_sync_service.dart';
import '../services/user_data_batch_sync_service.dart';

/// Single source of truth for auth + onboarding state.
/// Used as GoRouter's refreshListenable — redirect reads from this.
class AppSessionNotifier extends ChangeNotifier {
  AppSessionNotifier({
    AuthService? authService,
    NotificationService? notificationService,
    required bool initialOnboarded,
    Stream<AuthState>? authStateChanges,
    bool Function()? isAuthenticatedProvider,
    Future<void> Function()? hydrateEconomyCache,
    Future<bool> Function()? hasCompletedOnboarding,
    Duration? hydrationTimeout,
  })  : _hasOnboarded = initialOnboarded,
        _notificationService = notificationService ?? NotificationService(),
        _isAuthenticatedProvider = isAuthenticatedProvider ??
            (() => Supabase.instance.client.auth.currentUser != null),
        _hydrateEconomyCache = hydrateEconomyCache ?? _defaultHydrate,
        _hasCompletedOnboarding = hasCompletedOnboarding ??
            authService?.hasCompletedOnboarding ??
            (() async => false),
        _hydrationTimeout = hydrationTimeout ?? const Duration(seconds: 30) {
    _subscription =
        (authStateChanges ?? Supabase.instance.client.auth.onAuthStateChange)
            .listen(_onAuthChange);
  }

  late final StreamSubscription<AuthState> _subscription;
  final NotificationService _notificationService;
  final bool Function() _isAuthenticatedProvider;
  final Future<void> Function() _hydrateEconomyCache;
  final Future<bool> Function() _hasCompletedOnboarding;
  final Duration _hydrationTimeout;
  bool _hasOnboarded;

  bool get isAuthenticated => _isAuthenticatedProvider();
  bool get hasOnboarded => _hasOnboarded;

  /// `true` while an economy hydration is in flight.
  bool _hydrating = false;

  /// Whether the economy cache has been hydrated at least once this session.
  bool get economyHydrated => _economyHydrated;
  bool _economyHydrated = false;

  /// Whether the last hydration attempt failed or timed out.
  bool get hydrationFailed => _hydrationFailed;
  bool _hydrationFailed = false;

  void _onAuthChange(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.tokenRefreshed:
        if (isAuthenticated) {
          unawaited(_handleAuthenticatedChange(data));
        }
        if (isAuthenticated && !_hasOnboarded) {
          unawaited(_checkOnboardingStatus());
        }
        notifyListeners();
        break;
      case AuthChangeEvent.signedOut:
        unawaited(_notificationService.logout());
        _hasOnboarded = false;
        _economyHydrated = false;
        _hydrationFailed = false;
        notifyListeners();
        break;
      default:
        notifyListeners();
        break;
    }
  }

  Future<void> _handleAuthenticatedChange(AuthState data) async {
    var shouldRefreshNotificationTags = true;
    final userId = data.session?.user.id;

    if (userId != null && userId.isNotEmpty) {
      try {
        await _notificationService.identifyUser(userId);
      } catch (_) {
        shouldRefreshNotificationTags = false;
      }
    }

    await _hydrateAndNotify(
      refreshNotificationTags: shouldRefreshNotificationTags,
    );
  }

  Future<void> _hydrateAndNotify({
    bool refreshNotificationTags = true,
  }) async {
    if (_hydrating) return; // Avoid overlapping hydrations
    _hydrating = true;
    _hydrationFailed = false;
    try {
      await _hydrateEconomyCache().timeout(
        _hydrationTimeout,
        onTimeout: () => throw TimeoutException(
          'Economy hydration timed out',
          _hydrationTimeout,
        ),
      );
      _economyHydrated = true;
      if (refreshNotificationTags) {
        await _refreshNotificationTags();
      }
    } catch (_) {
      _hydrationFailed = true;
    } finally {
      _hydrating = false;
      notifyListeners(); // Kick providers to re-read fresh cache / failure UI
    }
  }

  /// Manually retry hydration after an error or timeout.
  Future<void> retryHydration() async {
    if (_hydrating || !_hydrationFailed) return;
    await _hydrateAndNotify();
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

  Future<void> _refreshNotificationTags() async {
    try {
      final streak = await getStreak();
      final lastCheckinDate = streak.lastActive == null
          ? null
          : DateTime.tryParse(streak.lastActive!);

      await _notificationService.refreshSessionTags(
        streakCount: streak.currentStreak,
        lastCheckinDate: lastCheckinDate,
      );
    } catch (_) {
      // Non-critical — session hydration should not fail because tag sync failed.
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
    resetLaunchGateSessionState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await prefs.remove('onboarding_state');

    // Clear user-scoped SharedPreferences keys to prevent cross-user data bleed.
    final uid = userId ?? supabaseSyncService.currentUserId;
    if (uid != null) {
      final allKeys = prefs.getKeys().toList();
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
// Hydrates batched user data via the batch RPC.
// ---------------------------------------------------------------------------

Future<void> _defaultHydrate() async {
  await hydrateUserDataFromBatchRpc();
}
