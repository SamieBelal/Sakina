import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sakina/core/env.dart';
import 'package:sakina/services/starter_name_cache.dart';
import 'package:sakina/services/widget_data_service.dart';
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

/// Outcome of [performSignUpWithRecovery].
enum SignUpOutcome {
  /// signUp succeeded and the response carried a live session.
  created,

  /// signUp resolved without a session, and a password sign-in for the
  /// just-created account established one.
  recoveredViaSignIn,

  /// The email already has an account. We do NOT sign in or touch it — signing
  /// in would let a returning user's onboarding run overwrite their existing
  /// profile (violating the "don't affect current users" rule). The screen
  /// shows an honest "log in instead" message.
  emailAlreadyRegistered,

  /// Could not establish a session — surfaced to the user with [errorMessage].
  failed,
}

class SignUpResult {
  const SignUpResult(this.outcome, {this.userId, this.errorMessage, this.errorCode});
  final SignUpOutcome outcome;
  final String? userId;

  /// Human-readable auth error to show the user when [outcome] is [failed].
  /// Null for a session-race failure with no underlying auth error.
  final String? errorMessage;

  /// The gotrue [AuthException.code], when [outcome] is [failed] from an auth
  /// error. Used to map to a bounded analytics reason; null otherwise.
  final String? errorCode;
}

/// Substring used as a last-resort match when an older gotrue backend reports
/// "email already registered" without setting the typed [AuthException.code].
/// Best-effort only — the typed `user_already_exists` code is the primary path.
const String _alreadyRegisteredMessageFragment = 'already registered';

/// True when an [AuthException] means "this email already has an account".
/// Matches the typed gotrue code first, with a message fallback for older
/// backends that only set the human string.
bool isAlreadyRegisteredAuthError(AuthException e) {
  if (e.code == 'user_already_exists') return true;
  return e.message.toLowerCase().contains(_alreadyRegisteredMessageFragment);
}

/// Orchestrates email signup with session recovery, closing the post-signup
/// dead end in sign_up_password_screen.dart.
///
/// The bug: the screen read the GLOBAL `currentUser`, which lags `auth.signUp`
/// on a slow network — so signUp succeeded but `currentUser` was null for a
/// beat. The old screen told the user to "tap Continue", which re-ran signUp →
/// "User already registered" → trapped in onboarding.
///
/// The fix reads the user id straight off the signUp [AuthResponse] (the
/// authoritative result, no propagation lag), so [signUp]/[signIn] are closures
/// that return the response's user id (or null when the response carried no
/// session). Recovery order:
///   1. signUp returns an id (live session)      → [SignUpOutcome.created].
///   2. signUp returns null (no session — rare;   → [signIn] for the just-created
///      autoconfirm is on so this shouldn't        account establishes one →
///      normally happen)                            [recoveredViaSignIn], else [failed].
///   3. signUp throws "User already registered"  → [emailAlreadyRegistered].
///      We deliberately do NOT sign in: the email belongs to an existing
///      account and continuing would overwrite that user's profile.
///   4. any other [AuthException]                → [failed] (message + code preserved).
///
/// All I/O is injected so this is fully unit-testable without Supabase. Only
/// [AuthException] is caught here; other throwables (a network blip with no
/// AuthException) propagate to the caller's try/catch, preserving the prior
/// generic-error behavior.
Future<SignUpResult> performSignUpWithRecovery({
  required Future<String?> Function() signUp,
  required Future<String?> Function() signIn,
}) async {
  String? userId;
  try {
    userId = await signUp();
  } on AuthException catch (e) {
    if (isAlreadyRegisteredAuthError(e)) {
      return const SignUpResult(SignUpOutcome.emailAlreadyRegistered);
    }
    return SignUpResult(SignUpOutcome.failed,
        errorMessage: e.message, errorCode: e.code);
  }

  if (userId != null) return SignUpResult(SignUpOutcome.created, userId: userId);

  // signUp resolved without a session. Recover OUR just-created account via a
  // password sign-in (safe — this account was created moments ago by us).
  String? recoveredId;
  try {
    recoveredId = await signIn();
  } on AuthException catch (e) {
    return SignUpResult(SignUpOutcome.failed,
        errorMessage: e.message, errorCode: e.code);
  }

  if (recoveredId != null) {
    return SignUpResult(SignUpOutcome.recoveredViaSignIn, userId: recoveredId);
  }
  // signIn resolved without throwing yet left no session — treat as failure
  // rather than reporting a phantom success.
  return const SignUpResult(SignUpOutcome.failed);
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

  /// Email signup that survives the post-signup session race. Wires the real
  /// Supabase calls into [performSignUpWithRecovery]; see that function for the
  /// recovery contract. Reads the user id straight off each [AuthResponse]
  /// (`session?.user.id`) rather than the lagging global `currentUser`, which
  /// is what removes the race. Returns the resolved user id via [SignUpResult].
  Future<SignUpResult> signUpWithRecovery(
    String email,
    String password, {
    String? fullName,
  }) {
    return performSignUpWithRecovery(
      signUp: () async =>
          (await signUpWithEmail(email, password, fullName: fullName))
              .session
              ?.user
              .id,
      signIn: () async =>
          (await signInWithEmail(email, password)).session?.user.id,
    );
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
    List<String> attribution = const [],
    String? ageRange,
    String? prayerFrequency,
    int? starterNameId,
    List<String> duaTopics = const [],
    String? duaTopicsOther,
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
      'onboarding_attribution': attribution,
      'age_range': ageRange,
      'prayer_frequency': prayerFrequency,
      'starter_name_id': starterNameId,
      'dua_topics': duaTopics,
      'dua_topics_other': duaTopicsOther,
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
    final prefs = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      await clearScopedPreferencesForUser(prefs, userId);
    }
    // Drain any stranded inbound referral code so a sign-in to a different
    // account doesn't accidentally redeem a code that was captured for the
    // previous (now-signed-out) account. PR #18 added the companion source
    // key — drain it too so the next user's analytics attribution is clean.
    await prefs.remove('pending_referral');
    await prefs.remove('pending_referral_source');
    // Wipe the home-screen widget payload from the App Group container — a
    // SEPARATE store from scoped prefs, so a second user on this device must
    // not inherit the previous user's streak/Name (spec §10.5).
    await widgetDataService.clearWidget();
  }

  Future<void> deleteAccount() async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.rpc('delete_own_account');
    // Local wipe — the RPC only deletes server rows. Clear this device so the
    // deleted user's cached economy/state and widget payload don't linger.
    final prefs = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      await clearScopedPreferencesForUser(prefs, userId);
    }
    await widgetDataService.clearWidget();
  }

  bool get isSignedIn => _supabase.auth.currentUser != null;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
