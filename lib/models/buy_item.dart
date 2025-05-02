import 'package:to_buy/models/syncable.dart';
import 'package:uuid/uuid.dart';

class BuyItem implements Syncable {
  @override
  String id;
  final String name;
  final double price;
  final double quantity;
  final DateTime date;
  bool isBuy;
  @override
  DateTime lastModified;
  @override
  bool isDeleted;
  @override
  String syncStatus;

  BuyItem({
    String? id,
    required this.name,
    required this.price,
    required this.quantity,
    DateTime? date,
    this.isBuy = false,
    DateTime? lastModified,
    this.isDeleted = false,
    this.syncStatus = 'pending',
  }) : date = date ?? DateTime.now(),
       id = id ?? Uuid().v4(),
       lastModified = lastModified ?? DateTime.now();

  double getTotal() => price * quantity;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'date': date.toUtc().toString(),
      'isBuy': isBuy ? 1 : 0,
      'last_modified': lastModified.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus,
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
      lastModified: DateTime.parse(map['last_modified']),
      isDeleted: map['is_deleted'] == 1,
      syncStatus: map['sync_status'],
    );
  }
  @override
  bool hasConflictWith(Syncable other) {
    if (other is! BuyItem) return false;

    // Comparer les champs importants pour déterminer s'il y a un conflit
    return name != other.name ||
        price != other.price ||
        quantity != other.quantity ||
        isBuy != other.isBuy;
  }
}
