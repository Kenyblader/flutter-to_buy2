class BuyItem {
  String? id;
  final String name;
  final double price;
  final double quantity;
  final DateTime date;
  bool isBuy;

  BuyItem({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    DateTime? date,
    this.isBuy = false,
  }) : date = date ?? DateTime.now() {
    id ??= DateTime.now().hashCode.toString();
  }

  double getTotal() => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'date': date.toUtc().toString(),
      'isBuy': isBuy ? 1 : 0,
    };
  }

  factory BuyItem.fromMap(Map<String, dynamic> map) {
    return BuyItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
      date: DateTime.parse(map['date']),
      isBuy: map['isBuy'] == 1,
    );
  }
}
