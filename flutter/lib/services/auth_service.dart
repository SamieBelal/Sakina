import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sakina/core/env.dart';
import 'package:sakina/services/starter_name_cache.dart';
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

  // Default written to `user_profiles.display_name` when onboarding state
  // has no usable name. Without this, the column persisted null for a
  // handful of users and their push notifications rendered the literal
  // word "Sakina" (the app name) as the greeting — see OneSignal history
  // from 2026-05-19 onward. English fallback chosen so the greeting reads
  // naturally in both LTR and RTL layouts.
  static const String defaultDisplayName = 'Friend';

  static String resolveDisplayName(String? name) {
    if (name == null) return defaultDisplayName;
    final trimmed = name.trim();
    return trimmed.isEmpty ? defaultDisplayName : trimmed;
  }

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
    int? starterNameId,
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
      'display_name': resolveDisplayName(displayName),
      'onboarding_intention': intention,
      'onboarding_familiarity': familiarity,
      'onboarding_quran_connection': quranConnection,
      'onboarding_attribution': attribution,
      'age_range': ageRange,
      'prayer_frequency': prayerFrequency,
      'starter_name_id': starterNameId,
      'dua_topics': duaTopics,
      'dua_topics_other': duaTopicsOther,
      'common_emotions': commonEmotions,
      'aspirations': aspirations,
      'daily_commitment_minutes': dailyCommitmentMinutes,
      'reminder_time': reminderTime,
      'commitment_accepted': commitmentAccepted,
    }).eq('id', userId);
  }

  /// Seed the user's collection with the starter Name they got from the
  /// first check-in. Check-then-insert pattern so we don't depend on a
  /// specific named unique constraint in the schema (older dev DBs may have
  /// only the index, not the constraint, which makes `onConflict` upserts
  /// fail). The user_id+name_id read is RLS-safe.
  ///
  /// Also writes the catalog id to a scoped SharedPreferences key so the
  /// home greeting can render the starter Name synchronously without waiting
  /// for the next Supabase round-trip (the previous behavior caused a
  /// noticeable "today's Name" flicker on the day-0 home greeting).
  Future<void> seedStarterCard(int nameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final existing = await _supabase
        .from('user_card_collection')
        .select('id')
        .eq('user_id', userId)
        .eq('name_id', nameId)
        .maybeSingle();
    if (existing == null) {
      await _supabase.from('user_card_collection').insert({
        'user_id': userId,
        'name_id': nameId,
        'tier': 'bronze',
      });
    }
    await writeCachedStarterNameId(nameId);
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
