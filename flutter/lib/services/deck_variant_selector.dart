/// Wave 5 — the deterministic variant selector
/// (plan `docs/superpowers/plans/2026-08-05-deck-ai-personalisation-plan.md`,
/// §4.3 + D8–D13).
///
/// **Nothing is ever generated here.** Every candidate line was authored,
/// founder-reviewed and cleared the ship gate before it reached the bundle;
/// this file only decides *which* of them a given reader meets, and answers
/// with an id. There is no network call, no model, no clock and no `Random` on
/// this path — same deck + same seen-set + same category always yields the same
/// answer, which is what "deterministic selector" means in the plan and what
/// makes the whole thing unit-testable.
///
/// **Where the policy boundary sits.** `buildBeatScreensFromDeck` promises
/// *"nothing is reordered, merged or dropped here"* and takes an
/// already-resolved `Map<String, String>` (beat kind → variant id). Rotation,
/// the seen set, the fallback ladder and persistence are policy, so they live
/// on this side of that seam. The builder never learns that any of it exists.
///
/// ---
///
/// ## The six closed decisions this file implements
///
/// * **D8 · The seen-set key is the composite `deck_id + beat_kind +
///   variant_id`**, never an array index and never a two-part key. Bridge and
///   reflection share the same seven category ids — `al-qahhar@1` carries a
///   `guilt` variant on *each*, two different sentences — so a two-part key
///   would mark a reflection line seen that the reader never met.
/// * **D9 · Selection is PAIRED.** One category id resolves both beats.
///   Rotation runs over the **bridge's** pool (every one of the 99 decks has
///   exactly one bridge; only 91 have a reflection), and the reflection simply
///   mirrors the chosen id — it takes the variant with that id if it carries
///   one and falls through to its own `primary` if it does not. The reflection
///   is never rotated independently.
/// * **D11 · No kill switch.** `primary` is the safety net: an empty selection
///   map is byte-identical to what shipped before personalisation existed.
/// * **D12 · Seen is marked on flow COMPLETION, not on selection.** [select] is
///   pure — it reads and never writes — and [markCompleted] is the separate
///   operation the caller invokes when the reader reaches the end. A flow that
///   is abandoned, backed out of or re-rolled leaves no trace and re-resolves
///   to the same id, because the seen set has not moved. When every pool member
///   for a deck has been seen the set is cleared and selection cycles rather
///   than freezing on `primary` — repetition is unavoidable by then, and
///   cycling is the better repetition.
/// * **D13 · One `deck_variant_selected` event on both surfaces**, segmented by
///   `source`, rather than two event names. Onboarding picks the deck BY the
///   chip, so its variant is contextual copy rather than a selection decision;
///   pooling the two into one "personalisation worked" number would let
///   onboarding volume swamp the only signal that means anything.
///
/// ## The pool is PRIORITISED, not flat — and this is the correction that
/// matters most
///
/// §4.3 reads *"pick the first unseen member of the pool"*, and a flat pool
/// inverts the Wave 2 authoring contract: **a category with nothing distinctive
/// to say carries NO variant and falls through to `primary` deliberately —
/// `primary` IS the authored text for that category.** A flat pool serves those
/// readers some *other* category's line instead. That is not a rare edge:
/// **195 of the 693 (deck, category) pairs have no variant of their own**, and
/// they are the ones where `primary` was written to answer.
///
/// The canonical example: `allah@1` carries `anxiety`, `heavy`, `guilt` and
/// `far_from_allah` and no `rizq`, because its `primary` — *"Some nights there
/// is no word for it. There is still a Name."* — already is the answer for a
/// reader the taxonomy placed elsewhere. A flat pool handed that reader the
/// anxiety line (*"A mind that will not stop…"*), which is about a different
/// problem.
///
/// So priority depends on whether the caller named a **known live category**:
///
/// ```
/// KNOWN CATEGORY C          UNMATCHED / NO CATEGORY
/// ─────────────────────     ───────────────────────────
/// 1  variant `C`            1  variant `default`   → fallback
///      → chip|category      2  __primary__         → fallback
/// 2  __primary__            3  remaining variants  → rotation
///      → chip|category
/// 3  variant `default`
///      → fallback
/// 4  remaining variants
///      → rotation
/// ```
///
/// **Why the two ladders disagree about `default` vs `primary`.** `default`
/// means *the no-category text* — it exists for `unmatched`, which is why only
/// the seven chip-echo decks carry one. For a KNOWN category, `primary` is the
/// author's answer and outranks `default`. For an UNMATCHED reader, `default`
/// outranks `primary`, because on those seven decks `primary` echoes a chip
/// label back (`as-salam@1`: *"For the weight you named — a mind that won't
/// stop racing"*) which is simply false for someone who named nothing. That
/// inversion is the whole point of Wave 2's chip-echo fix, and expressing it as
/// priority rather than as array order means the behaviour no longer depends on
/// where an author happened to put `default` in the JSON.
///
/// ## Two more things that are easy to get wrong
///
/// * **`primary` is a MEMBER of the pool, not the absence of one.** It is one
///   of the readings a returning user gets, so rotation consumes it like any
///   other and a second encounter moves past it to something genuinely new;
///   that is also why the ship gate forbids a variant from repeating it (a
///   duplicate would give one sentence two slots while the selector believed it
///   had rotated). It is represented by the [primaryVariantId] sentinel in the
///   seen set and by *no entry at all* in the selection map handed to the
///   builder.
/// * **`variants.isEmpty → primary` is NOT the main path**, whatever §4.3 says.
///   All 99 bridges and all 91 reflections carry variants, so that branch is
///   unreachable in shipped content and is exercised only by a synthetic deck.
///   It is handled — `source: fallback`, and uniquely, **nothing is ever
///   written down** — because a deck could be added without variants; it is not
///   designed around.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// ---------------------------------------------------------------------------
// Vocabulary
// ---------------------------------------------------------------------------

/// The deck wire kind of the opening personalisable beat. Rotation runs over
/// this beat's variant pool — every approved deck has exactly one.
const String deckBeatKindBridge = 'bridge';

/// The deck wire kind of the closing personalisable beat. Present on 91 of 99
/// decks; the 8 synergy-closers deliberately have none (D1).
const String deckBeatKindReflection = 'reflection';

/// The pool member standing for the beat's own `primary`.
///
/// Deliberately not a legal variant id (the gate pins variant ids to the live
/// chip taxonomy plus `default`, and none of them can start with an
/// underscore), so it can never collide with authored content in the seen set.
/// It appears in persisted keys and in the `variant_id` analytics property; it
/// never appears in the map handed to `buildBeatScreensFromDeck`, where
/// "render `primary`" is expressed by the absence of an entry.
const String primaryVariantId = '__primary__';

/// The variant id meaning *"the no-category text"*.
///
/// **Not a copy of `primary`** — the ship gate rejects a variant that repeats
/// anything else in the deck. It exists for the reader the taxonomy could not
/// place, which is why only the seven chip-echo decks carry one: they are the
/// decks whose `primary` echoes a chip label back and is therefore false for
/// exactly that reader. A KNOWN category outranks it (see the ladder on the
/// library docstring); an unmatched one is outranked by it.
const String defaultVariantId = 'default';

/// The seven live `problemCategory` values, read from the taxonomy itself so a
/// chip added or renamed in `problem_chips.dart` cannot leave a stale copy
/// here. `unmatched` is deliberately NOT a member — it is the *absence* of a
/// category, and routing it into the category branch would ask the deck for a
/// variant no deck carries.
final Set<String> liveProblemCategories = Set.unmodifiable({
  for (final chip in problemChips) chip.problemCategory,
});

/// Which surface asked for a selection. Decides only the `source` label a
/// category hit reports (D13) — the algorithm is identical on both.
enum DeckVariantSurface {
  /// The onboarding reveal. The deck was chosen BY the chip, so a category hit
  /// here is contextual copy rather than a personalisation decision, and it is
  /// reported as `chip` so the daily signal can be read without onboarding
  /// volume swamping it.
  onboarding(AnalyticsEvents.deckVariantSourceChip),

  /// The daily loop. The category came from `matchChipKeyForText()` over what
  /// the user actually wrote, against a deck drawn from the queue — the two
  /// were resolved independently, which is what makes a hit meaningful.
  daily(AnalyticsEvents.deckVariantSourceCategory);

  const DeckVariantSurface(this.matchedSource);

  /// The `source` value an EXACT answer for a known category reports on this
  /// surface — which covers both "the deck has a variant with that id" and "the
  /// deck deliberately has none because its `primary` is the answer". Both are
  /// hits, not misses; segment by `variant_id` to tell them apart.
  final String matchedSource;
}

/// The composite seen-set key (D8). Three parts, always, in this order.
String deckVariantSeenKey(String deckId, String beatKind, String variantId) =>
    '$deckId|$beatKind|$variantId';

// ---------------------------------------------------------------------------
// The selection
// ---------------------------------------------------------------------------

/// One resolved selection: what to render, what to report, and what to write
/// down if — and only if — the reader finishes the flow.
///
/// **Latch this at flow entry and hold it.** `muhasabah_screen.dart:507` builds
/// its screens inside `build()`, so a selection re-derived from live state
/// would let the bridge text swap while the user is reading it.
@immutable
class DeckVariantSelection {
  const DeckVariantSelection({
    required this.deckId,
    required this.variantId,
    required this.source,
    required this.reflectionMatched,
    required this.encounterIndex,
    required this.problemCategory,
    required this.cycled,
    required this.hasPool,
  });

  final String deckId;

  /// The chosen pool member: an authored variant id, or [primaryVariantId].
  final String variantId;

  /// `chip` | `category` | `rotation` | `fallback` — the
  /// `AnalyticsEvents.deckVariantSource*` constants.
  final String source;

  /// Whether the reflection beat carried [variantId] too. False whenever the
  /// deck has no reflection (the 8 synergy-closers), when the reflection's pool
  /// does not cover this category, and always when [isPrimary] — the pairing is
  /// on the *id*, and `primary` is not an id the reflection can carry.
  final bool reflectionMatched;

  /// How many times this deck's flow has been COMPLETED before this one; 0 on a
  /// first encounter. Survives the rotation cycle-clear, so it keeps counting
  /// across pool exhaustion.
  ///
  /// This is the property §6 calls `generation` — a name the plan never defines
  /// anywhere. Rather than invent a meaning for it, this ships the one number
  /// that was cheap and unambiguous.
  final int encounterIndex;

  /// The category the caller offered, verbatim: one of the seven, `unmatched`,
  /// or `none` when the caller had none at all.
  final String problemCategory;

  /// Whether the pool was exhausted and this selection came from a fresh cycle.
  /// [markCompleted] clears the deck's seen entries before recording when set.
  final bool cycled;

  /// Whether the deck offered anything to select from at all.
  ///
  /// False ONLY for the §4.3 `variants.isEmpty` shape (and a deck with no
  /// bridge beat) — unreachable in shipped content. It is the one case where
  /// nothing was chosen, so nothing is written down: [seenKeys] is empty, no
  /// rotation state ever accumulates, and the deck can never "exhaust".
  ///
  /// **Not the same thing as `source == fallback`.** A `fallback` selection on
  /// a deck that HAS a pool (`default` for an unmatched reader, or `primary`
  /// for one) is a real choice that must be marked seen, or the rotation would
  /// hand that reader the same line forever.
  final bool hasPool;

  /// Whether this renders the beats' own `primary` text.
  bool get isPrimary => variantId == primaryVariantId;

  /// Whether the taxonomy failed to place what the user said — the day-one
  /// input to the still-deferred D7 (§6).
  bool get categoryUnmatched => !liveProblemCategories.contains(problemCategory);

  /// The `selection` argument for `buildBeatScreensFromDeck`.
  ///
  /// Empty means "render every `primary`", which is byte-identical to the
  /// pre-personalisation output (pinned across all 99 decks by
  /// `test/widgets/beat_reveal_deck_test.dart`).
  Map<String, String> get selection => {
        if (!isPrimary) deckBeatKindBridge: variantId,
        if (reflectionMatched) deckBeatKindReflection: variantId,
      };

  /// The composite keys [markCompleted] records — exactly the beats the reader
  /// actually met, and nothing derivable-but-unread.
  ///
  /// D8's third part (the beat kind) is **defensive here, not load-bearing** —
  /// stated plainly because an earlier draft of this comment claimed otherwise
  /// and a reader would over-trust it. Rotation only ever reads BRIDGE keys
  /// (see `_firstUnseen`), and under D9's paired selection the reflection is
  /// shown with the bridge or not at all, so a two-part key would behave
  /// identically today.
  ///
  /// It earns its keep the moment either of those stops being true: `heavy` on
  /// the bridge and `heavy` on the reflection are DIFFERENT sentences
  /// (`al-qahhar@1` carries both), so a two-part key would silently mark one as
  /// read when the reader had only seen the other. Keeping the kind in the key
  /// means revisiting D9, or reading reflection state, cannot quietly become a
  /// bug — it costs one string segment to make a whole class of error
  /// unrepresentable.
  ///
  /// Gated on [hasPool], NOT on [source] — a `fallback` line the reader
  /// actually read still has to advance the rotation.
  List<String> get seenKeys => [
        if (hasPool) deckVariantSeenKey(deckId, deckBeatKindBridge, variantId),
        if (reflectionMatched)
          deckVariantSeenKey(deckId, deckBeatKindReflection, variantId),
      ];

  /// The `deck_variant_selected` payload (D13).
  Map<String, dynamic> get analyticsProperties => {
        AnalyticsEvents.propDeckId: deckId,
        AnalyticsEvents.propSource: source,
        AnalyticsEvents.propVariantId: variantId,
        AnalyticsEvents.propReflectionMatched: reflectionMatched,
        AnalyticsEvents.propEncounterIndex: encounterIndex,
        AnalyticsEvents.propProblemCategory: problemCategory,
        AnalyticsEvents.propCategoryUnmatched: categoryUnmatched,
      };
}

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

/// One deck's rotation bookkeeping.
@immutable
class DeckVariantDeckState {
  const DeckVariantDeckState({
    this.seen = const {},
    this.completedEncounters = 0,
  });

  /// Composite [deckVariantSeenKey] values.
  final Set<String> seen;

  /// Completed flows for this deck, ever. Deliberately NOT reset by the
  /// cycle-clear: it is a monotonic encounter counter, not pool state.
  final int completedEncounters;
}

/// The storage seam.
///
/// Injectable so a unit test never needs a real Supabase client or a
/// `SharedPreferences` binding — the default implementation reaches for both.
abstract interface class DeckVariantStore {
  Future<DeckVariantDeckState> read(String deckId);
  Future<void> write(String deckId, DeckVariantDeckState state);
}

/// The shipping store: one `SharedPreferences` entry per deck, **account-scoped
/// via [SupabaseSyncService.scopedKey]**.
///
/// The scoping is not decoration. Without it, two accounts on one device
/// inherit each other's rotation — the second user's first encounter with a
/// Name would silently skip whatever the first user had already read. The
/// suffix is `:<uid>`, which is also what `clearScopedPreferencesForUser` keys
/// its sign-out sweep on, so these entries are cleaned up with everything else.
///
/// ONBOARDING is the exception, because it runs before sign-up and therefore
/// has no uid to scope with — see [_adoptOnboardingEntry] for what that broke
/// and how the entry is claimed once an account exists.
///
/// Every operation swallows its failures. A prefs error must cost the rotation,
/// never the reveal: a failed read degrades to "first encounter" (the reader
/// gets an authored line either way) and a failed write degrades to "this
/// encounter did not happen".
class SharedPreferencesDeckVariantStore implements DeckVariantStore {
  const SharedPreferencesDeckVariantStore();

  /// Unscoped prefix; [SupabaseSyncService.scopedKey] adds the account suffix.
  @visibleForTesting
  static const String baseKeyPrefix = 'sakina_deck_variants_';

  static const String _seenField = 'seen';
  static const String _countField = 'n';

  String _key(String deckId) {
    try {
      return supabaseSyncService.scopedKey('$baseKeyPrefix$deckId');
    } catch (_) {
      // Supabase not initialised (a widget test, a very early launch). The
      // unscoped key is the same one an anonymous session would use.
      return '$baseKeyPrefix$deckId';
    }
  }

  @override
  Future<DeckVariantDeckState> read(String deckId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = await _adoptOnboardingEntry(prefs, deckId);
      if (raw == null) return const DeckVariantDeckState();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return DeckVariantDeckState(
        seen: ((json[_seenField] ?? const []) as List).cast<String>().toSet(),
        completedEncounters: (json[_countField] ?? 0) as int,
      );
    } catch (e) {
      debugPrint('[deck_variant_selector] seen-set read failed: $e');
      return const DeckVariantDeckState();
    }
  }

  /// Reads the entry, first CLAIMING any unscoped one left behind by
  /// onboarding.
  ///
  /// **Onboarding is always signed out, so it always writes the bare key.** The
  /// reveal fires `markCompleted` on page 1 of the reel flow; sign-up is pages
  /// 15-17 and there is no anonymous Supabase session anywhere in the app. So
  /// `scopedKey` has no uid to append and the rotation lands at
  /// `sakina_deck_variants_<deckId>` with no suffix.
  ///
  /// Two things went wrong with that, and this fixes both:
  ///
  ///  * **A second account on the same device inherited the first one's
  ///    rotation.** User A onboards and names a weight; user B signs up on the
  ///    same phone, names the same weight, and the reveal answers with the
  ///    generic line because A already consumed the authored one. That is the
  ///    first thing B ever sees, and it is the exact failure this class's
  ///    docstring claims the scoping prevents.
  ///  * **The sign-out sweep could never reach it.**
  ///    `clearScopedPreferencesForUser` matches on the `:<uid>` suffix, so an
  ///    unscoped entry survived every sign-out forever.
  ///
  /// The claim is the same move `SupabaseSyncService.migrateLegacyStringCache`
  /// makes for every other pre-auth cache: once a uid exists, the bare entry
  /// becomes that account's and the bare key is removed. It runs on READ rather
  /// than at sign-in because there is no sign-in hook this service can see, and
  /// a read is guaranteed to happen before the rotation can matter.
  ///
  /// **The residual case, stated rather than hidden:** a user who onboards and
  /// never signs up leaves the bare entry behind, because nothing ever calls
  /// this with a uid. A second onboarding on that device still inherits it.
  /// Closing that needs a device-scoped pre-auth key, which is a bigger change
  /// than the bug justifies — the common path is that people sign up.
  Future<String?> _adoptOnboardingEntry(
    SharedPreferences prefs,
    String deckId,
  ) async {
    final base = '$baseKeyPrefix$deckId';
    try {
      // Signed out: the bare key IS our key, and there is nothing to claim.
      if (supabaseSyncService.currentUserId == null) {
        return prefs.getString(base);
      }
      return await supabaseSyncService.migrateLegacyStringCache(prefs, base);
    } catch (_) {
      // Supabase not initialised (a widget test, a very early launch).
      return prefs.getString(base);
    }
  }

  @override
  Future<void> write(String deckId, DeckVariantDeckState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(deckId),
        jsonEncode({
          // Sorted so the persisted bytes are a function of the set's contents
          // and not of Dart's iteration order — a stable file is a debuggable
          // one, and it costs nothing at this size.
          _seenField: state.seen.toList()..sort(),
          _countField: state.completedEncounters,
        }),
      );
    } catch (e) {
      debugPrint('[deck_variant_selector] seen-set write failed: $e');
    }
  }
}

/// In-memory store for tests and for any caller that wants rotation without
/// persistence.
@visibleForTesting
class InMemoryDeckVariantStore implements DeckVariantStore {
  final Map<String, DeckVariantDeckState> _states = {};

  @override
  Future<DeckVariantDeckState> read(String deckId) async =>
      _states[deckId] ?? const DeckVariantDeckState();

  @override
  Future<void> write(String deckId, DeckVariantDeckState state) async {
    _states[deckId] = state;
  }
}

// ---------------------------------------------------------------------------
// The selector
// ---------------------------------------------------------------------------

/// Chip/category → variant id, with seen-set rotation over the bridge's pool.
///
/// Static, hook-based and Riverpod-free, like every other service that emits
/// analytics (`CLAUDE.md`: *"emit from providers via the static
/// `onAnalyticsEvent` hook pattern (no Riverpod in services)"*).
abstract final class DeckVariantSelector {
  /// `main.dart` wires this; tests leave it null, which makes emission a no-op.
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  /// The persistence seam. Replace it in tests; leave it alone in the app.
  @visibleForTesting
  static DeckVariantStore store = const SharedPreferencesDeckVariantStore();

  /// Resolves the variant pair for one encounter with [deck] and emits
  /// `deck_variant_selected`.
  ///
  /// **Reads, never writes** (D12). Call [markCompleted] with the returned
  /// selection when the reader reaches the end of the flow; a selection that is
  /// never completed leaves nothing behind, so backing out and re-entering
  /// re-resolves to the same id.
  ///
  /// [problemCategory] is a `problemCategory` value from the live taxonomy,
  /// `problemCategoryUnmatched`, or null when the caller has none. It is NOT a
  /// `chipKey` — the two vocabularies differ (`far-from-allah` vs
  /// `far_from_allah`), and the variant ids follow the category.
  static Future<DeckVariantSelection> select({
    required NameStoryDeck deck,
    required DeckVariantSurface surface,
    String? problemCategory,
  }) async {
    DeckVariantDeckState state;
    try {
      state = await store.read(deck.deckId);
    } catch (e) {
      debugPrint('[deck_variant_selector] store read threw: $e');
      state = const DeckVariantDeckState();
    }
    final selection = resolve(
      deck: deck,
      surface: surface,
      problemCategory: problemCategory,
      seen: state.seen,
      encounterIndex: state.completedEncounters,
    );
    onAnalyticsEvent?.call(
      AnalyticsEvents.deckVariantSelected,
      selection.analyticsProperties,
    );
    return selection;
  }

  /// The pure core: no I/O, no clock, no randomness. Everything the algorithm
  /// depends on is an argument, which is what lets the whole §4.3 diagram be
  /// tested without a store.
  ///
  /// Resolution is a PRIORITISED candidate list (see the library docstring for
  /// why it is not a flat pool), walked until an unseen member is found:
  ///
  /// **Known live category `C`** — 1. variant `C` · 2. `primary` · 3. `default`
  /// · 4. the remaining variants in asset order. The first two are exact
  /// answers for `C` and report `chip`/`category`; `default` is the
  /// no-category text and reports `fallback`; the rest report `rotation`.
  ///
  /// **`unmatched` / no category** — 1. `default` · 2. `primary` · 3. the
  /// remaining variants in asset order. The first two report `fallback` (there
  /// was no category to answer); the rest report `rotation`.
  ///
  /// Then, either way: **everything seen → clear the deck's set (functionally
  /// here; the write happens in [markCompleted]) and walk the same list again
  /// from the top** with [DeckVariantSelection.cycled] set. The list is never
  /// empty at that point, so this always resolves.
  ///
  /// The one exception is the **no-pool** shape — a bridge with no variants, or
  /// no bridge at all. Nothing is selected, every beat renders `primary`, the
  /// source is `fallback` and nothing is ever written down.
  @visibleForTesting
  static DeckVariantSelection resolve({
    required NameStoryDeck deck,
    required DeckVariantSurface surface,
    String? problemCategory,
    Set<String> seen = const {},
    int encounterIndex = 0,
  }) {
    final category = problemCategory == null || problemCategory.isEmpty
        ? AnalyticsEvents.deckVariantCategoryNone
        : problemCategory;

    final bridge = _beatOfKind(deck, deckBeatKindBridge);
    final variantIds =
        bridge?.variants.map((v) => v.id).toList(growable: false) ??
            const <String>[];

    if (variantIds.isEmpty) {
      // §4.3's `variants.isEmpty → primary`. Unreachable in shipped content.
      return DeckVariantSelection(
        deckId: deck.deckId,
        variantId: primaryVariantId,
        source: AnalyticsEvents.deckVariantSourceFallback,
        reflectionMatched: false,
        encounterIndex: encounterIndex,
        problemCategory: category,
        cycled: false,
        hasPool: false,
      );
    }

    final candidates = _candidates(category, variantIds, surface);

    var cycled = false;
    var chosen = _firstUnseen(candidates, seen, deck.deckId);
    if (chosen == null) {
      // D12 — every member seen. Cycle rather than freeze on `primary`.
      cycled = true;
      chosen = _firstUnseen(candidates, const {}, deck.deckId);
    }
    // The candidate list always contains `primary`, and the second pass sees an
    // empty seen-set, so it always answers. Belt and braces for a future edit.
    chosen ??= (primaryVariantId, AnalyticsEvents.deckVariantSourceFallback);

    final (id, source) = chosen;
    final isPrimary = id == primaryVariantId;
    final reflection = _beatOfKind(deck, deckBeatKindReflection);

    return DeckVariantSelection(
      deckId: deck.deckId,
      variantId: id,
      source: source,
      // D9 — the reflection MIRRORS the bridge's id and is never rotated on its
      // own. No variant with that id (or no reflection beat at all) simply
      // falls through to the reflection's `primary`.
      reflectionMatched: !isPrimary &&
          (reflection?.variants.any((v) => v.id == id) ?? false),
      encounterIndex: encounterIndex,
      problemCategory: category,
      cycled: cycled,
      hasPool: true,
    );
  }

  /// The priority-ordered `(variantId, source)` list for one category. Pure and
  /// total — it always contains [primaryVariantId], so it is never empty.
  ///
  /// The two ladders differ only in where `primary` and `default` sit, which is
  /// the entire Wave 2 authoring contract expressed as code: for a category the
  /// deck knows about, `primary` is the author's answer and outranks the
  /// no-category text; for a reader nobody could place, it is the other way
  /// round.
  static List<(String, String)> _candidates(
    String category,
    List<String> variantIds,
    DeckVariantSurface surface,
  ) {
    const fallback = AnalyticsEvents.deckVariantSourceFallback;
    const rotation = AnalyticsEvents.deckVariantSourceRotation;
    final hasDefault = variantIds.contains(defaultVariantId);

    if (liveProblemCategories.contains(category)) {
      return [
        // 1 — the line written for exactly this category.
        if (variantIds.contains(category)) (category, surface.matchedSource),
        // 2 — no such variant BECAUSE `primary` is the answer for it. Still an
        // exact answer, so still a hit: 195 of 693 (deck, category) pairs land
        // here, and calling them `fallback` would both mis-describe them and
        // make the >35% fallback alarm meaningless.
        (primaryVariantId, surface.matchedSource),
        // 3 — the no-category text. A miss for a reader who DID name something.
        if (hasDefault) (defaultVariantId, fallback),
        // 4 — somebody else's category. Only ever reached on a repeat visit.
        for (final id in variantIds)
          if (id != category && id != defaultVariantId) (id, rotation),
      ];
    }

    return [
      // 1 — written for precisely this reader: the one who named nothing.
      if (hasDefault) (defaultVariantId, fallback),
      // 2 — the authored default. On the seven chip-echo decks it is the line
      // that assumes a chip was tapped, which is why `default` outranks it.
      (primaryVariantId, fallback),
      // 3 — a category the reader never named. Repeat visits only.
      for (final id in variantIds)
        if (id != defaultVariantId) (id, rotation),
    ];
  }

  /// The first candidate this reader has not already met. Null means every one
  /// of them is seen — the cycle trigger.
  static (String, String)? _firstUnseen(
    List<(String, String)> candidates,
    Set<String> seen,
    String deckId,
  ) {
    for (final candidate in candidates) {
      final key = deckVariantSeenKey(deckId, deckBeatKindBridge, candidate.$1);
      if (!seen.contains(key)) return candidate;
    }
    return null;
  }

  /// Records [selection] as read. Call once, when the flow COMPLETES (D12).
  ///
  /// Clears the deck's seen entries first when the selection came from a fresh
  /// cycle, so the write is the whole new state rather than an append onto an
  /// exhausted set. [DeckVariantDeckState.completedEncounters] survives the
  /// clear.
  static Future<void> markCompleted(DeckVariantSelection selection) async {
    try {
      final prior = await store.read(selection.deckId);
      final seen = selection.cycled ? <String>{} : {...prior.seen};
      seen.addAll(selection.seenKeys);
      await store.write(
        selection.deckId,
        DeckVariantDeckState(
          seen: seen,
          completedEncounters: prior.completedEncounters + 1,
        ),
      );
    } catch (e) {
      // Bookkeeping must never take the flow down with it — the reader has
      // already finished; the only cost is one repeated line later.
      debugPrint('[deck_variant_selector] markCompleted failed: $e');
    }
  }

  static NameStoryBeat? _beatOfKind(NameStoryDeck deck, String kind) {
    for (final beat in deck.beats) {
      if (beat.kind == kind) return beat;
    }
    return null;
  }
}
