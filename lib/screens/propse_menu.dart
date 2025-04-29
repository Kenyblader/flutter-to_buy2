import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:to_buy/services/geminService.dart';

class ProposeMenu extends StatefulWidget {
  @override
  _ProposeMenuState createState() => _ProposeMenuState();
}

class _ProposeMenuState extends State<ProposeMenu> {
  final TextEditingController _budgetController = TextEditingController();
  final gemin = Geminservice();

  final List<ElementAffich> _items = [];
  final List<BuyItem> _saveditems = [];
  String menuName = "";

  DishModel? parseCustomJsonString(String jsonString) {
    // Corriger les clés non-encadrées avec des guillemets
    try {
      var cleanedJson = jsonString.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7, cleanedJson.length - 3).trim();
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3, cleanedJson.length - 3).trim();
      }

      print('Réponse JSON brute : $cleanedJson');

      // Parser le JSON
      final jsonData = jsonDecode(cleanedJson) as Map<String, dynamic>;
      final dish = DishModel.fromJson(jsonData);

      // Mettre à jour le widget Android avec les ingrédients
      return dish;
    } catch (error, stackTrace) {
      print('Erreur Gemini : $error');
      print('Trace de la pile : $stackTrace');
      return null;
    }
  }

  Future<void> _validateBudget() async {
    final budget = _budgetController.text;
    if (budget.isNotEmpty) {
      await gemin.GetMEnuByBudget(budget)
          .then((result) {
            print('IA Response: ${result}');
            final parsedResult = parseCustomJsonString(result);
            final menu = parsedResult?.name;
            if (menu != null) {
              final ingredients = parsedResult?.ingredients ?? [];

              setState(() {
                menuName = menu;
                _items.clear();
                _items.addAll(ingredients);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un budget valide')),
      );
    }
  }

  void _onDismissed(int index, DismissDirection direction) {
    setState(() {
      if (direction == DismissDirection.startToEnd) {
        _items[index].isSelected = true;
      } else if (direction == DismissDirection.endToStart) {
        _items[index].isSelected = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Propose Menu'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Entrez votre budget :',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Budget',
                hintText: 'Entrez votre budget ici',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _validateBudget,
              child: Text('Valider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                menuName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Dismissible(
                    key: Key(item.name),
                    // onDismissed: (direction) => _onDismissed(item, direction),
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      _onDismissed(index, direction);
                      return false;
                    },
                    child: Card(
                      elevation: 4,
                      color: item.isSelected ? Colors.green[50] : Colors.white,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.desctiption),
                            Text(
                              '${formatDouble(item.price)} XAF x ${formatDouble(item.quantity)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        leading: Icon(Icons.shopping_cart),
                        trailing: Text(
                          '${formatDouble(item.quantity * item.price)} XAF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final service = FirestoreService();
          for (var item in _items) {
            if (item.isSelected) {
              _saveditems.add(
                BuyItem(
                  name: item.name,
                  price: item.price,
                  quantity: item.quantity,
                ),
              );
            }
          }
          if (_saveditems.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Aucun article sélectionné')),
            );
            return;
          }
          if (menuName.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Veuillez valider le budget d\'abord')),
            );
            return;
          }
          var list = BuyList(
            name: "generated list ${DateTime.now().millisecond}",
            description: "preparation de $menuName",
            items: _saveditems,
          );
          service
              .addBuyList(list, _saveditems)
              .then((value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Liste créée avec succès')),
                );
                Navigator.pop(context);
              })
              .catchError((error) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur : $error')));
              });
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Text('save', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
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
      desctiption: json['description'],
      price: json['price'].toDouble(),
      quantity: json['quantity'].toDouble(),
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
    return value.toInt().toString(); // Pas de décimales
  } else {
    return value.toStringAsFixed(2); // Afficher 2 décimales
  }
}
