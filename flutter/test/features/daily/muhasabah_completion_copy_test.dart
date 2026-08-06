import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';

/// The morning-reader fix, pinned clock-free.
///
/// The muḥāsabah has never been night-gated: it is keyed on `entry_local_day`
/// with a one-per-user-per-local-day unique index, and nothing in the daily
/// provider consults the clock to decide whether it may be done. So a user who
/// opened the app at 9am completed a correct muḥāsabah and was then told
/// "Tonight is written down."
///
/// These assertions pass an hour in rather than reading `DateTime.now()`, so
/// they mean the same thing at every hour of the day — which the widget test
/// deliberately cannot.
void main() {
  group('the noun follows the hour, not the feature name', () {
    test('morning and afternoon read "Today"', () {
      for (final hour in [0, 6, 9, 12, 16]) {
        expect(MuhasabahCompletionCopy.dayNoun(hour), 'Today', reason: '$hour:00');
        expect(MuhasabahCompletionCopy.headerFor(hour), 'Today is written down.');
        expect(MuhasabahCompletionCopy.addToCtaFor(hour), 'Add to today');
        expect(MuhasabahCompletionCopy.subheaderFor(hour), contains('Today stays open'));
      }
    });

    test('evening and night read "Tonight"', () {
      for (final hour in [17, 20, 23]) {
        expect(MuhasabahCompletionCopy.dayNoun(hour), 'Tonight', reason: '$hour:00');
        expect(MuhasabahCompletionCopy.headerFor(hour), 'Tonight is written down.');
        expect(MuhasabahCompletionCopy.addToCtaFor(hour), 'Add to tonight');
        expect(MuhasabahCompletionCopy.subheaderFor(hour), contains('Tonight stays open'));
      }
    });

    test('the boundary is 17:00 exactly, and it is the documented constant', () {
      expect(MuhasabahCompletionCopy.eveningStartsAtHour, 17);
      expect(MuhasabahCompletionCopy.dayNoun(16), 'Today');
      expect(MuhasabahCompletionCopy.dayNoun(17), 'Tonight');
    });

    test('the evening strings are byte-identical to what shipped before', () {
      // The change may only affect the morning reader. If these drift, an
      // evening user's copy changed too, which was never the intent.
      expect(MuhasabahCompletionCopy.headerFor(21), MuhasabahCompletionCopy.header);
      expect(MuhasabahCompletionCopy.subheaderFor(21), MuhasabahCompletionCopy.subheader);
      expect(MuhasabahCompletionCopy.addToCtaFor(21), MuhasabahCompletionCopy.addToTonight);
    });
  });
}
