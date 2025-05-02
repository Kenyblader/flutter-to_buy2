import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/models/user.dart';

const ipadressserver = "10.244.39.193";

class BackendServices {
  final String baseUrl =
      'https://$ipadressserver:3000'; // Replace with your actual base URL

  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        body: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return User.fromMap(responseData['user']);
      } else {
        return Future.error("invalid credental");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        body: user.toMap(),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return User.fromMap(responseData['user']);
      } else {
        return Future.error("already exist");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$id'));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return User.fromMap(responseData['user']);
      } else {
        return Future.error("user not found");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BuyList>> getAllBuyList() async {
    try {
      final responce = await http.get(Uri.parse('$baseUrl/lists'));
      if (responce.statusCode == 200) {
        final responseData = jsonDecode(responce.body);
        return responseData.map((res) => BuyList.fromMap(res, []));
      } else {
        return Future.error("failed to fetch buy lists");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<List<BuyItem>> getAllItems() async {
    try {
      final responce = await http.get(Uri.parse('$baseUrl/items'));
      if (responce.statusCode == 200) {
        final responseData = jsonDecode(responce.body);
        return responseData.map((res) => BuyItem.fromMap(res));
      } else {
        return Future.error("failed to fetch buy items");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<BuyList> getBuyListByUser(String userId) async {
    try {
      final responce = await http.get(Uri.parse('$baseUrl/lists/$userId'));
      if (responce.statusCode == 200) {
        final responseData = jsonDecode(responce.body);
        return BuyList.fromMap(responseData, []);
      } else {
        return Future.error("failed to fetch buy lists");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<List<BuyItem>> getItemsByUser(String userId) async {
    try {
      final responce = await http.get(Uri.parse('$baseUrl/items/$userId'));
      if (responce.statusCode == 200) {
        final responseData = jsonDecode(responce.body);
        return responseData.map((res) => BuyItem.fromMap(res));
      } else {
        return Future.error("failed to fetch buy items");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<List<BuyItem>> getItemsByList(String listId) async {
    try {
      final responce = await http.get(Uri.parse('$baseUrl/items/$listId'));
      if (responce.statusCode == 200) {
        final responseData = jsonDecode(responce.body);
        return responseData.map((res) => BuyItem.fromMap(res));
      } else {
        return Future.error("failed to fetch buy items");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<void> addBuyList(BuyList buyList, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lists'),
        body: {...buyList.toMap(), "userId": userId},
      );
      if (response.statusCode != 200) {
        return Future.error("failed to add buy list");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<void> addBuyItem(BuyItem item, String listId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/items'),
        body: {...item.toMap(), "listId": listId},
      );
      if (response.statusCode != 200) {
        return Future.error("failed to add buy list");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<void> deleteBuyList(String listId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/lists/$listId'));
      if (response.statusCode != 200) {
        return Future.error("failed to delete buy list");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<void> deleteBuyItem(String itemId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/items/$itemId'));
      if (response.statusCode != 200) {
        return Future.error("failed to delete buy list");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<void> updateBuyList(BuyList buyList) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/lists/${buyList.id}'),
        body: buyList.toMap(),
      );
      if (response.statusCode != 200) {
        return Future.error("failed to update buy list");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<void> updateBuyItem(BuyItem item) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/lists/${item.id}'),
        body: item.toMap(),
      );
      if (response.statusCode != 200) {
        return Future.error("failed to update buy list");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }
}
