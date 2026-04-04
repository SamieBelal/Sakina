import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/card_collection_service.dart';

class CardCollectionNotifier extends StateNotifier<CardCollectionState> {
  CardCollectionNotifier() : super(const CardCollectionState()) {
    _load();
  }

  Future<void> _load() async {
    state = await getCardCollection();
  }

  /// Engage a card by Name transliteration. Returns the engage result.
  Future<CardEngageResult?> engageByName(String nameTransliteration) async {
    final card = findCollectibleByName(nameTransliteration);
    if (card == null) return null;

    final result = await engageCard(card.id);
    state = await getCardCollection();
    return result;
  }

  /// Engage a card by ID directly.
  Future<CardEngageResult> engageById(int id) async {
    final result = await engageCard(id);
    state = await getCardCollection();
    return result;
  }

  Future<void> reload() async {
    state = await getCardCollection();
  }
}

final cardCollectionProvider =
    StateNotifierProvider<CardCollectionNotifier, CardCollectionState>(
  (ref) => CardCollectionNotifier(),
);
