import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/auth_service.dart';

void main() {
  group('AuthService.resolveDisplayName', () {
    test('returns trimmed name when non-empty', () {
      expect(AuthService.resolveDisplayName('Ibrahim'), 'Ibrahim');
      expect(AuthService.resolveDisplayName('  Aisha  '), 'Aisha');
      expect(AuthService.resolveDisplayName('A'), 'A');
    });

    test('falls back to default for null input', () {
      expect(AuthService.resolveDisplayName(null),
          AuthService.defaultDisplayName);
      expect(AuthService.resolveDisplayName(null), 'Friend');
    });

    test('falls back to default for empty / whitespace-only input', () {
      expect(AuthService.resolveDisplayName(''),
          AuthService.defaultDisplayName);
      expect(AuthService.resolveDisplayName('   '),
          AuthService.defaultDisplayName);
      expect(AuthService.resolveDisplayName('\t\n'),
          AuthService.defaultDisplayName);
    });

    test('preserves non-ASCII names', () {
      // Don't strip Arabic / accented input — junk names are a separate
      // concern (input sanity check, not the display_name persistence layer).
      expect(AuthService.resolveDisplayName('عمر'), 'عمر');
      expect(AuthService.resolveDisplayName('Émile'), 'Émile');
    });
  });
}
