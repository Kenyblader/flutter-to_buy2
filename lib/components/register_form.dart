import 'package:flutter/material.dart';
import 'package:to_buy/components/style_button.dart';
import 'package:to_buy/validators/login_form_validators.dart';

class RegisterForm extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final void Function(String, String, GlobalKey<FormState>) onSubmit;
  final void Function() goToLogin;
  final String? errorMessage;

  RegisterForm({
    super.key,
    required this.onSubmit,
    required this.goToLogin,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: TextFormField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                prefixIcon: Icon(Icons.lock),
                labelText: 'Confirmer mot de passe',
              ),
              obscureText: true,
              validator: (confirmPassword) => confirmPasswordValidator(
                passwordController.text,
                confirmPassword,
              ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: StyleButton(
                    onPressed: () => onSubmit(
                      emailController.text,
                      passwordController.text,
                      formKey,
                    ),
                    child: const Text("S'inscrire"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: goToLogin,
                    child: const Text('Déjà inscrit ? Connexion'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: StyleButton(
              onPressed: () {
                // TODO: Implémenter Google Sign-In
              },
              backgroundColor: Colors.teal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.g_mobiledata_outlined,
                    color: Colors.red,
                    size: 40,
                  ),
                  SizedBox(width: 10),
                  Text("Se connecter avec Google"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}