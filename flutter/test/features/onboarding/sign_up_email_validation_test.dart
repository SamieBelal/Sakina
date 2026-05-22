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
  });
}
