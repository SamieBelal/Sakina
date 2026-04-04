/// Validates Names of Allah returned by Claude against the canonical 99 Names list.
/// Prevents hallucinated or non-standard names from appearing in the app.

import 'package:sakina/core/constants/allah_names.dart';

/// Normalise: lowercase, remove Arabic script, remove non-alpha,
/// strip common transliteration prefixes (al-, ar-, as-, ash-, at-, az-, an-).
String _normalise(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[\u0600-\u06FF\s]'), '') // strip Arabic script
      .replaceAll(RegExp(r'[^a-z]'), '') // strip non-alpha
      .replaceFirst(RegExp(r'^(al|ar|as|ash|at|az|an)'), ''); // strip common prefixes
}

/// Pre-built normalised lookup set from the canonical list.
final Set<String> _canonicalNormalised = {
  for (final n in allahNames) _normalise(n.transliteration),
};

/// Pre-built map from normalised key to canonical entry.
final Map<String, AllahName> _canonicalMap = {
  for (final n in allahNames) _normalise(n.transliteration): n,
};

/// Returns true if [name] matches a canonical Name of Allah.
bool isValidAllahName(String name) {
  return _canonicalNormalised.contains(_normalise(name));
}

/// Given a name string returned by Claude, find the closest canonical match.
/// Returns a record with name and nameArabic if found, null if it's a hallucination.
({String name, String nameArabic})? findCanonicalName(String name) {
  final key = _normalise(name);
  final entry = _canonicalMap[key];
  if (entry != null) {
    return (name: entry.transliteration, nameArabic: entry.arabic);
  }
  return null;
}

/// Filter a list of maps to only include valid Names.
/// Replaces name/nameArabic with canonical values where a match is found.
/// Each item must have 'name' and 'nameArabic' keys.
List<Map<String, dynamic>> filterValidNames(List<Map<String, dynamic>> names) {
  return names.fold<List<Map<String, dynamic>>>([], (acc, item) {
    final canonical = findCanonicalName(item['name'] as String);
    if (canonical != null) {
      acc.add({
        ...item,
        'name': canonical.name,
        'nameArabic': canonical.nameArabic,
      });
    }
    return acc;
  });
}

/// Build a compact canonical names reference string to inject into Claude prompts.
/// This constrains Claude to only use real Names.
String buildCanonicalNamesPromptList() {
  return allahNames
      .map((n) => '${n.transliteration} (${n.arabic}) — ${n.english}')
      .join('\n');
}
