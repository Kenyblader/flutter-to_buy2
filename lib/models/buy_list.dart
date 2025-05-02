import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/syncable.dart';
import 'package:uuid/uuid.dart';

class BuyList implements Syncable {
  @override
  String id;
  String name;
  String description;
  DateTime date;
  DateTime? expirationDate;
  List<BuyItem> items;
  @override
  DateTime lastModified;
  @override
  bool isDeleted;
  @override
  String syncStatus;

  BuyList({
    String? id,
    required this.name,
    required this.description,
    DateTime? date,
    this.expirationDate,
    this.items = const [],
    DateTime? lastModified,
    this.isDeleted = false,
    this.syncStatus = 'pending',
  }) : date = date ?? DateTime.now(),
       id = id ?? Uuid().v4(),
       lastModified = lastModified ?? DateTime.now();

  double get total => items.fold(0.0, (sum, item) => sum + item.getTotal());

  bool get isComplete {
    for (var item in items) {
      if (!item.isBuy) return false;
    }
    return true;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toUtc().toString(),
      'expirationDate': expirationDate?.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus,
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
      lastModified: DateTime.parse(map['last_modified']),
      isDeleted: map['is_deleted'] == 1,
      syncStatus: map['sync_status'],
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
      lastModified: DateTime.parse(json['last_modified']),
      isDeleted: json['is_deleted'] == 1,
      syncStatus: json['sync_status'],
      items:
          json['items'] != null
              ? (json['items'] as List)
                  .map((item) => BuyItem.fromMap(item))
                  .toList()
              : [],
    );
  }

  @override
  bool hasConflictWith(Syncable other) {
    if (other is! BuyList) return false;
    return name != other.name || description != other.description;
  }
}
