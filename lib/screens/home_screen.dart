import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/provider/auth_provider.dart';
import 'package:to_buy/provider/theme_provider.dart';
import 'package:to_buy/screens/item_form_screen.dart';
import 'package:to_buy/screens/item_list_all_screen.dart';
import 'package:to_buy/screens/list_detail_screen.dart';
import 'package:to_buy/screens/login_register_screen.dart';
import 'package:to_buy/screens/propse_menu.dart';
import 'package:to_buy/screens/map_screen.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:to_buy/widgets/listify_widget.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _floatingWidgetChannel = MethodChannel(
    'com.example.to_buy/floating_widget',
  );
  bool _isFloatingWidgetActive = false;
  bool isLoading = true;
  final _searchController = TextEditingController();
  final List<BuyList> _filteredItems = [];
  final List<BuyList> items = [];
  final fireSoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    var list = fireSoreService.getBuyLists();
    list.listen((event) {
      setState(() {
        items.clear();
        items.addAll(event);
        _filteredItems.clear();
        _filteredItems.addAll(items);
        isLoading = false;
      });
    });
    _searchController.addListener(() {
      filterItems(_searchController.text);
    });
  }

  void filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems.clear();
        _filteredItems.addAll(items);
      } else {
        _filteredItems.clear();
        _filteredItems.addAll(
          items.where(
            (item) => item.name.toLowerCase().contains(query.toLowerCase()),
          ),
        );
      }
    });
  }

  Future<void> _toggleFloatingWidget() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bouton flottant non supporté sur iOS')),
      );
      return;
    }

    try {
      if (_isFloatingWidgetActive) {
        await _floatingWidgetChannel.invokeMethod('stopFloatingWidget');
        setState(() {
          _isFloatingWidgetActive = false;
        });
        print('Bouton flottant fermé');
      } else {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Permission requise'),
                content: const Text(
                  'Pour afficher un bouton flottant par-dessus d\'autres applications, '
                  'vous devez accorder la permission d\'affichage. Voulez-vous continuer ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
        );
        if (shouldProceed != true) return;

        if (await Permission.systemAlertWindow.request().isGranted) {
          await _floatingWidgetChannel.invokeMethod('startFloatingWidget');
          setState(() {
            _isFloatingWidgetActive = true;
          });
          print('Bouton flottant ouvert');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permission d\'affichage refusée'),
              action: SnackBarAction(
                label: 'Réessayer',
                onPressed: _toggleFloatingWidget,
              ),
            ),
          );
          print('Permission refusée');
        }
      }
    } on PlatformException catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.message ?? 'Erreur inconnue'}')),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final authService = AuthService();
                authService.signOut().then((onValue) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginRegisterScreen(),
                    ),
                    (predicate) => false,
                  );
                });
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<Themeprovider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ListiFy'),
        centerTitle: true,
        titleSpacing: 10,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemListAllScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProposeMenu()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.location_on), // Added location icon
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
          ),
        ],
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'ListiFy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blueAccent),
              title: const Text('Paramètres'),
              onTap: () {
                ListifyWidgetManager.updateHeadline();
                print("HomeScreen Modifier");
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.account_circle,
                color: Colors.blueAccent,
              ),
              title: const Text('Mon Compte'),
              onTap: () async {
                var x = await HomeWidget.saveWidgetData("id", "string");
                print(x);
              },
            ),
            ListTile(
              leading:
                  themeProvider.isDark
                      ? const Icon(Icons.light_mode, color: Colors.blueAccent)
                      : const Icon(Icons.dark_mode, color: Colors.blueAccent),
              title: Text(themeProvider.isDark ? 'Mode Sombre' : 'Mode Clair'),
              onTap: () {
                themeProvider.toggleTheme();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blueAccent),
              title: const Text('À propos'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Icons.contact_support,
                color: Colors.blueAccent,
              ),
              title: const Text('Aide'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(
                _isFloatingWidgetActive ? Icons.close : Icons.bubble_chart,
                color: _isFloatingWidgetActive ? Colors.red : Colors.blueAccent,
              ),
              title: Text(
                _isFloatingWidgetActive
                    ? 'Désactiver Bouton Flottant'
                    : 'Activer Bouton Flottant',
              ),
              onTap: _toggleFloatingWidget,
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Déconnexion'),
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Rechercher une liste',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.blueAccent,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          _filteredItems.isEmpty
                              ? const Center(
                                child: Text(
                                  'Aucune liste de courses pour le moment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  return Dismissible(
                                    key: ValueKey(_filteredItems[index].id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                      ),
                                      alignment: Alignment.centerRight,
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (direction) {
                                      return showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Supprimer la liste',
                                              ),
                                              content: const Text(
                                                'Êtes-vous sûr de vouloir supprimer cette liste ?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Non'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    fireSoreService
                                                        .deleteBuyList(
                                                          _filteredItems[index]
                                                              .id!,
                                                        )
                                                        .then((val) {
                                                          setState(() {
                                                            items.removeAt(
                                                              index,
                                                            );
                                                            _filteredItems
                                                                .removeAt(
                                                                  index,
                                                                );
                                                          });
                                                        })
                                                        .catchError((e) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Erreur : $e',
                                                              ),
                                                            ),
                                                          );
                                                        });
                                                    Navigator.pop(
                                                      context,
                                                      true,
                                                    );
                                                  },
                                                  child: const Text('Oui'),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          _filteredItems[index].name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _filteredItems[index].description ??
                                              "",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.blueAccent,
                                        ),
                                        leading:
                                            _filteredItems[index].isComplete
                                                ? const Icon(
                                                  Icons.check,
                                                  color: Colors.green,
                                                )
                                                : null,
                                        onTap:
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => ListDetailScreen(
                                                      listId:
                                                          _filteredItems[index]
                                                              .id!,
                                                    ),
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
        onPressed: () async {
          // Attendre le résultat de ItemFormScreen
          final newList = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ItemFormScreen()),
          );
          // Si une nouvelle liste est renvoyée, l'ajouter localement
          if (newList != null && newList is BuyList) {
            setState(() {
              items.add(newList);
              _filteredItems.add(newList);
            });
          }
        },
        backgroundColor: Colors.blueAccent,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
