import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider pour écouter l'état de l'utilisateur
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provider pour les opérations d'authentification
final authProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Connexion avec email et mot de passe
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      var s = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .then((user) {
            if (user.user == null) {
              return 'invalid-credential'; // Identifiants invalides
            } else if (user.user!.emailVerified == false) {
              return 'email-not-verified'; // Email non vérifié
            } else if (user.user!.emailVerified == true) {
              return null;
            } else {
              return 'erreur reseaux';
            }
          });
      print('auth logins: $s');
      return s;
      // Pas d'erreur
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  // Inscription avec email et mot de passe
  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Déconnexion automatique après inscription
      await _auth.signOut();
      return null; // Pas d'erreur
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Gestion des erreurs Firebase
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'L\'email est invalide.';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      default:
        return 'Une erreur s\'est produite : ${e.message}';
    }
  }
}
