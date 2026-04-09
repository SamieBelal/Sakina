import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/streak_service.dart';

const String _selectedTitleKey = 'sakina_selected_title';
const String _unlockedTitlesKey = 'sakina_unlocked_titles';
const String _titleAutoModeKey = 'sakina_title_auto_mode';

/// Look up the Arabic version of an English title from xpLevels.
String? titleToArabic(String englishTitle) {
  // Check level titles
  final levelMatch = xpLevels.where((l) => l.title == englishTitle).firstOrNull;
  if (levelMatch != null) return levelMatch.titleArabic;
  // Check streak milestone titles
  final streakMatch = streakMilestones.where((m) => m.titleUnlock == englishTitle).firstOrNull;
  return streakMatch?.titleUnlockArabic;
}

/// Get the title the user should display.
/// Auto mode: returns current level's title.
/// Manual mode: returns the user's selected title.
Future<({String title, String titleArabic, bool isAuto})> getDisplayTitle(int currentLevel) async {
  final prefs = await SharedPreferences.getInstance();
  final isAuto = prefs.getBool(_titleAutoModeKey) ?? true;

  if (isAuto) {
    final level = xpLevels.where((l) => l.level == currentLevel).firstOrNull ?? xpLevels.first;
    return (title: level.title, titleArabic: level.titleArabic, isAuto: true);
  }

  final selected = prefs.getString(_selectedTitleKey);
  if (selected != null && selected.isNotEmpty) {
    final arabic = titleToArabic(selected) ?? '';
    return (title: selected, titleArabic: arabic, isAuto: false);
  }

  // Fallback to auto
  final level = xpLevels.where((l) => l.level == currentLevel).firstOrNull ?? xpLevels.first;
  return (title: level.title, titleArabic: level.titleArabic, isAuto: true);
}

/// Get list of all unlocked title names (English).
Future<List<String>> getUnlockedTitles() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_unlockedTitlesKey);
  if (raw == null) return ['Seeker']; // default
  final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
  return list;
}

/// Unlock a new title. Idempotent.
Future<void> unlockTitle(String title) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await getUnlockedTitles();
  if (!current.contains(title)) {
    current.add(title);
    await prefs.setString(_unlockedTitlesKey, jsonEncode(current));
  }
}

/// Select a title manually (disables auto mode).
Future<void> selectTitle(String title) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_selectedTitleKey, title);
  await prefs.setBool(_titleAutoModeKey, false);
}

/// Reset to auto mode (title follows current level).
Future<void> setAutoTitle() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_titleAutoModeKey, true);
  await prefs.remove(_selectedTitleKey);
}

/// Initialize unlocked titles for a user based on their current level.
/// Unlocks all milestone titles at or below their level.
/// Call on first load or migration.
Future<void> initializeUnlockedTitles(int currentLevel) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_unlockedTitlesKey);
  if (existing != null) return; // already initialized

  final titles = <String>[];
  for (final level in xpLevels) {
    if (level.level <= currentLevel && level.unlocksTitle) {
      titles.add(level.title);
    }
  }
  if (titles.isEmpty) titles.add('Seeker');
  await prefs.setString(_unlockedTitlesKey, jsonEncode(titles));
}
