abstract class Syncable {
  late String id;
  late DateTime lastModified;
  late bool isDeleted;
  late String syncStatus; // 'synced', 'pending', 'conflict'

  Map<String, dynamic> toMap();

  // Méthode pour comparer deux versions d'un même objet et identifier les différences
  bool hasConflictWith(Syncable other);
}
