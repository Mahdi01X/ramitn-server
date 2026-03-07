import 'card.dart';

enum MeldType { set, run }

class Meld {
  final String id;
  final MeldType type;
  final List<Card> cards;
  final String? ownerId; // Player who placed this meld

  const Meld({required this.id, required this.type, required this.cards, this.ownerId});

  factory Meld.fromJson(Map<String, dynamic> json) {
    return Meld(
      id: json['id'] as String,
      type: json['type'] == 'set' ? MeldType.set : MeldType.run,
      cards: (json['cards'] as List).map((c) => Card.fromJson(c)).toList(),
      ownerId: json['ownerId'] as String?,
    );
  }
}

