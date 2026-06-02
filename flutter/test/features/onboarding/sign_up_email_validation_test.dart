import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/sign_up_email_screen.dart';

void main() {
  group('SignUpEmailScreen.isValidEmail', () {
    test('accepts well-formed addresses', () {
      const valid = [
        'a@b.co',
        'darkmatter8789@gmail.com',
        'user.name+tag@sub.example.com',
        'first_last@example-domain.io',
        'A.B.C@d.example.org',
      ];
      for (final e in valid) {
        expect(SignUpEmailScreen.isValidEmail(e), isTrue,
            reason: '"$e" should be accepted');
      }
    });

    test('rejects the strings the old contains-check let through', () {
      const garbage = [
        'a@.',
        '@.',
        '@.b',
        'a@b',
        'me@@x.com',
        'test@.com',
        'a@b.',
        '.@.',
        'a@.com',
      ];
      for (final e in garbage) {
        expect(SignUpEmailScreen.isValidEmail(e), isFalse,
            reason: '"$e" should be rejected');
      }
    });

    test('rejects empty / whitespace input', () {
      expect(SignUpEmailScreen.isValidEmail(''), isFalse);
      expect(SignUpEmailScreen.isValidEmail('   '), isFalse);
      expect(SignUpEmailScreen.isValidEmail('\t\n'), isFalse);
    });

    test('rejects multiple @ or spaces', () {
      expect(SignUpEmailScreen.isValidEmail('a@b@c.com'), isFalse);
      expect(SignUpEmailScreen.isValidEmail('a b@c.com'), isFalse);
      expect(SignUpEmailScreen.isValidEmail('a@b c.com'), isFalse);
    });

    test('trims whitespace before validating', () {
      expect(SignUpEmailScreen.isValidEmail('  a@b.co  '), isTrue);
      expect(SignUpEmailScreen.isValidEmail('\ta@b.co\n'), isTrue);
    });

    test('rejects TLDs shorter than 2 letters', () {
      expect(SignUpEmailScreen.isValidEmail('a@b.c'), isFalse);
      expect(SignUpEmailScreen.isValidEmail('a@b.1'), isFalse);
    });

    // Internationalized addresses. Supabase auth accepts these; the old
    // ASCII-only regex bounced Turkish/French/CJK users out of the signup
    // funnel with a confusing "valid email" error (TODO: i18n email regex).
    test('accepts Unicode local-part and domain (i18n)', () {
      const intl = [
        'josé@example.com', // French / Spanish accent (precomposed U+00E9)
        'müller@example.de', // German umlaut
        'çağrı@example.com.tr', // Turkish, multi-label domain
        '用户@例え.jp', // CJK local-part + domain
        'a@b.cé', // Unicode-letter TLD (pins \p{L} TLD class)
      ];
      for (final e in intl) {
        expect(SignUpEmailScreen.isValidEmail(e), isTrue,
            reason: '"$e" should be accepted (Supabase accepts it)');
      }
    });

    test('accepts NFD (decomposed-diacritic) forms — \\p{M} coverage', () {
      // The exact i18n users the fix targets: many keyboards / paste sources
      // emit decomposed diacritics (base letter + combining mark) rather than
      // precomposed. Without \p{M} in the char classes these are rejected.
      const eAcute = 'é'; // 'é' decomposed = e + COMBINING ACUTE ACCENT
      expect(SignUpEmailScreen.isValidEmail('jos$eAcute@example.com'), isTrue,
          reason: 'NFD local-part should be accepted');
      expect(SignUpEmailScreen.isValidEmail('a@b.c$eAcute'), isTrue,
          reason: 'NFD TLD should be accepted');
    });

    test('rejects digit-bearing TLD (\\p{L}\\p{M} TLD excludes \\p{N})', () {
      // The Unicode TLD class must stay letters-only, not digits.
      expect(SignUpEmailScreen.isValidEmail('a@b.co1'), isFalse);
      expect(SignUpEmailScreen.isValidEmail('用户@例え.j2'), isFalse);
    });

    test('still rejects malformed Unicode-adjacent garbage', () {
      const garbage = [
        'not@an@email', // double @
        'josé@@example.com', // double @ after Unicode local-part
        'müller@.de', // leading-dot domain
        '用户@例え.j', // 1-char TLD
        'a@b.com\ninjected@evil.com', // embedded-newline injection (anchors hold)
      ];
      for (final e in garbage) {
        expect(SignUpEmailScreen.isValidEmail(e), isFalse,
            reason: '"$e" should be rejected');
      }
    });

    // Documents a DELIBERATE leniency, not a bug: the local-part allows leading,
    // trailing, and consecutive dots (matches what Supabase auth accepts).
    // Domain-side dot strictness is asserted separately above. Pinned so the
    // leniency is visible and intentional, not silently assumed.
    test('local-part dots are intentionally lenient (Supabase parity)', () {
      for (final e in const ['.a@b.com', 'a.@b.com', 'a..b@c.com']) {
        expect(SignUpEmailScreen.isValidEmail(e), isTrue,
            reason: '"$e" local-part dot leniency is intentional');
      }
    });
  });
}
