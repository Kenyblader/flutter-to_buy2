String? listNameValidator(value) {
  if (value == null || value.isEmpty) {
    return 'Veuillez entrer un nom pour la liste';
  }
  return null;
}
