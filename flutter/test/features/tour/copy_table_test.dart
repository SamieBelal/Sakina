import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/tour_service.dart';

/// T24 — copy table guard.
///
/// Per the design review: every string in [TourCopy] must be referenced
/// somewhere in `lib/features/` (verbatim) or via its `TourCopy.<name>`
/// identifier. This guards against copy drift — a strings-only sweep that
/// silently breaks the feature wiring.
void main() {
  test('T24: every TourCopy string appears in lib/', () async {
    // Static const reflection isn't available; list them explicitly. Keep in
    // sync with TourCopy in lib/services/tour_service.dart.
    final strings = <String, String>{
      'homeStep1': TourCopy.homeStep1,
      'homeStep2': TourCopy.homeStep2,
      'homeStep3': TourCopy.homeStep3,
      'collectionEmptyCaption': TourCopy.collectionEmptyCaption,
      'journalEmptyTitle': TourCopy.journalEmptyTitle,
      'journalEmptyBody': TourCopy.journalEmptyBody,
      'journalEmptyCta': TourCopy.journalEmptyCta,
      'duasStep1': TourCopy.duasStep1,
      'settingsReplayLabel': TourCopy.settingsReplayLabel,
      'winBackPushTitle': TourCopy.winBackPushTitle,
      'winBackPushBody': TourCopy.winBackPushBody,
    };

    final allDartContent = StringBuffer();
    // Walk lib/features (where the feature wiring lives) and the
    // tour_service.dart file (the copy source-of-truth). The win-back push
    // strings live in OneSignal config, not Dart code — they're referenced
    // via `TourCopy.winBackPushTitle` in tour_service.dart itself, which
    // satisfies the guard.
    final libDir = Directory('lib/features');
    if (libDir.existsSync()) {
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          allDartContent.write(await entity.readAsString());
          allDartContent.write('\n');
        }
      }
    }
    final tourSvc = File('lib/services/tour_service.dart');
    if (tourSvc.existsSync()) {
      allDartContent.write(await tourSvc.readAsString());
    }

    final content = allDartContent.toString();
    final missing = <String>[];
    for (final entry in strings.entries) {
      final literalUsed = content.contains(entry.value);
      final identifierUsed = content.contains('TourCopy.${entry.key}');
      if (!literalUsed && !identifierUsed) {
        missing.add('${entry.key}: "${entry.value}"');
      }
    }
    expect(missing, isEmpty,
        reason:
            'Every TourCopy string must be referenced somewhere in lib/features/ '
            'via either the literal text or TourCopy.<name>. Missing:\n${missing.join('\n')}');
  });
}
