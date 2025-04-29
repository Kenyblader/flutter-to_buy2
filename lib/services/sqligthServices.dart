import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Obtenir une instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('to_buy.db');
    return _database!;
  }

  // Initialiser la base de données
  Future<Database> _initDB(String fileName) async {
    String path = join(await getDatabasesPath(), fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Créer les tables avec relations
  Future _createDB(Database db, int version) async {
    // Table users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Table buy_lists
    await db.execute('''
      CREATE TABLE buy_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        expirationDate TEXT,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Table buy_items
    await db.execute('''
      CREATE TABLE buy_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        date TEXT NOT NULL,
        isBuy INTEGER NOT NULL DEFAULT 0,
        buyListId TEXT NOT NULL,
        FOREIGN KEY (buyListId) REFERENCES buy_lists(id) ON DELETE CASCADE
      )
    ''');

    // Index pour optimiser les requêtes
    await db.execute('CREATE INDEX idx_userId ON buy_lists(userId);');
    await db.execute('CREATE INDEX idx_buyListId ON buy_items(buyListId);');
  }

  // Fermer la base de données
  Future close() async {
    final db = await database;
    db.close();
  }

  // --- CRUD pour User ---

  Future<int> insertUser(User user) async {
    final db = await database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'insertion de l\'utilisateur : $e');
    }
  }

  Future<User?> getUserByEmail(String email, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    // Les BuyList et BuyItem associés seront supprimés grâce à ON DELETE CASCADE
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<User?> getActiveUser() async {
    final db = await database;
    final maps = await db.query('users', where: 'isActive = ?', whereArgs: [1]);
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  // --- CRUD pour BuyList ---

  Future<void> insertBuyList(BuyList buyList, String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insérer la BuyList
      await txn.insert('buy_lists', {
        'id': buyList.id ?? DateTime.now().hashCode.toString(),
        'name': buyList.name,
        'description': buyList.description,
        'date': buyList.date.toIso8601String(),
        'expirationDate': buyList.expirationDate?.toIso8601String(),
        'userId': userId,
      });

      // Insérer les BuyItems associés
      for (var item in buyList.items) {
        await txn.insert('buy_items', {
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'date': item.date.toIso8601String(),
          'isBuy': item.isBuy ? 1 : 0,
          'buyListId': buyList.id,
        });
      }
    });
  }

  Future<List<BuyList>> getBuyListsByUser(String userId) async {
    final db = await database;
    final listMaps = await db.query(
      'buy_lists',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    List<BuyList> buyLists = [];
    for (var listMap in listMaps) {
      final itemMaps = await db.query(
        'buy_items',
        where: 'buyListId = ?',
        whereArgs: [listMap['id']],
      );

      List<BuyItem> items =
          itemMaps.map((itemMap) => BuyItem.fromMap(itemMap)).toList();

      buyLists.add(BuyList.fromMap(listMap, items));
    }
    return buyLists;
  }

  Future<int> updateBuyList(BuyList buyList) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Mettre à jour la BuyList
      int count = await txn.update(
        'buy_lists',
        buyList.toMap(),
        where: 'id = ?',
        whereArgs: [buyList.id],
      );

      // Supprimer les anciens BuyItems
      await txn.delete(
        'buy_items',
        where: 'buyListId = ?',
        whereArgs: [buyList.id],
      );

      // Insérer les nouveaux BuyItems
      for (var item in buyList.items) {
        await txn.insert('buy_items', {
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'date': item.date.toIso8601String(),
          'isBuy': item.isBuy ? 1 : 0,
          'buyListId': buyList.id,
        });
      }

      return count;
    });
  }

  Future<int> deleteBuyList(String id) async {
    final db = await database;
    // Les BuyItems associés seront supprimés grâce à ON DELETE CASCADE
    return await db.delete('buy_lists', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD pour BuyItem ---

  Future<int> insertBuyItem(BuyItem item, String buyListId) async {
    final db = await database;
    return await db.insert('buy_items', {
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'date': item.date.toIso8601String(),
      'isBuy': item.isBuy ? 1 : 0,
      'buyListId': buyListId,
    });
  }

  Future<List<BuyItem>> getBuyItemsByBuyListId(String buyListId) async {
    final db = await database;
    final itemMaps = await db.query(
      'buy_items',
      where: 'buyListId = ?',
      whereArgs: [buyListId],
    );
    return itemMaps.map((itemMap) => BuyItem.fromMap(itemMap)).toList();
  }

  Future<int> updateBuyItem(BuyItem item) async {
    final db = await database;
    return await db.update(
      'buy_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteBuyItem(String id) async {
    final db = await database;
    return await db.delete('buy_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<BuyItem?> getBuyItemById(String id) async {
    final db = await database;
    final itemMaps = await db.query(
      'buy_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Item Maps $id : ${itemMaps.toString()}');
    return itemMaps.isNotEmpty ? BuyItem.fromMap(itemMaps.first) : null;
  }

  getBuyListById(String listId) async {
    final db = await database;
    final listMaps = await db.query(
      'buy_lists',
      where: 'id = ?',
      whereArgs: [listId],
    );
    if (listMaps.isNotEmpty) {
      final items = await getBuyItemsByBuyListId(listId);
      return BuyList.fromMap(listMaps.first, items);
    }
    return null;
  }

  // // --- Méthode pour synchronisation avec backend (optionnel) ---
  // Future<void> syncBuyListWithBackend(BuyList buyList, String backendUrl) async {
  //   // Exemple d'envoi au backend via HTTP
  //   final response = await http.post(
  //     Uri.parse('$backendUrl/buy_lists'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode(buyList.toJson()),
  //   );
  //   if (response.statusCode != 201) {
  //     throw Exception('Échec de la synchronisation : ${response.statusCode}');
  //   }
  // }
}
