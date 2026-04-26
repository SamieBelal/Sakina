// F1 fix unit test (2026-04-26-settings-no-display-name).
// resolveProfileDisplayName picks the canonical display name across the
// three possible sources: user_profiles.display_name (preferred), auth
// metadata full_name, and email. Pre-fix the Settings screen showed
// email twice because user_profiles.display_name was never read.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/settings/screens/settings_screen.dart';

void main() {
  test('prefers profileDisplayName when present', () {
    expect(
      resolveProfileDisplayName(
        profileDisplayName: 'QABot',
        fullName: 'Should Be Ignored',
        email: 'qa@example.com',
      ),
      'QABot',
    );
  });

  test('falls back to fullName when profileDisplayName is null', () {
    expect(
      resolveProfileDisplayName(
        profileDisplayName: null,
        fullName: 'Apple Signed-in User',
        email: 'qa@example.com',
      ),
      'Apple Signed-in User',
    );
  });

  test('falls back to fullName when profileDisplayName is empty/whitespace',
      () {
    expect(
      resolveProfileDisplayName(
        profileDisplayName: '   ',
        fullName: 'Real Name',
        email: 'qa@example.com',
      ),
      'Real Name',
    );
  });

  test('falls back to email when profile + fullName are missing', () {
    expect(
      resolveProfileDisplayName(
        profileDisplayName: null,
        fullName: null,
        email: 'qa@example.com',
      ),
      'qa@example.com',
    );
  });

  test('returns Guest when everything is null', () {
    expect(
      resolveProfileDisplayName(
        profileDisplayName: null,
        fullName: null,
        email: null,
      ),
      'Guest',
    );
  });

  test('returns Guest when everything is empty/whitespace', () {
    expect(
      resolveProfileDisplayName(
        profileDisplayName: '',
        fullName: '   ',
        email: '',
      ),
      'Guest',
    );
  });

  test('trims whitespace from profileDisplayName', () {
    expect(
      resolveProfileDisplayName(profileDisplayName: '  QABot  '),
      'QABot',
    );
  });
}
