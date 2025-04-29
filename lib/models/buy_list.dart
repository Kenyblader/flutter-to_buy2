import 'package:to_buy/models/buy_item.dart';

class BuyList {
  String? id;
  String name;
  String description;
  DateTime date;
  DateTime? expirationDate;
  List<BuyItem> items;

  BuyList.empty()
    : id = null,
      name = '',
      description = '',
      date = DateTime.now(),
      expirationDate = null,
      items = [];

  BuyList({
    this.id,
    required this.name,
    required this.description,
    DateTime? date,
    this.expirationDate,
    this.items = const [],
  }) : date = date ?? DateTime.now() {
    id ??= DateTime.now().hashCode.toString();
  }

  double get total => items.fold(0.0, (sum, item) => sum + item.getTotal());

  bool get isComplete {
    for (var item in items) {
      if (!item.isBuy) return false;
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toUtc().toString(),
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }

  factory BuyList.fromMap(Map<String, dynamic> map, List<BuyItem> items) {
    return BuyList(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      expirationDate:
          map['expirationDate'] != null
              ? DateTime.parse(map['expirationDate'])
              : null,
      items: items,
    );
  }

  // Méthodes toJson/fromJson (déjà fournies)
  factory BuyList.fromJson(Map<String, dynamic> json) {
    return BuyList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      date: DateTime.now(),
      expirationDate:
          json['expirationDate'] != null
              ? DateTime.parse(json['expirationDate'] as String)
              : null,
      items:
          json['items'] != null
              ? (json['items'] as List)
                  .map(
                    (item) => BuyItem(
                      name: item['name'] as String,
                      price: (item['price'] as num).toDouble(),
                      quantity: (item['quantity'] as num).toDouble(),
                      date: DateTime.parse(item['date'] as String),
                      isBuy: item['isBuy'] as bool,
                    ),
                  )
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'items':
          items
              .map(
                (item) => {
                  'name': item.name,
                  'price': item.price,
                  'quantity': item.quantity,
                  'date': item.date.toIso8601String(),
                  'isBuy': item.isBuy,
                },
              )
              .toList(),
    };
  }
}
