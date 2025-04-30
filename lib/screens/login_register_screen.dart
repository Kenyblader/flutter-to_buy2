import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_buy/components/login_form.dart';
import 'package:to_buy/components/register_form.dart';
import 'package:to_buy/provider/auth_provider.dart';
import 'package:to_buy/screens/home_screen.dart';

class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() =>
      _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen> {
  bool isLogin = true;
  String? errorMessage;
  bool isSubmitting = false;

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = null; // Réinitialiser le message d'erreur
    });
  }

  Future<void> onSubmit(
    String email,
    String password,
    GlobalKey<FormState> formKey,
  ) async {
    print("email: $email, password: $password");
    if (formKey.currentState!.validate()) {
      setState(() {
        isSubmitting = true; // Indiquer que la soumission est en cours
        errorMessage = null;
      });
      final authService = ref.read(authProvider);
      String? error;
      if (isLogin) {
        await authService.signInWithEmail(email, password).then((errore) {
          print('error: $error');
          if (error == 'invalid-credential') {
            error = 'Identifiants invalides.';
          } else if (errore == 'user-not-found') {
            error = 'Aucun utilisateur trouvé avec cet email.';
          } else if (errore == 'wrong-password') {
            error = 'Mot de passe incorrect.';
          } else if (errore == 'invalid-email') {
            error = 'Email invalide.';
          } else if (errore == 'user-disabled') {
            error = 'Utilisateur désactivé.';
          } else if (errore == 'operation-not-allowed') {
            error = 'L\'opération n\'est pas autorisée.';
          } else if (errore == 'too-many-requests') {
            error = 'Trop de demandes. Veuillez réessayer plus tard.';
          } else if (errore == 'network-request-failed') {
            error = 'Échec de la demande réseau. Vérifiez votre connexion.';
          } else if (errore == 'email-already-in-use') {
            error = 'Cet email est déjà utilisé.';
          } else if (errore == 'weak-password') {
            error = 'Le mot de passe est trop faible.';
          } else if (errore == null) {
            // Connexion réussie
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connexion réussie !')),
            );
          }
        });
      } else {
        error = await authService.signUpWithEmail(email, password);
      }
      setState(() {
        isSubmitting = false; // Terminer la soumission
        errorMessage = error;
      });
      if (error == null) {
        // Redirection après connexion réussie
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error as String)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Connexion' : 'Inscription'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            isLogin
                ? LoginForm(
                  onSubmit: onSubmit,
                  goToRegister: toggleForm,
                  errorMessage: errorMessage,
                )
                : RegisterForm(
                  onSubmit: onSubmit,
                  goToLogin: toggleForm,
                  errorMessage: errorMessage,
                ),
          ],
        ),
      ),
    );
  }
}
