import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/journal/journal_export.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

/// D2's export control.
///
/// The decision (design §11, 2026-08-02) was *"store the text server-side under
/// RLS **with** export / delete-one / delete-all shipped in the same release"*,
/// and plan §B4 records it as **non-negotiable**. Only delete-one existed —
/// and it pre-dated the journal work. These pin the half that was missing.
void main() {
  SavedReflection muhasabah({
    required String day,
    String words = 'I could not sleep.',
    String azm = '',
    List<ReflectionThreadEntry> thread = const [],
  }) =>
      SavedReflection(
        id: 'm-$day',
        date: '${day}T21:00:00.000',
        userText: words,
        name: 'Al-Halim',
        nameArabic: 'الحليم',
        reframePreview: 'Forbearance is not indifference.',
        reframe: 'He gave you room to return.',
        duaArabic: 'رَبِّ اشْرَحْ لِي صَدْرِي',
        duaTranslation: 'My Lord, expand for me my breast.',
        duaSource: "Qur'an 20:25",
        source: reflectionSourceMuhasabah,
        entryLocalDay: day,
        azm: azm,
        thread: thread,
      );

  test('an empty journal exports something honest rather than nothing', () {
    final out = buildJournalExport(const [], generatedOn: '2026-08-06');
    expect(out, contains(journalExportHeader));
    expect(out, contains('0 entries'));
    expect(out, contains('There is nothing saved yet.'));
  });

  test('every part the user authored survives the round trip', () {
    final out = buildJournalExport(
      [
        muhasabah(
          day: '2026-08-05',
          words: 'The interview is tomorrow.',
          azm: 'Call my mother.',
          thread: const [
            ReflectionThreadEntry(at: '2026-08-05T22:10:00.000', text: 'Still awake.'),
          ],
        ),
      ],
      generatedOn: '2026-08-06',
    );

    // The user's own words, their append, and their resolve — the three things
    // that are theirs and exist nowhere else.
    expect(out, contains('The interview is tomorrow.'));
    expect(out, contains('Still awake.'));
    expect(out, contains('Call my mother.'));
    // And what they were given.
    expect(out, contains('Al-Halim'));
    expect(out, contains('الحليم'));
    expect(out, contains('My Lord, expand for me my breast.'));
    expect(out, contains("Qur'an 20:25"));
  });

  test('entries come out newest first, like the Journal shows them', () {
    final out = buildJournalExport(
      [
        muhasabah(day: '2026-08-01', words: 'OLDEST'),
        muhasabah(day: '2026-08-05', words: 'NEWEST'),
        muhasabah(day: '2026-08-03', words: 'MIDDLE'),
      ],
      generatedOn: '2026-08-06',
    );
    expect(out.indexOf('NEWEST'), lessThan(out.indexOf('MIDDLE')));
    expect(out.indexOf('MIDDLE'), lessThan(out.indexOf('OLDEST')));
    expect(out, contains('3 entries'));
  });

  test('the two kinds of entry are labelled apart', () {
    final out = buildJournalExport(
      [
        muhasabah(day: '2026-08-05'),
        const SavedReflection(
          id: 'r1',
          date: '2026-08-04T10:00:00.000',
          userText: 'A Reflect save.',
          name: 'Al-Wakeel',
          nameArabic: 'الوكيل',
          reframePreview: 'You are not carrying the outcome.',
        ),
      ],
      generatedOn: '2026-08-06',
    );
    expect(out, contains('Muḥāsabah — 2026-08-05T21:00:00.000'));
    expect(out, contains('Reflection — 2026-08-04T10:00:00.000'));
  });

  test('no internal scaffolding leaks into the file', () {
    // An export padded with our own field names reads like a database dump.
    // The user gets what they wrote and what they were given — nothing about
    // how we render it.
    final out = buildJournalExport(
      [muhasabah(day: '2026-08-05')],
      generatedOn: '2026-08-06',
    );
    for (final leak in ['reframeKey', 'storyBeats', 'relatedNames', 'm-2026-08-05']) {
      expect(out, isNot(contains(leak)), reason: '$leak should not be exported');
    }
  });

  test('an entry with only the user text does not emit empty sections', () {
    final out = buildJournalExport(
      [
        const SavedReflection(
          id: 'r1',
          date: '2026-08-04T10:00:00.000',
          userText: 'Just this.',
          name: '',
          nameArabic: '',
          reframePreview: '',
        ),
      ],
      generatedOn: '2026-08-06',
    );
    expect(out, contains('Just this.'));
    for (final absent in ['Duʿā:', 'Your ʿazm:', 'Added later:', 'Story:']) {
      expect(out, isNot(contains(absent)), reason: 'empty section "$absent" emitted');
    }
  });
}
