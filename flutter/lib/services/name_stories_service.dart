import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:sakina/models/name_story_deck.dart';

// TODO(content): ar-rahman@1's comfort_verse quotes 2:286 in the Saheeh
// International rendering (founder-decided 2026-07-25). Confirm the tagged
// entry in `reflection_verse_catalog.dart` displays THAT rendering — if it
// carries a different translation, the beat must source the SI text with
// attribution. Tracked here rather than in the asset's editorial label, which
// ships as content.

/// Reads the bundled Name-story decks (`assets/content/name_stories.json`).
///
/// Asset-only by design: there is no `name_stories` table, so there is no
/// server/asset drift to reconcile and the whole onboarding reveal works before
/// the user has an account. The contract shape mirrors the public-catalog
/// services so a server refresh path can be bolted on later without reshaping
/// callers.
///
/// The real approval gate is `test/content/name_stories_ship_gate_test.dart`
/// (an unapproved deck fails CI). [_parse] keeps a belt-and-braces runtime
/// filter anyway: a deck whose `review_verdict` is not `good` is dropped, so
/// unreviewed scripture cannot reach a screen even if the gate is bypassed.
class NameStoriesService {
  NameStoriesService({Future<String> Function(String assetPath)? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.loadString;

  static const String assetPath = 'assets/content/name_stories.json';

  /// The chip whose pair doubles as the fallback when free text matches nothing
  /// and when a chip's own pair is unavailable.
  static const String comfortChipKey = 'sign';

  final Future<String> Function(String assetPath) _loadAsset;

  List<NameStoryDeck>? _decks;
  Future<List<NameStoryDeck>>? _loading;

  /// Every approved deck, parsed once and cached for the process lifetime.
  /// Concurrent first calls share one decode.
  Future<List<NameStoryDeck>> decks() {
    final cached = _decks;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load();
  }

  Future<List<NameStoryDeck>> _load() async {
    try {
      final parsed = _parse(await _loadAsset(assetPath));
      _decks = parsed;
      return parsed;
    } finally {
      _loading = null;
    }
  }

  List<NameStoryDeck> _parse(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((d) => NameStoryDeck.fromJson(d as Map<String, dynamic>))
        .where((d) => d.reviewVerdict == 'good')
        .toList(growable: false);
  }

  /// The approved decks for [chipKey], ordered Name₁ then Name₂.
  ///
  /// A chip is only renderable when this returns BOTH halves: an unapproved or
  /// missing partner yields a short list, and the caller falls back to
  /// [comfortPair] rather than revealing half a pair.
  Future<List<NameStoryDeck>> decksForChip(String chipKey) async {
    // `where().toList()` is already a fresh list, so sorting it in place can
    // never reorder the cached list shared with every other caller.
    final pair = (await decks())
        .where((d) => d.chipKeys.contains(chipKey))
        .toList(growable: false);
    return pair..sort((a, b) => a.positionInPair.compareTo(b.positionInPair));
  }

  /// The deck teaching the Name with [nameId], or null when none is approved.
  Future<NameStoryDeck?> deckForName(int nameId) async {
    for (final d in await decks()) {
      if (d.nameId == nameId) return d;
    }
    return null;
  }

  /// The comfort pair (the `sign` chip's decks) — what unmatched free text and
  /// any uncovered chip reveal instead.
  Future<List<NameStoryDeck>> comfortPair() => decksForChip(comfortChipKey);
}

/// Process-wide instance (same idiom as the other asset/catalog services).
final NameStoriesService nameStoriesService = NameStoriesService();
