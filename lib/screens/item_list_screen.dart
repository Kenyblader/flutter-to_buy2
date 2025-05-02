import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/provider/theme_provider.dart';
import 'package:to_buy/screens/item_form_screen.dart';
import 'package:to_buy/screens/propse_menu.dart';
import 'package:provider/provider.dart' as provider;
import 'package:to_buy/services/firestore_service.dart';

class ItemListScreen extends ConsumerStatefulWidget {
  final DishModel list;

  const ItemListScreen({super.key, required this.list});
  @override
  ConsumerState<ItemListScreen> createState() => ItemListScreenState();
}

class ItemListScreenState extends ConsumerState<ItemListScreen> {
  late final DishModel list;
  List<BuyItem> _saveditems = [];

  @override
  void initState() {
    super.initState();
    list = widget.list;
  }

  void _onDismissed(int index, DismissDirection direction) {
    setState(() {
      if (direction == DismissDirection.startToEnd) {
        list.ingredients[index].isSelected = true;
      } else if (direction == DismissDirection.endToStart) {
        list.ingredients[index].isSelected = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider.Provider.of<Themeprovider>(
      context,
      listen: false,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        centerTitle: true,
        backgroundColor:
            themeProvider.themeData.appBarTheme.backgroundColor ??
            Colors.blueAccent,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.cookie_sharp))],
        iconTheme: IconThemeData(color: Colors.white, size: 30),
        elevation: 5,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: list.ingredients.length,
              itemBuilder: (context, index) {
                final item = list.ingredients[index];
                return Dismissible(
                  key: Key(item.name),
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
                            style: const TextStyle(fontSize: 14),
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
                      leading: const Icon(
                        Icons.shopping_cart,
                        color: Colors.blueAccent,
                      ),
                      trailing: Text(
                        '${formatDouble(item.quantity * item.price)} XAF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final service = FirestoreService();
          for (var item in list.ingredients) {
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
          if (list.name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez valider le budget d\'abord'),
              ),
            );
            return;
          }
          var generatedList = BuyList(
            name: "generated list ${DateTime.now().millisecond}",
            description: "preparation de ${list.name}",
            items: _saveditems,
          );
          service
              .addBuyList(generatedList, _saveditems)
              .then((value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Liste créée avec succès')),
                );
                Navigator.pop(context, generatedList);
              })
              .catchError((error) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur : $error')));
              });
        },
        backgroundColor: Colors.blueAccent,
        elevation: 6,
        child: const Text('Save', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
