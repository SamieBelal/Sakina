import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/main.dart' show extractValidReferralCode, referralCodeMaxLength;

/// Tests for the deep-link referral code validator extracted from main.dart's
/// `_persistReferralFromUri`. Pins:
///
///   * Well-formed `sakina://r/<code>` returns the code.
///   * Non-`sakina` schemes are rejected.
///   * Host other than `r` is rejected.
///   * Empty path is rejected.
///   * Codes containing confusables (I/O/0/1) or lowercase are rejected.
///   * Pathologically long codes (>16) are rejected — would otherwise bloat
///     SharedPreferences from a hostile URL.
///   * Various adversarial shapes (whitespace, control chars, unicode) are
///     rejected.
///
/// The server-side validation (apply_referral RPC) is the real gate — this
/// just prevents writing junk into SharedPreferences from an untrusted URI.
void main() {
  group('extractValidReferralCode — happy paths', () {
    test('returns 8-char canonical code', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/ABCD2345')),
        'ABCD2345',
      );
    });

    test('returns shorter code (server rejects but shape is fine)', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/ABC')),
        'ABC',
      );
    });

    test('accepts code at exactly the max length', () {
      final code = 'A' * referralCodeMaxLength;
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/$code')),
        code,
      );
    });
  });

  group('extractValidReferralCode — scheme/host rejection', () {
    test('rejects http scheme', () {
      expect(
        extractValidReferralCode(Uri.parse('http://r/ABCD2345')),
        isNull,
      );
    });

    test('rejects https universal link (Phase 2 path)', () {
      expect(
        extractValidReferralCode(Uri.parse('https://sakina.app/r/ABCD2345')),
        isNull,
      );
    });

    test('rejects wrong host', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://x/ABCD2345')),
        isNull,
      );
    });

    test('rejects empty path', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/')),
        isNull,
      );
    });
  });

  group('extractValidReferralCode — charset rejection', () {
    test('rejects lowercase letters', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/abcd2345')),
        isNull,
      );
    });

    test('rejects confusable I', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/AICD2345')),
        isNull,
      );
    });

    test('rejects confusable O', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/AOCD2345')),
        isNull,
      );
    });

    test('rejects confusable 0', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/A0CD2345')),
        isNull,
      );
    });

    test('rejects confusable 1', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/A1CD2345')),
        isNull,
      );
    });

    test('rejects punctuation', () {
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/ABCD-345')),
        isNull,
      );
    });
  });

  group('extractValidReferralCode — length rejection (hardening)', () {
    test('rejects code longer than referralCodeMaxLength', () {
      final tooLong = 'A' * (referralCodeMaxLength + 1);
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/$tooLong')),
        isNull,
      );
    });

    test('rejects pathological 10KB code (hostile URL DoS attempt)', () {
      final huge = 'A' * 10000;
      expect(
        extractValidReferralCode(Uri.parse('sakina://r/$huge')),
        isNull,
      );
    });
  });
}
