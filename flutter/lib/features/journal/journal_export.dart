/// Turns the user's saved journal into plain text they can keep.
///
/// ## Why this exists
///
/// D2 (design §11, 2026-08-02) resolved the storage question as *"store the
/// text server-side under RLS **with** export / delete-one / delete-all shipped
/// in the same release"*, and plan §B4 records that as **non-negotiable**:
/// *"the decision was 'store it *with* the controls', not 'store it'."* The
/// muḥāsabah is confessional — people write about their own sin — and the
/// decision to keep it on a server was made conditional on being able to take
/// it back out and to destroy it.
///
/// The whole Islamic journaling cohort competes on exactly this: Tumaninah
/// (*"what you write in your muhasabah is between you and Allah"* — no backend
/// at all), Qalb (*"No servers, no data mining"*), Muhasaba (*"export or
/// permanently delete all data via Settings in one action"*). So this is a
/// posture commitment before it is a feature.
///
/// ## Why plain text and not JSON
///
/// The point of an export is that it outlives us. JSON is a better *backup* and
/// a worse *artifact*: a text file opens on any device in twenty years with no
/// tooling and no schema. Users who lose a journal describe it as losing years
/// of their life, so the format that survives neglect is the right one.
///
/// Deliberately NOT included: internal ids, the beat scaffolding
/// (`reframeKey` / `storyBeats` / `takeaway`) and `relatedNames`. Those are
/// rendering machinery for our screens, not things the user wrote or was given.
/// An export padded with our own field names reads like a database dump and
/// buries the part that matters.
library;

import 'package:sakina/features/reflect/providers/reflect_provider.dart';

/// Header line, kept out of the body so a test can pin it without matching prose.
const String journalExportHeader = 'My Sakina journal';

/// Renders [reflections] as one plain-text document, newest first.
///
/// Pure and synchronous — no I/O, no clock, no formatting locale — so the whole
/// shape is testable without a device. [generatedOn] is passed in rather than
/// read from `DateTime.now()` for the same reason.
String buildJournalExport(
  List<SavedReflection> reflections, {
  required String generatedOn,
}) {
  final buffer = StringBuffer()
    ..writeln(journalExportHeader)
    ..writeln('Exported $generatedOn')
    ..writeln('${reflections.length} '
        '${reflections.length == 1 ? 'entry' : 'entries'}')
    ..writeln();

  if (reflections.isEmpty) {
    buffer.writeln('There is nothing saved yet.');
    return buffer.toString();
  }

  // Newest first, matching the order the Journal itself shows. `date` is an
  // ISO-8601 instant written by us, so a string sort is a time sort.
  final sorted = [...reflections]..sort((a, b) => b.date.compareTo(a.date));

  for (final r in sorted) {
    buffer
      ..writeln('────────────────────────────────')
      ..writeln(r.isMuhasabah ? 'Muḥāsabah — ${r.date}' : 'Reflection — ${r.date}');
    if (r.name.isNotEmpty) {
      // Arabic on its own line, never concatenated with Latin (CLAUDE.md).
      buffer.writeln('The Name you met: ${r.name}');
      if (r.nameArabic.isNotEmpty) buffer.writeln(r.nameArabic);
    }
    buffer.writeln();

    if (r.userText.isNotEmpty) {
      buffer
        ..writeln('What you wrote:')
        ..writeln(r.userText)
        ..writeln();
    }

    for (final entry in r.thread) {
      buffer
        ..writeln('Added later:')
        ..writeln(entry.text)
        ..writeln();
    }

    if (r.azm.isNotEmpty) {
      buffer
        ..writeln('Your ʿazm:')
        ..writeln(r.azm)
        ..writeln();
    }

    if (r.reframe.isNotEmpty) {
      buffer
        ..writeln('Reflection:')
        ..writeln(r.reframe)
        ..writeln();
    }
    if (r.story.isNotEmpty) {
      buffer
        ..writeln('Story:')
        ..writeln(r.story)
        ..writeln();
    }

    for (final v in r.verses) {
      if (v.arabic.isNotEmpty) buffer.writeln(v.arabic);
      if (v.translation.isNotEmpty) buffer.writeln(v.translation);
      if (v.reference.isNotEmpty) buffer.writeln('— ${v.reference}');
      buffer.writeln();
    }

    if (r.duaTranslation.isNotEmpty || r.duaArabic.isNotEmpty) {
      buffer.writeln('Duʿā:');
      if (r.duaArabic.isNotEmpty) buffer.writeln(r.duaArabic);
      if (r.duaTransliteration.isNotEmpty) {
        buffer.writeln(r.duaTransliteration);
      }
      if (r.duaTranslation.isNotEmpty) buffer.writeln(r.duaTranslation);
      if (r.duaSource.isNotEmpty) buffer.writeln('— ${r.duaSource}');
      buffer.writeln();
    }
  }

  return buffer.toString();
}
