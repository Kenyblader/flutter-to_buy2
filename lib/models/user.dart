import 'package:to_buy/models/syncable.dart';
import 'package:uuid/uuid.dart';

class User implements Syncable {
  @override
  String id;
  final String email;
  final String password;
  bool isActive;
  @override
  bool isDeleted;
  @override
  DateTime lastModified;
  @override
  String syncStatus;

  User({
    String? id,
    required this.email,
    required this.password,
    this.isActive = false,
    DateTime? lastModified,
    this.isDeleted = false,
    this.syncStatus = 'pending',
  }) : this.id = id ?? Uuid().v4(),
       this.lastModified = lastModified ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'isActive': isActive ? 1 : 0,
      'last_modified': lastModified.toUtc().toString(),
      'is_deleted': isDeleted ? 1 : 0,
      'sync_status': syncStatus,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'] as String,
      password: map['password'] as String,
      isActive: map['isActive'] == 1,
      lastModified:
          map['last_modified'] != null
              ? DateTime.parse(map['last_modified'])
              : DateTime.now(),
      isDeleted: map['is_deleted'] == 1,
      syncStatus: map['sync_status'] ?? 'synced',
    );
  }

  @override
  bool hasConflictWith(Syncable other) {
    if (other is! User) return false;

    // Comparer les champs importants pour déterminer s'il y a un conflit
    return email != other.email ||
        isDeleted != other.isDeleted ||
        password != other.password;
  }
}
