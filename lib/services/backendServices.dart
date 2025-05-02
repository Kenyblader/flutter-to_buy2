import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/models/user.dart';

const ipadressserver = "10.244.39.193";

class BackendServices {
  final String baseUrl =
      'http://$ipadressserver:3000'; // Replace with your actual base URL

  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return User.fromMap(responseData['user']);
      } else {
        return Future.error("invalid credential");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toMap()),
      );
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return User.fromMap(responseData);
      } else {
        return Future.error("already exists");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );
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
      final responce = await http.get(
        Uri.parse('$baseUrl/lists'),
        headers: {'Content-Type': 'application/json'},
      );
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
      final responce = await http.get(
        Uri.parse('$baseUrl/items'),
        headers: {'Content-Type': 'application/json'},
      );
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
      final responce = await http.get(
        Uri.parse('$baseUrl/lists/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
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
      final responce = await http.get(
        Uri.parse('$baseUrl/items/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
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
      final responce = await http.get(
        Uri.parse('$baseUrl/items/$listId'),
        headers: {'Content-Type': 'application/json'},
      );
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({...buyList.toMap(), "userId": userId}),
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({...item.toMap(), "listId": listId}),
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
      final response = await http.delete(
        Uri.parse('$baseUrl/lists/$listId'),
        headers: {'Content-Type': 'application/json'},
      );
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
      final response = await http.delete(
        Uri.parse('$baseUrl/items/$itemId'),
        headers: {'Content-Type': 'application/json'},
      );
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(buyList.toMap()),
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(item.toMap()),
      );
      if (response.statusCode != 200) {
        return Future.error("failed to update buy list");
      }
    } catch (e) {
      print("erruer: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getChanges(
    String entity,
    DateTime since,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$entity/changes?since=${since.toIso8601String()}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to get changes: ${response.statusCode}');
    }
  }

  Future<void> pushChanges(
    String entity,
    List<Map<String, dynamic>> changes,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/sync/$entity/batch'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'changes': changes}),
    );
    print("les changes: ${json.encode(changes)}");
    if (response.statusCode != 200) {
      throw Exception('Failed to push changes: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchData(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/sync/$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> postData(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/sync/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> putData(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update data: ${response.statusCode}');
    }
  }

  Future<void> deleteData(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete data: ${response.statusCode}');
    }
  }
}
