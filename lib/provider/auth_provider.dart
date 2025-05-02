import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_buy/models/user.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:to_buy/services/sqligthServices.dart';

// Provider pour écouter l'état de l'utilisateur
// final authStateProvider = StreamProvider<User?>((ref) {
//   return ref.watch(authProvider).authStateChanges;
// });

// Provider pour les opérations d'authentification
final authProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  var service = FirestoreService();
  static String userId = '';
  // Connexion avec email et mot de passe
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      var user = await service.getUserByEmail(email, password);
      if (user == null) {
        return 'Aucun utilisateur trouvé avec cet email.';
      }
      userId = user.id.toString();
      return null; // Pas d'erreur
      // Pas d'erreur
    } on Exception catch (e) {
      print("erreur de connexion: ${e.toString()}");
      return e.toString();
    }
  }

  // Inscription avec email et mot de passe
  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      await service.insertUser(User(email: email, password: password));
      // Déconnexion automatique après inscription
      return null; // Pas d'erreur
    } on Exception catch (e) {
      print("erreur d'incription: ${e.toString()}");
      return e.toString();
    }
  }

  // Déconnexion
  Future<void> signOut() async {}
}
