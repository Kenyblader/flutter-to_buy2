import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:to_buy/components/style_button.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:to_buy/services/geminService.dart';
import 'package:to_buy/validators/add_form_validators.dart';
import 'package:provider/provider.dart';
import 'package:to_buy/provider/theme_provider.dart';

class ItemFormScreen extends StatefulWidget {
  final BuyItem? item;
  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  final List<ItemPropose> iaItem = [];
  double _total = 0.0;
  List<BuyItem> _existingItems = [];
  Map<String, BuyItem> _existingItemsMap = {}; // Map pour recherche rapide par nom

  @override
  void initState() {
    super.initState();
    _addItemRow();
    _loadExistingItems();
  }

  void _loadExistingItems() {
    FirestoreService().getBuyLists().listen((buyLists) {
      setState(() {
        _existingItems.clear();
        _existingItemsMap.clear();

        for (var buyList in buyLists) {
          for (var item in buyList.items) {
            // Si cet article n'existe pas encore dans notre map ou si sa date est plus récente
            if (!_existingItemsMap.containsKey(item.name.toLowerCase()) ||
                (item.date != null && _existingItemsMap[item.name.toLowerCase()]!.date != null &&
                    item.date!.isAfter(_existingItemsMap[item.name.toLowerCase()]!.date!))) {
              _existingItemsMap[item.name.toLowerCase()] = item;
            }
          }
        }

        // Mettre à jour la liste des articles existants à partir de la map
        _existingItems = _existingItemsMap.values.toList();
      });
    });
  }

  void _addItemRow() {
    setState(() {
      _items.add({
        'name': TextEditingController(),
        'price': TextEditingController(),
        'quantity': TextEditingController(),
        'existingItem': null, // Référence au BuyItem existant (ou null pour nouvel article)
      });
    });
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _items) {
      final price = double.tryParse(item['price']!.text) ?? 0.0;
      final quantity = double.tryParse(item['quantity']!.text) ?? 0.0;
      total += price * quantity;
    }
    setState(() {
      _total = total;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotal();
    });
  }

  // Vérifier si un article avec le même nom existe déjà et l'utiliser
  void _checkForExistingItem(int index) {
    final itemName = _items[index]['name']!.text.trim().toLowerCase();
    if (itemName.isNotEmpty && _existingItemsMap.containsKey(itemName)) {
      setState(() {
        // Utiliser l'article existant
        final existingItem = _existingItemsMap[itemName]!;
        _items[index]['existingItem'] = existingItem;
        _items[index]['price']!.text = existingItem.price.toString();
        _items[index]['quantity']!.text = "1.0"; // Réinitialiser la quantité à 1
        _calculateTotal();
      });
    }
  }

  void _validateAndSave() async {
    if (_formKey.currentState!.validate()) {
      // Construire une liste temporaire pour vérifier les doublons dans la soumission actuelle
      final Map<String, int> currentSubmissionItems = {};

      final items = _items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final itemName = item['name']!.text.trim();

        // Vérifier si cet article a déjà été inclus dans cette soumission
        if (currentSubmissionItems.containsKey(itemName.toLowerCase())) {
          // Article déjà dans la liste courante, fusionner les quantités
          final existingIndex = currentSubmissionItems[itemName.toLowerCase()]!;
          final existingQuantity = double.parse(_items[existingIndex]['quantity']!.text);
          final newQuantity = double.parse(item['quantity']!.text);

          // Mettre à jour la quantité de l'article existant
          _items[existingIndex]['quantity']!.text = (existingQuantity + newQuantity).toString();

          // Retourner null pour indiquer que cet article a été fusionné
          return null;
        } else {
          // Marquer cet article comme inclus dans cette soumission
          currentSubmissionItems[itemName.toLowerCase()] = index;

          // Si un article existant a été sélectionné via autocomplétion
          if (item['existingItem'] != null) {
            BuyItem existing = item['existingItem'] as BuyItem;
            return BuyItem(
              id: existing.id, // Conserver l'ID pour réutiliser l'article existant
              name: itemName,
              price: double.parse(item['price']!.text),
              quantity: double.parse(item['quantity']!.text),
              date: DateTime.now(), // Mettre à jour la date
            );
          } else {
            // Nouvel article ou article existant identifié par nom
            final existingByName = _existingItemsMap[itemName.toLowerCase()];
            return BuyItem(
              id: existingByName?.id, // Réutiliser l'ID s'il existe
              name: itemName,
              price: double.parse(item['price']!.text),
              quantity: double.parse(item['quantity']!.text),
              date: DateTime.now(),
            );
          }
        }
      }).where((item) => item != null).cast<BuyItem>().toList();

      final buyList = BuyList(
        name: _nameController.text,
        description: _descriptionController.text,
        items: items,
      );

      try {
        await FirestoreService().addBuyList(buyList, items);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liste créée !')),
        );
        Navigator.pop(context, buyList);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  void proposeValue(String jsonString) {
    var cleanedJson = jsonString.trim();
    if (cleanedJson.startsWith('```json')) {
      cleanedJson = cleanedJson.substring(7, cleanedJson.length - 3).trim();
    } else if (cleanedJson.startsWith('```')) {
      cleanedJson = cleanedJson.substring(3, cleanedJson.length - 3).trim();
    }

    print('Réponse JSON brute : $cleanedJson');

    try {
      final jsonData = jsonDecode(cleanedJson) as Map<String, dynamic>;
      List<ItemPropose> items = [];

      if (jsonData.containsKey("items") && jsonData["items"] is List) {
        items = (jsonData["items"] as List)
            .map((data) => ItemPropose.fromJson(data as Map<String, dynamic>))
            .toList();

        setState(() {
          _items.addAll(
            items.map((item) {
              final itemName = item.name.trim().toLowerCase();
              final existingItem = _existingItemsMap[itemName];

              return {
                'name': TextEditingController(text: item.name),
                'price': TextEditingController(
                    text: existingItem?.price.toString() ?? item.price.toString()),
                'quantity': TextEditingController(text: item.quantity.toString()),
                'existingItem': existingItem,
              };
            }).toList(),
          );
          _calculateTotal();
        });
      }
    } catch (e) {
      print("Erreur lors du traitement de la réponse JSON: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<Themeprovider>(context, listen: false);

    try {
      if (_items.isNotEmpty && _items.every((item) {
        return item['name']?.text != null &&
            item['price']?.text != null &&
            item['quantity']?.text != null &&
            item['name']!.text.isNotEmpty &&
            item['price']!.text.isNotEmpty &&
            item['quantity']!.text.isNotEmpty;
      })) {
        Geminservice().getItemsWithOrder(
          _items
              .map(
                (e) => BuyItem(
              name: e['name']?.text as String,
              price: double.tryParse(e['price']?.text as String) ?? 0.0,
              quantity: double.tryParse(e['quantity']?.text as String) ?? 0.0,
            ),
          )
              .toList(),
          proposeValue,
        );
      }
    } catch (e) {
      print("erreur Gemini: $e");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une liste de courses'),
        backgroundColor:
        themeProvider.themeData.appBarTheme.backgroundColor ?? Colors.blueAccent,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la liste',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: validateName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: validateDescription,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Articles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controllers = entry.value;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Autocomplete<BuyItem>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<BuyItem>.empty();
                                }
                                return _existingItems.where((BuyItem item) {
                                  return item.name
                                      .toLowerCase()
                                      .contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              displayStringForOption: (BuyItem item) => item.name,
                              onSelected: (BuyItem selected) {
                                setState(() {
                                  controllers['name']!.text = selected.name;
                                  controllers['price']!.text = selected.price.toString();
                                  controllers['existingItem'] = selected;
                                  _calculateTotal();
                                });
                              },
                              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                textEditingController.text = controllers['name']!.text;
                                textEditingController.addListener(() {
                                  controllers['name']!.text = textEditingController.text;
                                  // Réinitialiser existingItem si le nom est modifié manuellement
                                  if (controllers['existingItem'] != null &&
                                      textEditingController.text != (controllers['existingItem'] as BuyItem).name) {
                                    controllers['existingItem'] = null;
                                  }
                                  _calculateTotal();
                                });
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Nom',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  validator: validateName,
                                  onChanged: (value) {
                                    _checkForExistingItem(index);
                                    _calculateTotal();
                                  },
                                  onEditingComplete: () => _checkForExistingItem(index),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: controllers['price'],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Prix',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: validatePrice,
                              onChanged: (_) => _calculateTotal(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: controllers['quantity'],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Qté',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: validateQuantity,
                              onChanged: (_) => _calculateTotal(),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeItem(index),
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: _addItemRow,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: ${_total.toStringAsFixed(2)} Fcfa',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(
                  child: StyleButton(
                    onPressed: _validateAndSave,
                    child: const Text('Valider la liste'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var item in _items) {
      item['name']!.dispose();
      item['price']!.dispose();
      item['quantity']!.dispose();
    }
    super.dispose();
  }
}

class ItemPropose {
  String name;
  double price;
  double quantity;
  ItemPropose({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory ItemPropose.fromJson(Map<String, dynamic> data) {
    try {
      return ItemPropose(
        name: data['name'] as String,
        price: (data['price'] is int)
            ? (data['price'] as int).toDouble()
            : data['price'] as double,
        quantity: (data['quantity'] is int)
            ? (data['quantity'] as int).toDouble()
            : data['quantity'] as double,
      );
    } catch (e) {
      print("Erreur lors de la conversion ItemPropose: $e");
      return ItemPropose(name: "Erreur", price: 0.0, quantity: 0.0);
    }
  }
}