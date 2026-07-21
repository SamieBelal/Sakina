import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/economy_events.dart';

class CardCollectionNotifier extends StateNotifier<CardCollectionState> {
  CardCollectionNotifier() : super(const CardCollectionState()) {
    _load();
    // Reload when the cache is mutated out-of-band (e.g. the premium Emerald
    // retro-bump at boot), so watchers like the Collection nav-tab badge
    // reflect the change immediately instead of a stale count.
    _sub = EconomyEvents.stream.listen((e) {
      if (e is CardCollectionChanged) reload();
    });
  }

  StreamSubscription<EconomyEvent>? _sub;

  Future<void> _load() async {
    state = await getCardCollection();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Engage a card by Name transliteration. Returns the engage result.
  Future<CardEngageResult?> engageByName(String nameTransliteration) async {
    final card = findCollectibleByName(nameTransliteration);
    if (card == null) return null;

    final result = await engageCard(card.id, maxTier: await premiumTierCeiling());
    state = await getCardCollection();
    return result;
  }

  /// Engage a card by ID directly.
  Future<CardEngageResult> engageById(int id) async {
    final result = await engageCard(id, maxTier: await premiumTierCeiling());
    state = await getCardCollection();
    return result;
  }

  Future<void> markSeen(int cardId, {int? tierNumber}) async {
    await markCardSeen(cardId, tierNumber: tierNumber);
    state = await getCardCollection();
  }

  Future<void> reload() async {
    state = await getCardCollection();
  }
}

final cardCollectionProvider =
    StateNotifierProvider<CardCollectionNotifier, CardCollectionState>(
  (ref) => CardCollectionNotifier(),
);
