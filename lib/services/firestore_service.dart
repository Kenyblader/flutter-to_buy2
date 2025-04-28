import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'ID de l'utilisateur actuel
  String? get userId {
    final uid = _auth.currentUser?.uid;
    print('FirestoreService - User ID: $uid');
    return uid;
  }

  // Ajouter une liste de courses avec ses articles
  Future<void> addBuyList(BuyList buyList, List<BuyItem> items) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    print('Ajout d\'une nouvelle liste: ${buyList.name}');
    final listRef =
        _firestore.collection('users').doc(userId).collection('lists').doc();

    final listData = buyList.toJson()..['createdAt'] = Timestamp.now();
    await listRef.set(listData);

    final batch = _firestore.batch();
    for (var item in items) {
      final itemRef = listRef.collection('items').doc();
      batch.set(itemRef, {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'date': Timestamp.fromDate(item.date),
        'isBuy': item.isBuy,
      }, SetOptions(merge: false)); // Forcer l'écriture
    }
    await batch.commit();
    print('Liste ajoutée avec succès: ${listRef.id}');
  }

  // Récupérer toutes les listes de courses
  Stream<List<BuyList>> getBuyLists() {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté, retour d\'un stream vide');
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .snapshots()
        .map((snapshot) {
          print(
            'Récupération des listes pour userId: $userId, ${snapshot.docs.length} listes trouvées',
          );
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return BuyList(
              id: doc.id, // Safely parse doc.id to an integer
              name: data['name'] as String,
              description: data['description'] as String,
              expirationDate:
                  data['expirationDate'] != null
                      ? (data['expirationDate'] as Timestamp).toDate()
                      : null,
              items:
                  doc.data()['items'] != null
                      ? (data['items'] as List)
                          .map(
                            (item) => BuyItem(
                              id: null,
                              firestoreId: item['id'] as String?,
                              name: item['name'] as String,
                              price: (item['price'] as num).toDouble(),
                              quantity: (item['quantity'] as num).toDouble(),
                              date: DateTime.parse(item['date'] as String),
                              isBuy: item['isBuy'] as bool? ?? false,
                            ),
                          )
                          .toList()
                      : [],
            );
          }).toList();
        });
  }

  // Récupérer les articles d'une liste spécifique
  Stream<List<BuyItem>> getItemsForList(String listId) {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté, retour d\'un stream vide');
      return Stream.value([]);
    }

    print('Récupération des articles pour listId: $listId');
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .snapshots()
        .map((snapshot) {
          print(
            'Nombre d\'articles trouvés pour listId $listId: ${snapshot.docs.length}',
          );
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return BuyItem(
              id: null,
              firestoreId: doc.id,
              name: data['name'] as String,
              price: (data['price'] as num).toDouble(),
              quantity: (data['quantity'] as num).toDouble(),
              date: (data['date'] as Timestamp).toDate(),
              isBuy: data['isBuy'] as bool? ?? false,
            );
          }).toList();
        });
  }

  // Ajouter un article à une liste existante
  Future<void> addItemToList(String listId, BuyItem item) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    final itemRef =
        _firestore
            .collection('users')
            .doc(userId)
            .collection('lists')
            .doc(listId)
            .collection('items')
            .doc();

    try {
      print(
        'Ajout de l\'article "${item.name}" à la liste $listId, chemin: ${itemRef.path}',
      );
      await itemRef.set({
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'date': Timestamp.fromDate(item.date),
        'isBuy': item.isBuy,
      }, SetOptions(merge: false)); // Forcer l'écriture
      print('Article ajouté avec succès, ID: ${itemRef.id}');
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'article "${item.name}": $e');
      throw Exception('Erreur lors de l\'ajout de l\'article: $e');
    }
  }

  // Modifier un article dans une liste
  Future<void> updateItem(String listId, String itemId, BuyItem item) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    final itemRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(itemId);

    try {
      print(
        'Mise à jour de l\'article $itemId dans la liste $listId, chemin: ${itemRef.path}',
      );
      await itemRef.update({
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'date': Timestamp.fromDate(item.date),
        'isBuy': item.isBuy,
      });
      print('Article mis à jour avec succès: $itemId');
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'article $itemId: $e');
      throw Exception('Erreur lors de la mise à jour de l\'article: $e');
    }
  }

  Future<void> toggleItemStatus(
    String listId,
    String itemId,
    bool isBuy,
  ) async {
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final itemRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(itemId);

    await itemRef.update({'isBuy': isBuy});
  }

  // Supprimer un article d'une liste
  Future<void> deleteItem(String listId, String itemId) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    final itemRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(itemId);

    try {
      print(
        'Suppression de l\'article $itemId dans la liste $listId, chemin: ${itemRef.path}',
      );
      await itemRef.delete();
      print('Article supprimé avec succès: $itemId');
    } catch (e) {
      print('Erreur lors de la suppression de l\'article $itemId: $e');
      throw Exception('Erreur lors de la suppression de l\'article: $e');
    }
  }

  // Supprimer une liste et la déplacer vers deleted_lists
  Future<void> deleteBuyList(String listId) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    print('Suppression de la liste $listId');
    final listDoc =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('lists')
            .doc(listId)
            .get();

    if (!listDoc.exists) {
      print('Erreur: Liste $listId introuvable');
      throw Exception('Liste introuvable');
    }

    final itemsSnapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('lists')
            .doc(listId)
            .collection('items')
            .get();

    final deletedListRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('deleted_lists')
        .doc(listId);

    final batch = _firestore.batch();
    batch.set(deletedListRef, {
      ...listDoc.data()!,
      'deletedAt': Timestamp.now(),
    });

    for (var itemDoc in itemsSnapshot.docs) {
      final itemRef = deletedListRef.collection('items').doc(itemDoc.id);
      batch.set(itemRef, itemDoc.data());
    }

    for (var itemDoc in itemsSnapshot.docs) {
      batch.delete(itemDoc.reference);
    }
    batch.delete(listDoc.reference);

    await batch.commit();
    print('Liste $listId supprimée et déplacée vers deleted_lists');
  }

  // Récupérer les listes supprimées
  Stream<List<BuyList>> getDeletedBuyLists() {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté, retour d\'un stream vide');
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('deleted_lists')
        .snapshots()
        .map((snapshot) {
          print(
            'Récupération des listes supprimées pour userId: $userId, ${snapshot.docs.length} listes trouvées',
          );
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return BuyList(
              id: doc.id,
              name: data['name'] as String,
              description: data['description'] as String,
              expirationDate:
                  data['expirationDate'] != null
                      ? (data['expirationDate'] as Timestamp).toDate()
                      : null,
              items: const [],
            );
          }).toList();
        });
  }

  // Restaurer une liste supprimée
  Future<void> restoreBuyList(String listId, String listName) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    print('Restauration de la liste $listId');
    final deletedListDoc =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('deleted_lists')
            .doc(listId)
            .get();

    if (!deletedListDoc.exists) {
      print('Erreur: Liste supprimée $listId introuvable');
      throw Exception('Liste supprimée introuvable');
    }
    if (deletedListDoc.data()!['name'] != listName) {
      print(
        'Erreur: Nom de la liste incorrect, attendu: $listName, trouvé: ${deletedListDoc.data()!['name']}',
      );
      throw Exception('Nom de la liste incorrect');
    }

    final itemsSnapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('deleted_lists')
            .doc(listId)
            .collection('items')
            .get();

    final listRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId);

    final batch = _firestore.batch();
    batch.set(listRef, {
      ...deletedListDoc.data()!,
      'createdAt': Timestamp.now(),
    });

    for (var itemDoc in itemsSnapshot.docs) {
      final itemRef = listRef.collection('items').doc(itemDoc.id);
      batch.set(itemRef, itemDoc.data());
    }

    for (var itemDoc in itemsSnapshot.docs) {
      batch.delete(itemDoc.reference);
    }
    batch.delete(deletedListDoc.reference);

    await batch.commit();
    print('Liste $listId restaurée avec succès');
  }
}
