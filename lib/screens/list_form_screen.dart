import 'package:flutter/material.dart';
import 'package:to_buy/components/style_button.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/screens/item_list_screen.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:to_buy/validators/list_form_validators.dart';

class ListFormScreen extends StatefulWidget {
  const ListFormScreen({super.key});

  @override
  _ListFormScreenState createState() => _ListFormScreenState();
}

// This screen will serve as a form for creating a BuyList
class _ListFormScreenState extends State<ListFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _listNameController = TextEditingController();
  final TextEditingController _listDescriptController = TextEditingController();
  final firebaseService = FirestoreService();
  bool isCharging = false; // Assuming you have a FirebaseService class

  Future<void> _saveList() async {
    if (_formKey.currentState!.validate()) {
      print('Form is valid!');
      setState(() {
        isCharging = true;
        print('Saving list...');
      });
      final listName = _listNameController.text;
      final listDescript = _listDescriptController.text;
      final list = BuyList(name: listName, description: listDescript);
      await firebaseService
          .addBuyList(list, [])
          .then((onValue) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Liste enregistrée avec succès !')),
            );
            // Navigator.pushAndRemoveUntil(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => ItemListScreen(list: list),
            //   ),
            //   (predicate) => false,
            // );
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erreur lors de l\'enregistrement de la liste : $error',
                ),
              ),
            );
          })
          .whenComplete(() {
            setState(() {
              isCharging = false;
            });
          });
      _listNameController.clear();
      _listDescriptController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nouvelle Liste')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _listNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la liste',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    prefixIcon: Icon(Icons.list_rounded),
                  ),
                  validator: listNameValidator,
                ),
                SizedBox(height: 16),

                SizedBox(height: 16),
                TextFormField(
                  controller: _listDescriptController,
                  decoration: InputDecoration(
                    labelText: 'Description des articles',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(255, 243, 215, 33),
                      ),
                    ),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                SizedBox(height: 32),
                Center(
                  child: StyleButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the form
                    },
                    child: Text('Annuler'),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: StyleButton(
                    onPressed: _saveList,
                    child: Text('Enregistrer la liste'),
                  ),
                ),
                SizedBox(height: 16),
                if (isCharging) Center(child: CircularProgressIndicator()),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
