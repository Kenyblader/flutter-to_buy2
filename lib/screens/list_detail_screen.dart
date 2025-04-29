import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:provider/provider.dart' as provider;
import 'package:to_buy/provider/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListDetailScreen extends StatelessWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  // Fonction pour afficher le formulaire d'ajout d'article
  Future<void> _showAddItemDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ajouter un article'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Prix (€)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un prix';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Veuillez entrer un prix valide';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Veuillez entrer une quantité valide';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      final newItem = BuyItem(
                        id: null,
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        quantity: double.parse(quantityController.text),
                        date: DateTime.now(),
                      );
                      print(
                        'Tentative d\'ajout de l\'article: ${newItem.name}, Liste ID: $listId',
                      );
                      await FirestoreService().addItemToList(listId, newItem);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Article ajouté avec succès'),
                        ),
                      );
                    } catch (e) {
                      print('Erreur lors de l\'ajout de l\'article: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
                      );
                    }
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
    );
  }

  // Fonction pour afficher le formulaire de modification
  Future<void> _showEditItemDialog(
    BuildContext context,
    BuyItem item,
    String itemId,
  ) async {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifier l\'article'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Prix (€)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un prix';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Veuillez entrer un prix valide';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Veuillez entrer une quantité valide';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      final updatedItem = BuyItem(
                        id: item.id,
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        quantity: double.parse(quantityController.text),
                        date: item.date,
                      );
                      print(
                        'Tentative de modification de l\'article: $itemId, Liste ID: $listId',
                      );
                      await FirestoreService().updateItem(
                        listId,
                        itemId,
                        updatedItem,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Article modifié avec succès'),
                        ),
                      );
                    } catch (e) {
                      print('Erreur lors de la modification: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la modification: $e'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  // Fonction pour générer et partager un PDF
  Future<void> _shareList(BuildContext context, List<BuyItem> items) async {
    final listSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirestoreService().userId)
            .collection('lists')
            .doc(listId)
            .get();

    if (!listSnapshot.exists) {
      print('Erreur: Liste $listId introuvable');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : Liste introuvable')),
      );
      return;
    }

    final listData = listSnapshot.data()!;
    final list = BuyList(
      id: listSnapshot.id,
      name: listData['name'] as String,
      description: listData['description'] as String,
      expirationDate:
          listData['expirationDate'] != null
              ? (listData['expirationDate'] as Timestamp).toDate()
              : null,
      items: items,
    );

    final pdf = pw.Document();
    final total = items.fold(0.0, (sum, item) => sum + item.getTotal());

    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Liste de courses : ${list.name}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Description : ${list.description}',
                  style: pw.TextStyle(fontSize: 16),
                ),
                if (list.expirationDate != null)
                  pw.Text(
                    'Date d\'expiration : ${list.expirationDate!.toLocal().toString().split(' ')[0]}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Articles :',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor(0.78, 0.78, 0.78),
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Nom',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Prix unitaire',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Quantité',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...items.map(
                      (item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(item.name),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '${item.price.toStringAsFixed(2)} €',
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(item.quantity.toStringAsFixed(0)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '${(item.price * item.quantity).toStringAsFixed(2)} €',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Total général : ${total.toStringAsFixed(2)} Fcfa',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/liste_${list.name.replaceAll(' ', '_')}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    final param = ShareParams(
      text: 'Voici la liste de courses "${list.name}" en PDF.',
      subject: 'Liste de courses : ${list.name}',
      files: [XFile(file.path)],
    );

    var result = await SharePlus.instance.share(param);

    if (result.status == ShareResultStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste partagée avec succès')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du partage de la liste')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider.Provider.of<Themeprovider>(
      context,
      listen: false,
    );
    print('Construction de ListDetailScreen, listId: $listId');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la liste'),
        backgroundColor:
            themeProvider.themeData.appBarTheme.backgroundColor ??
            Colors.blueAccent,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: FutureBuilder<Stream<List<BuyItem>>>(
        future: FirestoreService().getItemsForList(listId),
        builder: (context, futureSnapshot) {
          if (futureSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (futureSnapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement des articles: ${futureSnapshot.error}',
              ),
            );
          }
          final stream = futureSnapshot.data;
          if (stream == null) {
            return const Center(child: Text('Aucun article dans cette liste'));
          }
          return StreamBuilder<List<BuyItem>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print(
                  'StreamBuilder: En attente des données pour listId: $listId',
                );
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print(
                  'StreamBuilder: Erreur lors du chargement des articles: ${snapshot.error}',
                );
                return Center(
                  child: Text(
                    'Erreur de chargement des articles: ${snapshot.error}',
                  ),
                );
              }
              final items = snapshot.data ?? [];
              print(
                'StreamBuilder: ${items.length} articles chargés pour listId: $listId',
              );
              print(
                'Articles: ${items.map((item) => "${item.name} ").toList()}',
              );
              if (items.isEmpty) {
                return const Center(
                  child: Text('Aucun article dans cette liste'),
                );
              }
              final total = items.fold(
                0.0,
                (sum, item) => sum + item.getTotal(),
              );
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final itemId = item.id ?? '';
                        print(
                          'Affichage de l\'article: ${item.name}, itemId: $itemId, listId: $listId',
                        );
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            'Prix: ${item.price.toStringAsFixed(2)} Fcfa | Qté: ${item.quantity.toStringAsFixed(0)}',
                          ),
                          leading: Checkbox(
                            value: item.isBuy,
                            onChanged: (value) async {
                              if (item.id == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Erreur: ID de l\'article invalide',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                await FirestoreService().toggleItemStatus(
                                  listId,
                                  itemId,
                                  value!,
                                );
                                // Update the local state of the item
                                (context as Element)
                                    .markNeedsBuild(); // Trigger a rebuild to reflect changes
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erreur lors de la mise à jour: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  if (itemId.isEmpty) {
                                    print(
                                      'Erreur: ID de l\'article invalide pour ${item.name}',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Erreur: ID de l\'article invalide',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  _showEditItemDialog(context, item, itemId);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  if (itemId.isEmpty) {
                                    print(
                                      'Erreur: ID de l\'article invalide pour ${item.name}',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Erreur: ID de l\'article invalide',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            'Confirmer la suppression',
                                          ),
                                          content: Text(
                                            'Voulez-vous supprimer l\'article "${item.name}" ?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Annuler'),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('Supprimer'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      print(
                                        'Lancement de la suppression de l\'article: $itemId, listId: $listId',
                                      );
                                      await FirestoreService().deleteItem(
                                        listId,
                                        itemId,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Article supprimé avec succès',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      print(
                                        'Erreur lors de la suppression de l\'article $itemId: $e',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Erreur lors de la suppression: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total de la liste: ${total.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _shareList(context, items),
                      icon: const Icon(Icons.share),
                      label: const Text('Partager la liste'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor:
            themeProvider.themeData.floatingActionButtonTheme.backgroundColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
