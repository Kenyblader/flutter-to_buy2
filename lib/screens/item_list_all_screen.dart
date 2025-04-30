import 'dart:async';
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
  final List<BuyItem> _filteredItems = [];
  final List<BuyItem> _allItems = []; // Liste principale d'articles uniques
  final FirestoreService firestoreService = FirestoreService();
  bool _isLoading = true;
  StreamSubscription? _subscription; // Pour gérer l'abonnement

  void filterItems(String query) {
    setState(() {
      _filteredItems.clear();
      if (query.isEmpty) {
        _filteredItems.addAll(_allItems);
      } else {
        _filteredItems.addAll(
          _allItems.where(
                (item) => item.name.toLowerCase().contains(query.toLowerCase()),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _isLoading = true;
      _allItems.clear(); // Vider complètement la liste avant de recharger
    });

    // Annuler l'abonnement précédent s'il existe
    _subscription?.cancel();

    // Créer un nouvel abonnement
    _subscription = firestoreService.getBuyLists().listen((buyLists) {
      // Map temporaire pour détecter et éliminer les doublons
      final Map<String, BuyItem> itemsMap = {};

      // Parcourir toutes les listes et tous les articles
      for (var buyList in buyLists) {
        for (var item in buyList.items) {
          // Utiliser une clé unique basée sur le nom (en minuscules pour ignorer la casse)
          final key = item.name.toLowerCase();

          // Ne garder que l'élément le plus récent si des doublons existent
          if (!itemsMap.containsKey(key) ||
              (item.date != null && itemsMap[key]!.date != null &&
                  item.date!.isAfter(itemsMap[key]!.date!))) {
            itemsMap[key] = item;
          }
        }
      }

      setState(() {
        // Reconstruire complètement la liste avec les éléments uniques
        _allItems.clear();
        _allItems.addAll(itemsMap.values);

        // Trier par ordre alphabétique
        _allItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        // Mettre à jour la liste filtrée
        _filteredItems.clear();
        _filteredItems.addAll(_allItems);
        _isLoading = false;
      });
    }, onError: (error) {
      print("Erreur de chargement des données: $error");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $error')),
      );
    });
  }

  @override
  void dispose() {
    // S'assurer de libérer les ressources
    _searchController.dispose();
    _subscription?.cancel();
    super.dispose();
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadItems, // Permet de rafraîchir manuellement la liste
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) {
              return [
                const PopupMenuItem(child: Text("Partager")),
                PopupMenuItem(
                  child: const Text("Exporter"),
                  onTap: () {
                    print("Exporter");
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
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Icon(Icons.search_outlined),
                      hintText: 'Rechercher un article',
                    ),
                    onChanged: filterItems,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                ? const Center(child: Text('Aucun article trouvé'))
                : RefreshIndicator(
              onRefresh: () async {
                _loadItems();
              },
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return Dismissible(
                    key: Key(item.id ?? DateTime.now().millisecondsSinceEpoch.toString() + item.name),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer l\'article'),
                          content: Text(
                            'Êtes-vous sûr de vouloir supprimer "${item.name}" ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Oui'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Non'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      // Supprimer localement
                      final removedItem = _filteredItems[index];
                      setState(() {
                        _filteredItems.removeAt(index);
                        _allItems.remove(removedItem);
                      });

                      // Ici, ajouter la logique pour supprimer de Firestore
                      // firestoreService.deleteItem(removedItem.id);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${removedItem.name} supprimé'),
                          action: SnackBarAction(
                            label: 'Annuler',
                            onPressed: () {
                              setState(() {
                                // Restaurer l'élément dans les listes
                                _allItems.add(removedItem);
                                filterItems(_searchController.text);
                              });
                              // Logique pour annuler la suppression dans Firestore si nécessaire
                            },
                          ),
                        ),
                      );
                    },
                    child: ItemList(item: item),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ajouter la navigation vers ItemFormScreen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const ItemFormScreen()),
          // ).then((value) {
          //   if (value != null) {
          //     // Recharger complètement les données après avoir ajouté un nouvel élément
          //     _loadItems();
          //   }
          // });
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