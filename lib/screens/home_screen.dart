import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:to_buy/components/nav_card.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/provider/auth_provider.dart';
import 'package:to_buy/provider/theme_provider.dart';
import 'package:to_buy/screens/item_form_screen.dart';
import 'package:to_buy/screens/item_list_all_screen.dart';
import 'package:to_buy/screens/list_screen.dart';
import 'package:to_buy/screens/login_register_screen.dart';
import 'package:to_buy/widgets/listify_widget.dart';

import '../widgets/shared_preferences_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<Themeprovider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ListiFy'),
        centerTitle: true,
        titleSpacing: 10,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 25),
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        actions: [
          IconButton(
            onPressed: () {
              _showLogoutDialog();
            },
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.logout_rounded,
                color: const Color.fromARGB(255, 253, 252, 252),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'ListiFy',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                ListifyWidgetManager.updateHeadline(BuyList(name: "parmBuyList", description: " description param"));
                print("HomeScreen Modifier");
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Mon Compte'),
              onTap: () async {
               var x=await HomeWidget.saveWidgetData("id", "string");
               print(x);
              },
            ),
            ListTile(
              leading:
                  themeProvider.isDark
                      ? const Icon(Icons.light_mode)
                      : const Icon(Icons.dark_mode),
              title: Text(themeProvider.isDark ? 'Mode Sombre' : 'Mode Clair'),
              onTap: () {
                themeProvider.toggleTheme();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('À propos'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.contact_support),
              title: const Text('Aide'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavCard(
              title: "Nouvelle Liste",
              icon: Icons.newspaper_rounded,
              destination: const ItemFormScreen(),
            ),
            NavCard(
              title: "Mes Listes",
              icon: Icons.article_rounded,
              destination: const ListScreen(),
            ),
            // NavCard(
            //   title: "Nouvel Article",
            //   icon: Icons.add_circle_rounded,
            //   destination: const ItemFormScreen(),
            // ),
            NavCard(
              title: "Mes Articles",
              icon: Icons.add_shopping_cart_sharp,
              destination: const ItemListAllScreen(),
            ),
          ],
        ),
      ),
    );
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
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
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
}
