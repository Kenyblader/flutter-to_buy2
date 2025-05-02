import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:to_buy/components/style_button.dart';
import 'package:to_buy/validators/login_form_validators.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final void Function(String, String, GlobalKey<FormState>) onSubmit;
  final void Function() goToRegister;
  final String? errorMessage;

  LoginForm({
    super.key,
    required this.onSubmit,
    required this.goToRegister,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    return Form(
      key: formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: emailValidator,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                prefixIcon: Icon(Icons.lock),
                labelText: 'Mot de passe',
              ),
              obscureText: true,
              validator: passwordValidator,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(height: 10),

          TextButton(
            onPressed:
                () => onSubmit(
                  emailController.text,
                  passwordController.text,
                  formKey,
                ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              elevation: 15,
              fixedSize: Size(500, 50),
            ),
            child: const Text(
              'Connexion',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),
          TextButton(
            onPressed: goToRegister,
            child: const Text("Pas encore de compte ? Inscrivez-vous"),
          ),
        ],
      ),
    );
  }
}
