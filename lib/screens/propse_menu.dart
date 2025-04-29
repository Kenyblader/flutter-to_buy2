import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/services/geminService.dart';

class ProposeMenu extends StatefulWidget {
  @override
  _ProposeMenuState createState() => _ProposeMenuState();
}

class _ProposeMenuState extends State<ProposeMenu> {
  final TextEditingController _budgetController = TextEditingController();
  final gemin = Geminservice().gemini;

  final List<ElementAffich> _items = [];
  final List<BuyItem> _saveditems = [];

  Map<String, dynamic> parseCustomJsonString(String input) {
    // Corriger les clés non-encadrées avec des guillemets
    final keyRegex = RegExp(r'(\w+):');
    final fixedJson = input.replaceAllMapped(
      keyRegex,
      (match) => '"${match[1]}":',
    );

    // Parser en JSON
    return jsonDecode(fixedJson);
  }

  void _validateBudget() {
    final budget = _budgetController.text;
    if (budget.isNotEmpty) {
      gemin
          .prompt(
            parts: [
              Part.text(
                "je suis un camerounais qui vis actuelement au cameroun et j'aimerais que aprtir des informations que tu as su la cuisine camerounaise te me propose un menu que je peux faire avec la somme de $budget",
              ),
              Part.text(
                "ta reponse ne dois comporter aucun formuel car je la parserais en brute pour quelle respecte cette strecuture menu:{name:\"ici tu metra le nom du menu que tu me propose tel qu'il est appeler au cameroun \",ingredients:[{name:\"ici le nom de l'ingredient\",description:\"l'utilite de l'ingredient\",price:le prix unitaire en double,quantity:int}]}",
              ),
              Part.text(
                "surtout noublis pas de bien formater le resultat car le mesage que vas me renvoyer sera parser en json tel quel",
              ),
            ],
          )
          .then((result) {
            final parsedResult = parseCustomJsonString(
              result?.output as String,
            );
            final menu = parsedResult['menu'];
            final ingredients = menu['ingredients'] as List<dynamic>;

            List<ElementAffich> items =
                ingredients.map((ingredient) {
                  return ElementAffich(
                    name: ingredient['name'],
                    price: ingredient['price'].toDouble(),
                    quantity: ingredient['quatity'],
                    desctiption: ingredient['description'],
                  );
                }).toList();

            setState(() {
              _items.clear();
              _items.addAll(items);
            });
          })
          .catchError((e) {
            print('Erreur: $e');
          });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un budget valide')),
      );
    }
  }

  void _onDismissed(ElementAffich item, DismissDirection direction) {
    if (direction == DismissDirection.startToEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action gauche-droite sur ${item.name}')),
      );
    } else if (direction == DismissDirection.endToStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action droite-gauche sur ${item.name}')),
      );
    }
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
            Text(
              'Entrez votre budget :',
              style: Theme.of(context).textTheme.labelMedium,
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
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Dismissible(
                    key: Key(item.name),
                    onDismissed: (direction) => _onDismissed(item, direction),
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
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text('Prix: \$${item.price}'),
                        leading: Icon(Icons.shopping_cart),
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
}

class ElementAffich {
  String name;
  String desctiption;
  double price;
  double quantity;

  ElementAffich({
    required this.desctiption,
    required this.name,
    required this.price,
    required this.quantity,
  });
}
