import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';

const String _selectedTitleKey = 'sakina_selected_title';
const String _titleAutoModeKey = 'sakina_title_auto_mode';
const String _prefsDirtyKey = 'sakina_title_prefs_dirty';
const String _legacyUnlockedTitlesKey = 'sakina_unlocked_titles';

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
  final isAuto =
      prefs.getBool(supabaseSyncService.scopedKey(_titleAutoModeKey)) ?? true;

  if (isAuto) {
    final level = xpLevels.where((l) => l.level == currentLevel).firstOrNull ?? xpLevels.first;
    return (title: level.title, titleArabic: level.titleArabic, isAuto: true);
  }

  final selected = prefs.getString(supabaseSyncService.scopedKey(_selectedTitleKey));
  if (selected != null && selected.isNotEmpty) {
    final arabic = titleToArabic(selected) ?? '';
    return (title: selected, titleArabic: arabic, isAuto: false);
  }

  // Fallback to auto
  final level = xpLevels.where((l) => l.level == currentLevel).firstOrNull ?? xpLevels.first;
  return (title: level.title, titleArabic: level.titleArabic, isAuto: true);
}

/// Derive unlocked titles from the user's current XP level and longest streak.
/// Pure function — no SharedPreferences read.
List<String> getUnlockedTitles({
  required int currentLevel,
  required int longestStreak,
}) {
  final titles = <String>[];
  for (final level in xpLevels) {
    if (level.level <= currentLevel && level.unlocksTitle) {
      titles.add(level.title);
    }
  }
  for (final milestone in streakMilestones) {
    final unlock = milestone.titleUnlock;
    if (unlock != null && milestone.days <= longestStreak) {
      titles.add(unlock);
    }
  }
  return titles;
}

/// Select a title manually (disables auto mode).
/// Writes to scoped local prefs and pushes to Supabase user_profiles.
Future<void> selectTitle(String title) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      supabaseSyncService.scopedKey(_selectedTitleKey), title);
  await prefs.setBool(
      supabaseSyncService.scopedKey(_titleAutoModeKey), false);
  await _pushTitlePrefs(selectedTitle: title, isAutoTitle: false);
}

/// Reset to auto mode (title follows current level).
Future<void> setAutoTitle() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(
      supabaseSyncService.scopedKey(_titleAutoModeKey), true);
  await prefs.remove(supabaseSyncService.scopedKey(_selectedTitleKey));
  await _pushTitlePrefs(selectedTitle: null, isAutoTitle: true);
}

/// Push title preferences to Supabase user_profiles.
/// Sets a dirty flag before attempting the write so a failed push can be
/// retried from [hydrateTitlePrefsCache] on next sign-in.
Future<void> _pushTitlePrefs({
  required String? selectedTitle,
  required bool isAutoTitle,
}) async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) {
    // Anonymous — no server to push to, no dirty flag needed.
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  // Mark dirty BEFORE the push so a crash mid-push still leaves a breadcrumb.
  await prefs.setBool(supabaseSyncService.scopedKey(_prefsDirtyKey), true);
  final ok = await supabaseSyncService.upsertRawRow('user_profiles', {
    'id': userId,
    'selected_title': selectedTitle,
    'is_auto_title': isAutoTitle,
  });
  if (ok) {
    await prefs.remove(supabaseSyncService.scopedKey(_prefsDirtyKey));
  }
  // else: dirty flag stays set, next hydrate cycle will retry.
}

/// Migrate legacy unscoped title prefs into the current user's scoped keys
/// and retire the obsolete `sakina_unlocked_titles` cache.
///
/// Does NOT clear local state — if the subsequent hydration RPC fails, the
/// migrated local values remain and [getDisplayTitle] keeps working.
Future<void> prepareTitlePrefsCacheForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await supabaseSyncService.migrateLegacyStringCache(prefs, _selectedTitleKey);
  await supabaseSyncService.migrateLegacyBoolCache(prefs, _titleAutoModeKey);
  // Retire the unlocked-titles cache — unlocks are now derived on read.
  await prefs.remove(_legacyUnlockedTitlesKey);
}

/// Hydrate the local title prefs cache from a server payload.
///
/// Reconciles dirty state: if the local copy has pending unpushed changes,
/// push them first before overwriting with the server's view. On push
/// failure the dirty flag is preserved and local values are NOT overwritten.
Future<void> hydrateTitlePrefsCache({
  required String? selectedTitle,
  required bool isAutoTitle,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final dirtyKey = supabaseSyncService.scopedKey(_prefsDirtyKey);
  final isDirty = prefs.getBool(dirtyKey) ?? false;

  if (isDirty) {
    // Push local values up before accepting remote values.
    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      final localSelected =
          prefs.getString(supabaseSyncService.scopedKey(_selectedTitleKey));
      final localAuto =
          prefs.getBool(supabaseSyncService.scopedKey(_titleAutoModeKey)) ??
              true;
      final ok = await supabaseSyncService.upsertRawRow('user_profiles', {
        'id': userId,
        'selected_title': localSelected,
        'is_auto_title': localAuto,
      });
      if (!ok) {
        // Push failed — keep dirty flag, do NOT overwrite local state.
        return;
      }
      await prefs.remove(dirtyKey);
    }
  }

  // Write the (now authoritative) remote values into the scoped local cache.
  final selectedScoped = supabaseSyncService.scopedKey(_selectedTitleKey);
  final autoScoped = supabaseSyncService.scopedKey(_titleAutoModeKey);
  if (selectedTitle != null && selectedTitle.isNotEmpty) {
    await prefs.setString(selectedScoped, selectedTitle);
  } else {
    await prefs.remove(selectedScoped);
  }
  await prefs.setBool(autoScoped, isAutoTitle);
}
