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
      if (isLogin) {
        try {
          final data = await authService.signInWithEmail(email, password);
          if (data == null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (predicate) => false,
            );
          } else {
            setState(() {
              errorMessage = data;
            });
          }
        } catch (e) {
          errorMessage = 'desole erreur de connexion au serveur';
        }
      } else {
        try {
          final data = await authService.signUpWithEmail(email, password);
          if (data == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("inscription reussit mtn connectez vous")),
            );
            setState(() {
              isLogin = true;
            });
          } else {
            setState(() {
              errorMessage = data;
            });
          }
        } catch (e) {
          errorMessage = 'erreur serveur veuiller reesayer plus tard';
        }
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
