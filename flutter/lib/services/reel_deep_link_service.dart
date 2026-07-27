import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/onboarding/content/problem_chips.dart';
import 'card_collection_service.dart' show allCollectibleNames;

/// The reel flow's two inbound links (One Ship W2-E4), cloned from the
/// `pending_referral` pattern in `main.dart`:
///
///   * `sakina://reel/<id>` — a specific reel sent this user. Optional
///     `?name_ids=12,34` overrides the pair the hook would have resolved, so a
///     reel that named two Names on camera reveals exactly those.
///   * `sakina://feel/<emotion>` — pre-selects a hook card.
///
/// The parsers are pure and the prefs keys are UNSCOPED, for the same reason
/// the referral key is: the link fires before the user has an account. The link
/// arrives during cold launch, minutes before onboarding renders, so the
/// capture (`main.dart`, before `runApp`) and the drain (the onboarding screen's
/// entry) are separated by prefs rather than by a callback.
///
/// Everything here is best-effort: a malformed link is silently ignored. There
/// is no user to tell — they tapped a link and expect the app, not an error.

/// Captured `sakina://reel/<id>` payload, awaiting the onboarding entry.
const String pendingReelArrivalPrefsKey = 'pending_reel_arrival';

/// Captured `sakina://feel/<emotion>` chip key, awaiting the hook screen.
const String pendingFeelChipPrefsKey = 'pending_feel_chip';

/// Reel ids are opaque campaign slugs. Capped so a hostile
/// `sakina://reel/<10KB blob>` cannot bloat SharedPreferences, and charset-
/// restricted so the value is safe to carry as an analytics property.
const int reelIdMaxLength = 64;

/// URL-slug charset: the id ends up in `acquisition_promise.reel_id`.
final RegExp reelIdRegex = RegExp(r'^[A-Za-z0-9_-]+$');

/// A pair is exactly two Names — [reelNameIdsLength] is a length, not a cap
/// that a shorter list may sit under. Half an override is not an override.
const int reelNameIdsLength = 2;

/// Emotion slugs are chip keys or short phrases; same bloat guard.
const int feelEmotionMaxLength = 64;

/// What a `sakina://reel/<id>` link said.
class ReelArrival {
  const ReelArrival({required this.reelId, this.nameIds = const []});

  final String reelId;

  /// The `name_ids` pair override, or empty when the link named no Names (the
  /// common case — the hook screen resolves the pair as usual).
  final List<int> nameIds;

  Map<String, dynamic> toJson() => {
        'reel_id': reelId,
        if (nameIds.isNotEmpty) 'name_ids': nameIds,
      };

  /// Re-validates on the way out as well as in: the prefs blob is only as
  /// trustworthy as the build that wrote it, and a catalog id that was valid
  /// under an older catalog must not reveal a Name that no longer exists.
  static ReelArrival? fromJson(Map<String, dynamic> json) {
    final id = json['reel_id'];
    if (id is! String || !_isValidReelId(id)) return null;
    final raw = json['name_ids'];
    if (raw is! List) return ReelArrival(reelId: id);
    return ReelArrival(
      reelId: id,
      nameIds: _validatedPair([
        for (final e in raw) e is num ? e.toInt() : null,
      ]),
    );
  }
}

bool _isValidReelId(String id) =>
    id.isNotEmpty && id.length <= reelIdMaxLength && reelIdRegex.hasMatch(id);

/// `sakina://reel/<id>[?name_ids=a,b]` → the arrival, or null when the URI is
/// not a reel link or the id is malformed.
///
/// A bad `name_ids` does NOT reject the link — the reel id is the arrival
/// record, and losing it because a query parameter was junk would erase the
/// only evidence the reel sent this user. The override alone is dropped.
ReelArrival? extractReelArrival(Uri uri) {
  if (uri.scheme != 'sakina' || uri.host != 'reel') return null;
  if (uri.pathSegments.isEmpty) return null;
  final id = uri.pathSegments.first;
  if (!_isValidReelId(id)) return null;
  return ReelArrival(
    reelId: id,
    nameIds: parseReelNameIdsOverride(uri.queryParameters['name_ids']),
  );
}

/// `12,34` → `[12, 34]`; anything else → empty.
///
/// All-or-nothing by design. A partly-honoured override would reveal one Name
/// the reel promised and one it did not, which is worse than ignoring the
/// parameter and letting the hook resolve both.
List<int> parseReelNameIdsOverride(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final parts = raw.split(',');
  // Checked before parsing so a 10k-element list is rejected, not walked.
  if (parts.length != reelNameIdsLength) return const [];
  return _validatedPair([
    for (final part in parts) int.tryParse(part.trim()),
  ]);
}

List<int> _validatedPair(List<int?> candidates) {
  if (candidates.length != reelNameIdsLength) return const [];
  final ids = <int>[];
  for (final id in candidates) {
    if (id == null) return const [];
    if (!allCollectibleNames.any((name) => name.id == id)) return const [];
    // Two of the same Name is not a pair — Name₂ would be revealed already.
    if (ids.contains(id)) return const [];
    ids.add(id);
  }
  return List.unmodifiable(ids);
}

/// `sakina://feel/<emotion>` → the hook chip key to pre-select, or null.
///
/// Accepts a taxonomy key verbatim (`sakina://feel/far-from-allah`) and,
/// failing that, runs the same keyword map the free-text box uses — so a reel
/// can link `sakina://feel/overwhelmed` without knowing the taxonomy. An
/// emotion that matches nothing yields null: pre-selecting the comfort chip
/// would claim an answer on the user's behalf.
String? extractFeelChip(Uri uri) {
  if (uri.scheme != 'sakina' || uri.host != 'feel') return null;
  if (uri.pathSegments.isEmpty) return null;
  final raw = uri.pathSegments.first;
  if (raw.isEmpty || raw.length > feelEmotionMaxLength) return null;
  if (problemChipsByKey.containsKey(raw)) return raw;
  return matchChipKeyForText(raw);
}

/// Persists whichever of the two links [uri] is. Called from `main.dart` for
/// both the cold-launch URI and every warm-launch one.
Future<void> captureReelDeepLink(Uri uri) async {
  final arrival = extractReelArrival(uri);
  if (arrival != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      pendingReelArrivalPrefsKey,
      jsonEncode(arrival.toJson()),
    );
    return;
  }
  final chip = extractFeelChip(uri);
  if (chip != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingFeelChipPrefsKey, chip);
  }
}

/// Reads and clears the captured reel arrival. Cleared on read so a second
/// onboarding run (sign-out → sign-up) does not re-attribute to an old reel.
Future<ReelArrival?> consumePendingReelArrival() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(pendingReelArrivalPrefsKey);
  if (raw == null) return null;
  await prefs.remove(pendingReelArrivalPrefsKey);
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return ReelArrival.fromJson(decoded);
  } catch (_) {
    return null;
  }
}

/// Reads and clears the captured feel chip.
Future<String?> consumePendingFeelChip() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(pendingFeelChipPrefsKey);
  if (raw == null) return null;
  await prefs.remove(pendingFeelChipPrefsKey);
  // A chip that has since left the taxonomy is not a chip we can pre-select.
  return problemChipsByKey.containsKey(raw) ? raw : null;
}
