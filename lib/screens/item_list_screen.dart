import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:provider/provider.dart';
import 'package:to_buy/components/item_list.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/provider/theme_provider.dart';
import 'package:to_buy/screens/item_form_screen.dart';
import 'package:to_buy/screens/list_detail_screen.dart';
import 'package:to_buy/screens/restore_list_screen.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:provider/provider.dart' as provider;
import 'package:to_buy/provider/theme_provider.dart';

class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key, required this.list});
  final BuyList? list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = provider.Provider.of<Themeprovider>(
      context,
      listen: false,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes listes de courses'),
        centerTitle: true,
        backgroundColor:
            themeProvider.themeData.appBarTheme.backgroundColor ??
            Colors.blueAccent,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RestoreListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.restore, color: Colors.white),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: StreamBuilder<List<BuyList>>(
        stream: FirestoreService().getBuyLists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement des listes'));
          }
          final lists = snapshot.data ?? [];
          if (lists.isEmpty) {
            return const Center(child: Text('Aucune liste disponible'));
          }
          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Dismissible(
                key: Key(list.id!.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Confirmer la suppression'),
                          content: Text(
                            'Voulez-vous supprimer la liste "${list.name}" ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                  );
                },
                onDismissed: (direction) async {
                  await FirestoreService().deleteBuyList(list.id!.toString());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Liste "${list.name}" supprimée')),
                  );
                },
                child: ListTile(
                  title: Text(list.name),
                  subtitle: Text(list.description),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ListDetailScreen(listId: list.id!.toString()),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Voir détails'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ItemFormScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
