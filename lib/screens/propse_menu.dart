import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:to_buy/screens/item_list_screen.dart';
import 'package:to_buy/services/geminService.dart';

class ProposeMenu extends StatefulWidget {
  const ProposeMenu({super.key});

  @override
  _ProposeMenuState createState() => _ProposeMenuState();
}

class _ProposeMenuState extends State<ProposeMenu> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _nbPersonController = TextEditingController();
  final gemin = Geminservice();
  bool _isLoading = false;

  final List<DishModel> _items = [];

  List<DishModel>? parseCustomJsonString(String jsonString) {
    try {
      var cleanedJson = jsonString.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7, cleanedJson.length - 3).trim();
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3, cleanedJson.length - 3).trim();
      }

      print('Réponse JSON brute : $cleanedJson');

      final jsonData = jsonDecode(cleanedJson) as List<dynamic>;
      final dish = jsonData.map((data) => DishModel.fromJson(data)).toList();
      return dish;
    } catch (error, stackTrace) {
      print('Erreur Gemini : $error');
      print('Trace de la pile : $stackTrace');
      return null;
    }
  }

  Future<void> _validateBudget() async {
    setState(() {
      _isLoading = true;
    });

    final budget = _budgetController.text;
    if (budget.isNotEmpty) {
      await gemin.GetMEnuByBudget(budget)
          .then((result) {
            print('IA Response: $result');
            final parsedResult = parseCustomJsonString(result);

            if (parsedResult != null) {
              setState(() {
                _items.clear();
                _items.addAll(parsedResult);
              });
            }
          })
          .onError((error, stackTrace) {
            print('Erreur : $error');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur : $error')));
          });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un budget valide'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propose Menu'),
        backgroundColor: Colors.blueAccent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Entrez votre budget :',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Budget',
                hintText: 'Entrez votre budget ici',
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.money, color: Colors.blueAccent),
              ),
            ),
            Center(
              child: Text(
                'A combien desirez vous manger :',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nbPersonController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Nombre de personnes',
                hintText: 'entrer le nombre de personne ici',
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(
                  Icons.person_4,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _validateBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Valider', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 16),
            if (_items.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'Ingrédients (glissez à droite pour sélectionner, à gauche pour désélectionner):',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            Expanded(
              child:
                  _items.isEmpty
                      ? Center(
                        child: Text(
                          _items.isEmpty
                              ? 'Entrez un budget pour recevoir une suggestion de menu'
                              : 'Aucun ingrédient disponible',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          var item = _items[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Card(
                              elevation: 3,
                              color: Colors.grey[100],
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.ingredients.length} ingredients',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      '${formatDouble(item.total)} XAF }',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                leading: const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.blueAccent,
                                ),
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (builder) =>
                                                ItemListScreen(list: item),
                                      ),
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }
}

class ElementAffich {
  String name;
  String desctiption;
  double price;
  double quantity;
  bool isSelected = true;

  ElementAffich({
    required this.desctiption,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory ElementAffich.fromJson(Map<String, dynamic> json) {
    return ElementAffich(
      name: json['name'],
      desctiption: json['description'] ?? '',
      price: json['price'].toDouble(),
      quantity:
          json['quantity'] is int
              ? json['quantity'].toDouble()
              : json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': desctiption,
      'price': price,
      'quantity': quantity,
    };
  }
}

class DishModel {
  final String name;
  final List<ElementAffich> ingredients;

  DishModel({required this.name, required this.ingredients});

  double get total =>
      ingredients.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  factory DishModel.fromJson(Map<String, dynamic> json) {
    return DishModel(
      name: json['name'],
      ingredients:
          (json['ingredients'] as List<dynamic>)
              .map((ingredient) => ElementAffich.fromJson(ingredient))
              .toList(),
    );
  }
}

String formatDouble(double value) {
  if (value == value.toInt()) {
    return value.toInt().toString();
  } else {
    return value.toStringAsFixed(2);
  }
}
