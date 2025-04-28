import 'package:flutter/material.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/services/firestore_service.dart';

class RestoreListScreen extends StatelessWidget {
  const RestoreListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurer une liste'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<List<BuyList>>(
        stream: FirestoreService().getDeletedBuyLists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erreur de chargement des listes supprimées'),
            );
          }
          final deletedLists = snapshot.data ?? [];
          if (deletedLists.isEmpty) {
            return const Center(
              child: Text('Aucune liste supprimée disponible'),
            );
          }
          return ListView.builder(
            itemCount: deletedLists.length,
            itemBuilder: (context, index) {
              final list = deletedLists[index];
              return ListTile(
                title: Text(list.name),
                subtitle: Text(list.description),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final nameController = TextEditingController();
                    final formKey = GlobalKey<FormState>();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Restaurer la liste'),
                            content: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Entrez le nom exact de la liste "${list.name}" pour la restaurer.',
                                  ),
                                  TextFormField(
                                    controller: nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom de la liste',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le nom';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.pop(context, true);
                                  }
                                },
                                child: const Text('Confirmer'),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      try {
                        await FirestoreService().restoreBuyList(
                          list.id!.toString(),
                          nameController.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Liste "${list.name}" restaurée'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur : ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Restaurer'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
