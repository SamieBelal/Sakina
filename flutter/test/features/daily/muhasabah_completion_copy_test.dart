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
        expect(MuhasabahCompletionCopy.addToCtaFor(hour),
            'Something else for today');
        expect(MuhasabahCompletionCopy.subheaderFor(hour), contains('Today stays open'));
      }
    });

    test('evening and night read "Tonight"', () {
      for (final hour in [17, 20, 23]) {
        expect(MuhasabahCompletionCopy.dayNoun(hour), 'Tonight', reason: '$hour:00');
        expect(MuhasabahCompletionCopy.headerFor(hour), 'Tonight is written down.');
        expect(MuhasabahCompletionCopy.addToCtaFor(hour),
            'Something else for tonight');
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

    test('the short form names the same act, without the day noun', () {
      // The compose menu's card caps at 168pt, where the long form would
      // ellipsise mid-word ("Something else for tod…"). The elision is
      // deliberate and so is what it drops FIRST: the day noun, which is also
      // the only hour-dependent half — a menu row whose text changed at 17:00
      // would be the shape-shifting control `JournalComposeAction` exists to
      // prevent.
      expect(MuhasabahCompletionCopy.addToCtaShort, 'Something else');
      for (final hour in [0, 9, 16, 17, 21, 23]) {
        expect(MuhasabahCompletionCopy.addToCtaFor(hour),
            startsWith(MuhasabahCompletionCopy.addToCtaShort),
            reason: 'the long and short forms must be the same NAME, elided — '
                'not two names for one act ($hour:00)');
      }
    });

    test('neither form names the database operation', () {
      // The rename's whole point (2026-08-07). No comparable app labels this
      // action after its storage: the guided journals name the moment, the
      // free-form ones name the content. "Add to today" named the row.
      for (final label in [
        MuhasabahCompletionCopy.addToCtaFor(9),
        MuhasabahCompletionCopy.addToCtaFor(21),
        MuhasabahCompletionCopy.addToCtaShort,
        MuhasabahCompletionCopy.addToTonight,
      ]) {
        expect(label.toLowerCase(), isNot(startsWith('add to')),
            reason: '"$label" is back to naming the write, not the act');
      }
    });
  });
}
