import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Unit tests for [performSignUpWithRecovery] — the orchestration that closes
/// the post-signup session-race dead end documented in
/// sign_up_password_screen.dart.
///
/// THIS is the deterministic reproduction the iOS simulator cannot force: the
/// race is "signUp() resolved but the session didn't materialize on the next
/// read", which is timing-dependent in the real auth stack. Here the signUp
/// closure simply returns `null` (no session) — no flakiness, no Supabase.
///
/// signUp/signIn are injected as closures that return the user id from their
/// AuthResponse (or null when the response carried no session), so the
/// orchestration is tested with zero Supabase / widget dependencies.
void main() {
  late List<String> calls;

  setUp(() => calls = []);

  Future<String?> Function() signUpReturns(String? id) => () async {
        calls.add('signUp');
        return id;
      };

  Future<String?> Function() signUpThrows(AuthException e) => () async {
        calls.add('signUp');
        throw e;
      };

  Future<String?> Function() signInReturns(String? id) => () async {
        calls.add('signIn');
        return id;
      };

  Future<String?> Function() signInThrows(AuthException e) => () async {
        calls.add('signIn');
        throw e;
      };

  group('performSignUpWithRecovery · happy path', () {
    test('signUp returns an id (live session) → created, signIn NOT called',
        () async {
      final result = await performSignUpWithRecovery(
        signUp: signUpReturns('uid-1'),
        signIn: signInReturns('should-not-run'),
      );

      expect(result.outcome, SignUpOutcome.created);
      expect(result.userId, 'uid-1');
      expect(calls, ['signUp'], reason: 'signIn must not run when session is live');
    });
  });

  group('performSignUpWithRecovery · session race', () {
    test('signUp returns null (no session) → signIn recovers → recoveredViaSignIn',
        () async {
      final result = await performSignUpWithRecovery(
        signUp: signUpReturns(null),
        signIn: signInReturns('uid-fallback'),
      );

      expect(result.outcome, SignUpOutcome.recoveredViaSignIn);
      expect(result.userId, 'uid-fallback');
      expect(calls, ['signUp', 'signIn']);
    });

    test('signUp null → signIn also null → failed (no phantom success)',
        () async {
      final result = await performSignUpWithRecovery(
        signUp: signUpReturns(null),
        signIn: signInReturns(null),
      );

      expect(result.outcome, SignUpOutcome.failed);
      expect(result.userId, isNull);
      expect(calls, ['signUp', 'signIn']);
    });

    test('signUp null → signIn throws AuthException → failed with message+code',
        () async {
      final result = await performSignUpWithRecovery(
        signUp: signUpReturns(null),
        signIn: signInThrows(
          const AuthException('Email rate limit exceeded',
              code: 'over_email_send_rate_limit'),
        ),
      );

      expect(result.outcome, SignUpOutcome.failed);
      expect(result.errorMessage, 'Email rate limit exceeded');
      expect(result.errorCode, 'over_email_send_rate_limit');
      expect(calls, ['signUp', 'signIn']);
    });
  });

  group('performSignUpWithRecovery · email already registered', () {
    test('user_already_exists code → emailAlreadyRegistered, signIn NOT called',
        () async {
      final result = await performSignUpWithRecovery(
        signUp: signUpThrows(
          const AuthException('User already registered',
              code: 'user_already_exists'),
        ),
        signIn: signInReturns('should-not-run'),
      );

      expect(result.outcome, SignUpOutcome.emailAlreadyRegistered);
      expect(result.userId, isNull);
      // Critically: we never sign in, so a pre-existing account is never touched.
      expect(calls, ['signUp'],
          reason: 'must NOT sign into / overwrite an existing account');
    });

    test('already-registered message (no typed code) is also recognized',
        () async {
      final result = await performSignUpWithRecovery(
        signUp: signUpThrows(const AuthException('User already registered')),
        signIn: signInReturns('should-not-run'),
      );

      expect(result.outcome, SignUpOutcome.emailAlreadyRegistered);
      expect(calls, ['signUp']);
    });
  });

  group('performSignUpWithRecovery · genuine failures', () {
    test('non-recoverable AuthException on signUp → failed, signIn NOT called',
        () async {
      final result = await performSignUpWithRecovery(
        signUp: signUpThrows(
          const AuthException('Password should be at least 6 characters',
              code: 'weak_password'),
        ),
        signIn: signInReturns('should-not-run'),
      );

      expect(result.outcome, SignUpOutcome.failed);
      expect(result.errorMessage, 'Password should be at least 6 characters');
      expect(result.errorCode, 'weak_password');
      expect(calls, ['signUp'], reason: 'a weak-password error is not recoverable');
    });

    test('non-AuthException on signUp propagates to the caller', () async {
      // Contract: only AuthException is caught here. A bare network/socket
      // error must bubble to the screen's outer try/catch (generic-error path).
      expect(
        () => performSignUpWithRecovery(
          signUp: () async {
            calls.add('signUp');
            throw Exception('socket closed');
          },
          signIn: signInReturns('x'),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('non-AuthException on the signIn fallback propagates too', () async {
      expect(
        () => performSignUpWithRecovery(
          signUp: signUpReturns(null),
          signIn: () async {
            calls.add('signIn');
            throw Exception('socket closed');
          },
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('isAlreadyRegisteredAuthError', () {
    test('matches the typed code and the message fragment, rejects others', () {
      expect(
        isAlreadyRegisteredAuthError(
            const AuthException('x', code: 'user_already_exists')),
        isTrue,
      );
      // Case-insensitive message fallback for older backends.
      expect(
        isAlreadyRegisteredAuthError(const AuthException('User Already Registered')),
        isTrue,
      );
      // An unrelated auth error must NOT be treated as already-registered,
      // otherwise genuine failures would be misrouted.
      expect(
        isAlreadyRegisteredAuthError(
            const AuthException('Password should be at least 6 characters',
                code: 'weak_password')),
        isFalse,
      );
      expect(
        isAlreadyRegisteredAuthError(
            const AuthException('Invalid login credentials',
                code: 'invalid_credentials')),
        isFalse,
      );
    });
  });
}
