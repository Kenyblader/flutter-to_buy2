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
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

import '../widgets/shared_preferences_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _floatingWidgetChannel = MethodChannel(
    'com.example.to_buy/floating_widget',
  );
  static const _pipChannel = MethodChannel('com.example.tobuy/pip');
  bool _isFloatingWidgetActive = false;

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
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Continuer'),
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

  Future<void> _enterPipMode() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode Picture-in-Picture non supporté sur iOS'),
        ),
      );
      return;
    }

    try {
      await _pipChannel.invokeMethod('enterPipMode');
      print('Mode PiP déclenché');
    } catch (e) {
      print('Erreur PiP: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur PiP: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<Themeprovider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ListiFy'),
        centerTitle: true,
        titleSpacing: 10,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 25),
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture),
            color: Colors.white,
            onPressed: _enterPipMode,
          ),
          IconButton(
            icon: Icon(
              _isFloatingWidgetActive ? Icons.close : Icons.bubble_chart,
            ),
            color: _isFloatingWidgetActive ? Colors.red : Colors.white,
            onPressed: _toggleFloatingWidget,
          ),
          IconButton(
            onPressed: () {
              _showLogoutDialog();
            },
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(5),
              child: const Icon(
                Icons.logout_rounded,
                color: Color.fromARGB(255, 253, 252, 252),
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
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'ListiFy',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                ListifyWidgetManager.updateHeadline();
                print("HomeScreen Modifier");
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Mon Compte'),
              onTap: () async {
                var x = await HomeWidget.saveWidgetData("id", "string");
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
}
