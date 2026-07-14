// Generates the home-screen widget's daily-Name catalog.
//
// Produces `ios/SakinaWidget/catalog.json`: one row per Name, in EXACTLY the
// same order as `allahNames`, so the widget's offline daily fallback can index
// `dayOfYear % catalog.length` and always agree with the app's
// `getTodaysName()` (spec §10.1). The catalog is a COMMITTED artifact — CI runs
// this generator and the parity test; no DB access needed at build time
// (§10.2). The anchor text comes from the committed snapshot
// `assets/widget/name_anchors_snapshot.json`.
//
// Run: dart run scripts/gen_widget_catalog.dart
// Exits non-zero if any Name fails to resolve an anchor or any anchor is unused
// (the mapping must be a bijection).

import 'dart:convert';
import 'dart:io';

import 'package:sakina/core/constants/allah_names.dart';

/// `allahNames` transliteration variants → the `name_anchors.name_key` spelling.
/// Only the entries whose normalized transliteration does NOT already equal the
/// snapshot key. Explicit over clever: every divergent romanization is listed.
const Map<String, String> _keyOverrides = {
  'ar-raheem': 'ar-rahim',
  'al-hakeem': 'al-hakim',
  'al-kareem': 'al-karim',
  'al-wakeel': 'al-wakil',
  'al-lateef': 'al-latif',
  'al-mujeeb': 'al-mujib',
  'al-baseer': 'al-basir',
  'al-khabeer': 'al-khabir',
  'ash-shaheed': 'ash-shahid',
  'al-qawiyy': 'al-qawi',
  'al-mateen': 'al-matin',
};

String _normalize(String transliteration) => transliteration
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// The snapshot key for [name].
String _anchorKey(AllahName name) {
  final base = _normalize(name.transliteration);
  return _keyOverrides[base] ?? base;
}

void main() {
  final root = Directory.current.path;
  final snapshotFile =
      File('$root/assets/widget/name_anchors_snapshot.json');
  if (!snapshotFile.existsSync()) {
    stderr.writeln('Missing ${snapshotFile.path}');
    exit(1);
  }
  final snapshot =
      jsonDecode(snapshotFile.readAsStringSync()) as Map<String, dynamic>;
  final anchors = <String, String>{
    for (final e in snapshot.entries)
      if (!e.key.startsWith('_')) e.key: e.value as String,
  };

  final unresolved = <String>[];
  final usedKeys = <String>{};
  final catalog = <Map<String, dynamic>>[];

  for (var i = 0; i < allahNames.length; i++) {
    final name = allahNames[i];
    final key = _anchorKey(name);
    final anchor = anchors[key];
    if (anchor == null) {
      unresolved.add('#${name.id} ${name.transliteration} → "$key" (no anchor)');
      continue;
    }
    usedKeys.add(key);
    catalog.add({
      'index': i,
      'name_key': key,
      'arabic': name.arabic,
      'transliteration': name.transliteration,
      'english': name.english,
      'anchor': anchor,
    });
  }

  final unusedKeys = anchors.keys.toSet().difference(usedKeys);

  if (unresolved.isNotEmpty || unusedKeys.isNotEmpty) {
    stderr.writeln('Catalog generation FAILED — mapping is not a bijection:');
    for (final u in unresolved) {
      stderr.writeln('  UNRESOLVED: $u');
    }
    for (final k in unusedKeys) {
      stderr.writeln('  UNUSED ANCHOR: $k');
    }
    exit(1);
  }

  final outFile = File('$root/ios/SakinaWidget/catalog.json');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'count': catalog.length,
      'names': catalog,
    }),
  );
  stdout.writeln(
      'Wrote ${catalog.length} names → ${outFile.path} (bijection verified).');
}
