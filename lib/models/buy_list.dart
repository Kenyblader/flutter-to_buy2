import 'package:to_buy/models/buy_item.dart';

class BuyList {
  String? id = DateTime.now().hashCode.toString();
  String name;
  String description;
  DateTime date = DateTime.now();
  DateTime? expirationDate;
  List<BuyItem> items;

  BuyList({
    this.id,
    required this.name,
    required this.description,
    this.expirationDate,
    this.items = const [],
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.getTotal());
  factory BuyList.fromJson(Map<String, dynamic> json) {
    return BuyList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
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

  bool get isComplete {
    print("isComplete: ${items.length}");
    items.forEach((item) {
      print(item.isBuy);
    });
    for (var item in items) {
      if (!item.isBuy) return false;
    }
    return true;
  }
}
