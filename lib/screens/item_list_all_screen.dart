import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_buy/components/item_list.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/provider/theme_provider.dart';
import 'package:to_buy/services/firestore_service.dart';

class ItemListAllScreen extends StatefulWidget {
  const ItemListAllScreen({super.key});
  @override
  State<ItemListAllScreen> createState() => _ItemListAllScreenState();
}

class _ItemListAllScreenState extends State<ItemListAllScreen> {
  final _searchController = TextEditingController();
  final _filteredItems = <BuyItem>[];
  List<BuyItem> items = [];
  final firestoreService = FirestoreService();

  void filterItems(String query) {
    setState(() {
      _filteredItems.clear();
      if (query.isEmpty) {
        _filteredItems.addAll(items);
      } else {
        _filteredItems.addAll(
          items.where(
            (item) => item.name.toLowerCase().contains(query.toLowerCase()),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    firestoreService.getBuyLists().listen((value) {
      for (var element in value) {
        items.addAll(element.items);
      }
      setState(() {
        _filteredItems.clear();
        _filteredItems.addAll(items);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<Themeprovider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            themeProvider.themeData.appBarTheme.backgroundColor ??
            Colors.blueAccent,
        title: const Text('Liste d\'achats'),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) {
              return [
                PopupMenuItem(child: Text("partager"), onTap: () {}),
                PopupMenuItem(
                  child: Text("Exporter"),
                  onTap: () {
                    print("ok");
                  },
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      label: Icon(Icons.search_outlined),
                    ),
                    onChanged: filterItems,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return Dismissible(
                  key: Key(item.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) {
                    return showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Supprimer l\'article'),
                            content: const Text(
                              'Êtes-vous sûr de vouloir supprimer cet article ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // Handle deletion logic here
                                  Navigator.pop(context);
                                },
                                child: const Text('Oui'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Non'),
                              ),
                            ],
                          ),
                    );
                  },
                  onDismissed: (direction) {
                    setState(() {
                      items.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} supprimé')),
                    );
                  },
                  child: ItemList(item: _filteredItems[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const ItemFormScreen()),
          // );
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
