import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart' as provider;
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/provider/theme_provider.dart';
import 'package:to_buy/screens/home_screen.dart';
import 'package:to_buy/screens/list_screen.dart';
import 'package:to_buy/screens/login_register_screen.dart';
import 'package:to_buy/services/geminService.dart';
import 'package:to_buy/widgets/listify_widget.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Geminservice.init();
  ListifyWidgetManager.setGroupId();
  ListifyWidgetManager.updateHeadline();
  runApp(
    riverpod.ProviderScope(
      child: provider.ChangeNotifierProvider<Themeprovider>(
        create: (_) => Themeprovider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider.Provider.of<Themeprovider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'to Buy',
      theme: themeProvider.themeData,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<StatefulWidget> createState() => AuthGateStata();
}

class AuthGateStata extends State<AuthGate> {
  static final platform = MethodChannel("ListifyWidgetRoutes");

  @override
  void initState() {
    super.initState();
    _checkWidgetIntent();
  }

  Future<void> _checkWidgetIntent() async {
    try {
      final result = await platform.invokeMethod('getWidgetIntentExtras');
      if (result != null) {
        final targetPage = result['target_page'] as String?;
        if (targetPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ListScreen()),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des extras : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapchot) {
        if (snapchot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapchot.hasData) {
          return HomeScreen();
        }
        return LoginRegisterScreen();
      },
    );
  }
}
