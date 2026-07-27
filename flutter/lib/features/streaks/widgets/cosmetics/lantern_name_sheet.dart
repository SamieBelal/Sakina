import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// E3 — name-your-lantern. OQ-D2: no server column exists yet (DEP-D1), so the
// name is persisted to user-scoped SharedPreferences today. When Lane A ships
// user_profiles.lantern_name + a sync section, the read path swaps to the sync
// cache with no change to this widget.

const String _lanternNameKey = 'sakina_lantern_name';
const int _maxLanternNameLen = 20;

/// Shown until the user names their lantern.
const String defaultLanternName = 'Your lantern';

// Minimal blocklist — a UI guard, not moderation. Server-side moderation is out
// of scope for a field that is never shared with other users.
//
// Split deliberately: short tokens are matched as whole words only, because a
// substring match on 'ass' would reject "Compassion" — a far likelier name than
// the one it would block.
const Set<String> _blockedSubstrings = {'shit', 'fuck', 'bitch', 'cunt'};
const Set<String> _blockedWords = {'ass', 'damn'};

/// Unicode bidi/zero-width/control characters. Rejected because they let a name
/// reorder the surrounding LTR UI (the same RTL-bleed class of bug the design
/// system bans mixed-direction `Text` for) and enable homograph spoofing.
// Escapes, not literals: these code points are invisible in source and the
// analyzer flags raw ones (text_direction_code_point_in_literal).
final RegExp _controlChars = RegExp(
    r'[\u0000-\u001F\u007F\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]');

final RegExp _wordSplit = RegExp(r'[^a-z]+');

/// Returns a user-facing error message if [name] is invalid, else null.
String? validateLanternName(String name) {
  if (_controlChars.hasMatch(name)) {
    return 'That name has invalid characters';
  }
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Give your lantern a name';
  if (trimmed.characters.length > _maxLanternNameLen) {
    return 'Keep it under $_maxLanternNameLen characters';
  }
  final lower = trimmed.toLowerCase();
  for (final w in _blockedSubstrings) {
    if (lower.contains(w)) return 'Please choose another name';
  }
  final words = lower.split(_wordSplit).where((w) => w.isNotEmpty);
  for (final w in words) {
    if (_blockedWords.contains(w)) return 'Please choose another name';
  }
  return null;
}

/// The saved lantern name, or null if unset. Returns null (never throws) when
/// the pref store or the user scope is unavailable — a naming pref must never
/// take the Companion stage down with it.
Future<String?> readLanternName() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(supabaseSyncService.scopedKey(_lanternNameKey));
  } catch (_) {
    return null;
  }
}

/// Persists the trimmed [name] under the user-scoped key.
Future<void> saveLanternName(String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      supabaseSyncService.scopedKey(_lanternNameKey), name.trim());
}

/// Opens the rename sheet; resolves to the saved name, or null if cancelled.
Future<String?> showLanternNameSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundLight,
    builder: (_) => _LanternNameSheet(current: current),
  );
}

class _LanternNameSheet extends StatefulWidget {
  const _LanternNameSheet({this.current});

  final String? current;

  @override
  State<_LanternNameSheet> createState() => _LanternNameSheetState();
}

class _LanternNameSheetState extends State<_LanternNameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final error = validateLanternName(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final name = _controller.text.trim();
    try {
      await saveLanternName(name);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = "Couldn't save that name. Please try again.";
      });
      return;
    }
    if (mounted) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name your lantern',
              style: AppTypography.headlineMedium
                  .copyWith(color: AppColors.textPrimaryLight)),
          const SizedBox(height: AppSpacing.sm),
          Text('Only you will see this.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: _maxLanternNameLen,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              errorText: _error,
              hintText: 'Noor',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
