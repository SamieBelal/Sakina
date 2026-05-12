/// Validates Names of Allah returned by Claude against the canonical 99 Names list.
/// Prevents hallucinated or non-standard names from appearing in the app.
library;

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

/// Pre-built normalised lookup set from the canonical list (including aliases).
final Set<String> _canonicalNormalised = _canonicalMap.keys.toSet();

/// Common AI transliteration variants → canonical Name. The AI sometimes
/// returns vowel-length variants (Al-Wakil vs canonical Al-Wakeel) or
/// dh↔z variants (Al-Dhahir vs canonical Az-Zahir). These map to the same
/// underlying Arabic Name, but `_normalise` doesn't collapse them because
/// a blanket `ee→i` rule would conflate Al-Majeed and Al-Majid (two
/// distinct Names). Keep this map small and only add entries the eval surfaces.
const Map<String, String> _transliterationAliases = {
  'Al-Wakil': 'Al-Wakeel',
  'Al-Dhahir': 'Az-Zahir',
  'Al-Halim': 'Al-Haleem',
  'Al-Latif': 'Al-Lateef',
};

/// Pre-built map from normalised key to canonical entry. Includes aliases
/// so AI-returned variants resolve to the same `AllahName` as their canonical form.
final Map<String, AllahName> _canonicalMap = () {
  final m = <String, AllahName>{
    for (final n in allahNames) _normalise(n.transliteration): n,
  };
  for (final entry in _transliterationAliases.entries) {
    final canonical = allahNames.firstWhere(
      (n) => n.transliteration == entry.value,
      orElse: () => throw StateError(
          'alias target ${entry.value} not in allahNames'),
    );
    m[_normalise(entry.key)] = canonical;
  }
  return m;
}();

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

/// Pre-built canonical names reference string. Compile-time once (the underlying
/// `allahNames` is const), reused across every AI call. Previously was a function
/// that rebuilt the same ~3KB string on every invocation (4 sites per reflect/
/// daily/findNames call) — pure waste since the input is const.
final String _canonicalNamesPromptList = allahNames
    .map((n) => '${n.transliteration} (${n.arabic}) — ${n.english}')
    .join('\n');

/// Build a compact canonical names reference string to inject into Claude prompts.
/// This constrains Claude to only use real Names.
String buildCanonicalNamesPromptList() => _canonicalNamesPromptList;
