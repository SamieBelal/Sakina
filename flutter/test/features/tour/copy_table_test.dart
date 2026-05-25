import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/tour_service.dart';

/// T24 — copy table guard.
///
/// Per the design review: every string in [TourCopy] must be referenced
/// somewhere in `lib/features/` via its `TourCopy.<name>` identifier (the
/// constant lookup, not a hardcoded literal). This guards against copy
/// drift — a strings-only sweep that silently breaks the feature wiring.
///
/// Excludes:
///   * `lib/services/tour_service.dart` itself — the literals live there as
///     `static const` definitions and would trivially match themselves.
///   * `winBackPushTitle` / `winBackPushBody` — these are consumed in
///     OneSignal config (manual setup per docs/runbooks/onesignal-segments.md),
///     not in Dart code. They are validated by reading the runbook below.
void main() {
  test('T24: every TourCopy code-side string is referenced in lib/features/', () async {
    final codeSideStrings = <String, String>{
      'homeStep1': TourCopy.homeStep1,
      'homeStep2': TourCopy.homeStep2,
      'homeStep3': TourCopy.homeStep3,
      'collectionEmptyCaption': TourCopy.collectionEmptyCaption,
      'journalEmptyTitle': TourCopy.journalEmptyTitle,
      'journalEmptyBody': TourCopy.journalEmptyBody,
      'journalEmptyCta': TourCopy.journalEmptyCta,
      'duasStep1': TourCopy.duasStep1,
      'settingsReplayLabel': TourCopy.settingsReplayLabel,
    };

    final featuresContent = StringBuffer();
    final featuresDir = Directory('lib/features');
    expect(featuresDir.existsSync(), isTrue,
        reason: 'lib/features must exist for this test to be meaningful');
    await for (final entity in featuresDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        featuresContent.write(await entity.readAsString());
        featuresContent.write('\n');
      }
    }
    final content = featuresContent.toString();

    final missing = <String>[];
    for (final entry in codeSideStrings.entries) {
      // Strict: require the TourCopy.<name> identifier reference. Hardcoded
      // literal copies would still pass a contains-check but defeat the
      // whole point of the copy table.
      final identifierUsed = content.contains('TourCopy.${entry.key}');
      if (!identifierUsed) {
        missing.add('TourCopy.${entry.key} ("${entry.value}")');
      }
    }
    expect(missing, isEmpty,
        reason: 'Every TourCopy code-side string MUST be referenced via the '
            'TourCopy.<name> identifier in lib/features/. Hardcoded literals '
            'defeat the copy table guard. Missing references:\n${missing.join('\n')}');
  });

  test('T24b: win-back push copy is referenced in the OneSignal runbook', () async {
    // winBackPushTitle / winBackPushBody live in OneSignal config (not Dart).
    // Verify the runbook documents both literals so a future engineer can
    // rebuild the template if it's deleted from the OneSignal dashboard.
    final runbook = File('docs/runbooks/onesignal-segments.md');
    expect(runbook.existsSync(), isTrue,
        reason: 'OneSignal runbook missing — win-back push copy has no spec');
    final body = await runbook.readAsString();
    expect(body, contains(TourCopy.winBackPushTitle),
        reason: 'OneSignal runbook must document the literal winBackPushTitle');
    expect(body, contains(TourCopy.winBackPushBody),
        reason: 'OneSignal runbook must document the literal winBackPushBody');
  });
}
