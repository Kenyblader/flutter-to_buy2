String? emailValidator(String? email) {
  // Regular expression for validating email
  const String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  final RegExp regex = RegExp(pattern);
  if (email == null || email.isEmpty) {
    return 'Email ne peut pas etre vide';
  } else if (!regex.hasMatch(email)) {
    return 'Format d\'email invalide';
  }
  return null;
}

String? passwordValidator(String? password) {
  print('password: $password');
  if (password == null || password.isEmpty) {
    return 'Mot de passe ne peut pas etre vide';
  } else if (password.length < 6) {
    return 'Le mot de passe doit contenir au moins 6 caractères';
  }
  return null;
}

String? confirmPasswordValidator(String? password, String? confirmPassword) {
  if (confirmPassword == null || confirmPassword.isEmpty) {
    return 'Confirmer le mot de passe ne peut pas etre vide';
  } else if (password != confirmPassword) {
    return 'Les mots de passe ne correspondent pas';
  }
  return null;
}
