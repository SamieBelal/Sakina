import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Single source of truth for auth + onboarding state.
/// Used as GoRouter's refreshListenable — redirect reads from this.
class AppSessionNotifier extends ChangeNotifier {
  AppSessionNotifier({
    required AuthService authService,
    required bool initialOnboarded,
  })  : _authService = authService,
        _hasOnboarded = initialOnboarded {
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(_onAuthChange);
  }

  final AuthService _authService;
  late final StreamSubscription<AuthState> _subscription;
  bool _hasOnboarded;

  bool get isAuthenticated => Supabase.instance.client.auth.currentUser != null;
  bool get hasOnboarded => _hasOnboarded;

  void _onAuthChange(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.tokenRefreshed:
        if (data.session != null && !_hasOnboarded) {
          _checkOnboardingStatus();
        }
        notifyListeners();
      case AuthChangeEvent.signedOut:
        _hasOnboarded = false;
        notifyListeners();
      default:
        notifyListeners();
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final onboarded = await _authService.hasCompletedOnboarding();
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
    final onboarded = await _authService.hasCompletedOnboarding();
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
  Future<void> clearSession() async {
    _hasOnboarded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
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
