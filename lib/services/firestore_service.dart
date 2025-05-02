import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/models/user.dart';
import 'package:to_buy/provider/auth_provider.dart';
import 'package:to_buy/services/backendServices.dart';
import 'package:to_buy/services/sqligthServices.dart';
import 'package:to_buy/services/sync_service.dart';
import 'package:to_buy/widgets/listify_widget.dart';

class FirestoreService {
  final sqlService = DatabaseHelper.instance;
  final backendService = BackendServices();
  SyncService syncService = SyncService(
    sqliteService: DatabaseHelper(),
    nestService: BackendServices(),
  );

  String? userId;

  FirestoreService() {
    userId = AuthService.userId;
    syncService.startPeriodicSync();
  }

  // Ajouter une liste de courses avec ses articles
  Future<void> addBuyList(BuyList buyList, List<BuyItem> items) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    print('Ajout d\'une nouvelle liste: ${buyList.name}');
    buyList.items = items;

    try {
      await sqlService.insertBuyList(buyList, userId as String);
      syncService.syncAll(); // Synchroniser après l'ajout
    } catch (e) {
      print('Erreur lors de l\'ajout de la liste: $e');
      throw Exception('Erreur lors de l\'ajout de la liste: $e');
    }
    // syncService.syncAll();

    ListifyWidgetManager.updateHeadline();
  }

  Future<BuyList?> getBuyListById(String listId) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté, retour d\'une liste vide');
      return null;
    }

    var buyList = await sqlService.getBuyListById(listId);
    return buyList;
  }

  // Récupérer toutes les listes de courses
  Stream<List<BuyList>> getBuyLists() {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté, retour d\'un stream vide');
      return Stream.value([]);
    }
    userId = AuthService.userId;
    print('Récupération des listes de courses pour userId: [$userId]');
    var lists = sqlService.getBuyListsByUser(userId as String);
    return lists.asStream();
  }

  // Récupérer les articles d'une liste spécifique
  Future<Stream<List<BuyItem>>> getItemsForList(String listId) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté, retour d\'un stream vide');
      return Stream.value([]);
    }

    var data = sqlService.getBuyItemsByBuyListId(listId).asStream();
    return data;
  }

  // Ajouter un article à une liste existante
  Future<void> addItemToList(String listId, BuyItem item) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    try {
      var x = await sqlService.insertBuyItem(item, listId); // Forcer l'écriture
      print(
        'Article ajouté avec succès, ID: $x',
      ); // Afficher l'ID de l'article ajouté
      syncService.syncAll(); // Synchroniser après l'ajout
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

    try {
      await sqlService.updateBuyItem(item);
      print('Article mis à jour avec succès: $itemId');
      syncService.syncAll();
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'article $itemId: $e');
      throw Exception('Erreur lors de la mise à jour de l\'article: $e');
    }
  }

  Future<void> toggleItemStatus(String listId, BuyItem item, bool isBuy) async {
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }
    // var item = await sqlService.getBuyItemById(itemId);
    // if (item == null) {
    //   throw Exception('Article introuvable');
    // }
    item.isBuy = isBuy;
    await sqlService.updateBuyItem(item);
    print(
      'Statut de l\'article ${item.id} dans la liste $listId mis à jour: $isBuy',
    );
    //syncService.syncAll();
  }

  // Supprimer un article d'une liste
  Future<void> deleteItem(String listId, String itemId) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    try {
      print('Suppression de l\'article $itemId de la liste $listId');
      await sqlService.deleteBuyItem(itemId);
      print('Article supprimé avec succès: $itemId');
      // syncService.syncAll();
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

    await sqlService.deleteBuyList(listId);

    print('Liste $listId supprimée et déplacée vers deleted_lists');
    //syncService.syncAll();
  }

  // Récupérer les listes supprimées
  Stream<List<BuyList>> getDeletedBuyLists() {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté, retour d\'un stream vide');
      return Stream.value([]);
    }

    return Stream.value([]);
  }

  // Restaurer une liste supprimée
  Future<void> restoreBuyList(String listId, String listName) async {
    if (userId == null) {
      print('Erreur: Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    print('Restauration de la liste $listId');

    print('Liste $listId restaurée avec succès');
  }

  getUserByEmail(String email, String password) async {
    try {
      final user = await backendService.login(email, password);
      user.isActive = true;
      var isHere = await sqlService.getUserByEmail(email, password);
      if (isHere == null)
        sqlService.insertUser(user);
      else
        sqlService.updateUser(user);

      print("le user est localement enregistrer: $isHere");

      return user;
    } catch (e) {
      throw Exception("erreur de connection serveur: ${e.toString()}");
    }
  }

  insertUser(User user) async {
    try {
      await backendService.register(user);
      await sqlService.insertUser(user);
    } catch (e, st) {
      print("erreur d'inscription: ${e} - stack: $st");
      throw Exception("erreur de connection serveur");
    }
  }

  Future<bool> isUserActive() async {
    return await sqlService
        .getActiveUser()
        .then((user) {
          AuthService.userId = user.id;
          return Future.value(true);
        })
        .onError((handleError, stackTrace) {
          Future.error(handleError.toString());
          return false;
        });
  }
}
