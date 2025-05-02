import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:to_buy/services/geminService.dart';

class ProposeMenu extends StatefulWidget {
  const ProposeMenu({super.key});

  @override
  _ProposeMenuState createState() => _ProposeMenuState();
}

class _ProposeMenuState extends State<ProposeMenu> {
  final TextEditingController _budgetController = TextEditingController();
  final gemin = Geminservice();

  final List<ElementAffich> _items = [];
  final List<BuyItem> _saveditems = [];
  String menuName = "";
  bool _isLoading = false;

  DishModel? parseCustomJsonString(String jsonString) {
    try {
      var cleanedJson = jsonString.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7, cleanedJson.length - 3).trim();
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3, cleanedJson.length - 3).trim();
      }

      print('Réponse JSON brute : $cleanedJson');

      final jsonData = jsonDecode(cleanedJson) as Map<String, dynamic>;
      final dish = DishModel.fromJson(jsonData);
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
      try {
        final result = await gemin.GetMEnuByBudget(budget);
        print('IA Response: $result');

        final parsedResult = parseCustomJsonString(result);
        if (parsedResult == null) {
          throw Exception("Impossible de traiter la réponse de l'IA");
        }

        final menu = parsedResult.name;
        final ingredients = parsedResult.ingredients;

        setState(() {
          menuName = menu;
          _items.clear();
          _items.addAll(ingredients);
          _isLoading = false;
        });
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        print('Erreur : $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _onDismissed(int index, DismissDirection direction) {
    setState(() {
      if (direction == DismissDirection.startToEnd) {
        _items[index].isSelected = true;
      } else if (direction == DismissDirection.endToStart) {
        _items[index].isSelected = false;
      }
    });
  }

  double _calculateTotalPrice() {
    double total = 0;
    for (var item in _items) {
      if (item.isSelected) {
        total += item.price * item.quantity;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final double totalPrice = _calculateTotalPrice();

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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Valider', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            if (menuName.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      menuName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prix total: ${formatDouble(totalPrice)} XAF',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
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
              child: _items.isEmpty
                  ? Center(
                child: Text(
                  menuName.isEmpty
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
                  final item = _items[index];
                  return Dismissible(
                    key: Key('${item.name}_$index'),
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      _onDismissed(index, direction);
                      return false;
                    },
                    child: Card(
                      elevation: 3,
                      color: item.isSelected ? Colors.green[50] : Colors.white,
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
                                item.desctiption,
                                style: const TextStyle(fontSize: 14)
                            ),
                            Text(
                              '${formatDouble(item.price)} XAF x ${formatDouble(item.quantity)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        leading: Icon(
                          Icons.shopping_cart,
                          color: item.isSelected ? Colors.green : Colors.blueAccent,
                        ),
                        trailing: Text(
                          '${formatDouble(item.quantity * item.price)} XAF',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            item.isSelected = !item.isSelected;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _items.isEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          _saveditems.clear();
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
              const SnackBar(content: Text('Aucun article sélectionné')),
            );
            return;
          }
          if (menuName.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Veuillez valider le budget d\'abord')),
            );
            return;
          }
          var list = BuyList(
            name: "Liste pour $menuName",
            description: "Préparation de $menuName",
            items: _saveditems,
          );
          service.addBuyList(list, _saveditems).then((value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Liste créée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur : $error'),
                backgroundColor: Colors.red,
              ),
            );
          });
        },
        backgroundColor: Colors.blueAccent,
        elevation: 6,
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text('Enregistrer la liste', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      desctiption: json['description'],
      price: json['price'].toDouble(),
      quantity: json['quantity'] is int
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

  factory DishModel.fromJson(Map<String, dynamic> json) {
    return DishModel(
      name: json['name'],
      ingredients: (json['ingredients'] as List<dynamic>)
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