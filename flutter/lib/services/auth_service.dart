import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sakina/core/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// F3 fix (2026-04-26): clears all SharedPreferences keys scoped to the given
/// user. supabase_sync_service writes scoped keys with the suffix `:<uid>`;
/// this mirrors that contract. Cross-user safety is preserved by the suffix
/// so this only ever removes keys belonging to the signing-out user. Top
/// level so it can be unit-tested without instantiating an AuthService.
Future<int> clearScopedPreferencesForUser(
    SharedPreferences prefs, String userId) async {
  if (userId.isEmpty) return 0;
  final suffix = ':$userId';
  final scopedKeys =
      prefs.getKeys().where((k) => k.endsWith(suffix)).toList(growable: false);
  for (final key in scopedKeys) {
    await prefs.remove(key);
  }
  return scopedKeys.length;
}

class AuthService {
  late final _supabase = Supabase.instance.client;

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Could not find ID Token from Apple credential.');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Apple only provides the user's name on the FIRST authorization.
    // It's on the credential object (not in the ID token), so we must
    // capture it here and persist it to Supabase user metadata.
    final givenName = credential.givenName;
    final familyName = credential.familyName;
    if (givenName != null || familyName != null) {
      final fullName = [givenName, familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      if (fullName.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
      }
    }

    return response;
  }

  Future<AuthResponse> signInWithGoogle() async {
    const webClientId = Env.googleWebClientId;
    const iosClientId = Env.googleIosClientId;

    if (webClientId.isEmpty || (Platform.isIOS && iosClientId.isEmpty)) {
      throw const AuthException(
        'Google Sign-In is not configured. Missing client ID.',
      );
    }

    final googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS ? iosClientId : null,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('No ID Token found.');
    }

    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> saveOnboardingData({
    String? displayName,
    String? intention,
    String? familiarity,
    String? quranConnection,
    List<String> attribution = const [],
    String? ageRange,
    String? prayerFrequency,
    String? resonantNameId,
    List<String> duaTopics = const [],
    String? duaTopicsOther,
    List<String> commonEmotions = const [],
    List<String> aspirations = const [],
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool commitmentAccepted = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('user_profiles').update({
      if (displayName != null && displayName.isNotEmpty)
        'display_name': displayName,
      'onboarding_intention': intention,
      'onboarding_familiarity': familiarity,
      'onboarding_quran_connection': quranConnection,
      'onboarding_attribution': attribution,
      'age_range': ageRange,
      'prayer_frequency': prayerFrequency,
      'resonant_name_id': resonantNameId,
      'dua_topics': duaTopics,
      'dua_topics_other': duaTopicsOther,
      'common_emotions': commonEmotions,
      'aspirations': aspirations,
      'daily_commitment_minutes': dailyCommitmentMinutes,
      'reminder_time': reminderTime,
      'commitment_accepted': commitmentAccepted,
    }).eq('id', userId);
  }

  Future<void> markOnboardingCompleted() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('user_profiles')
        .update({'onboarding_completed': true}).eq('id', userId);
  }

  /// Returns `true` if the current user has completed onboarding.
  /// Returns `false` if there is no profile row or onboarding is incomplete.
  Future<bool> hasCompletedOnboarding() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final row = await _supabase
        .from('user_profiles')
        .select('onboarding_completed')
        .eq('id', userId)
        .maybeSingle();

    return row?['onboarding_completed'] == true;
  }

  Future<void> signOut() async {
    // Capture uid BEFORE signOut — afterwards currentUser is null.
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.auth.signOut();
    if (userId != null && userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await clearScopedPreferencesForUser(prefs, userId);
    }
  }

  Future<void> deleteAccount() async {
    await _supabase.rpc('delete_own_account');
  }

  bool get isSignedIn => _supabase.auth.currentUser != null;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
