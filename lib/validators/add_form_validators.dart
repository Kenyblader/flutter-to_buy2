String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Le nom est requis';
  }
  if (value.length < 2) {
    return 'Le nom doit contenir au moins 2 caractères';
  }
  return null;
}

String? validatePrice(String? value) {
  if (value == null || value.isEmpty) {
    return 'Le prix est requis';
  }
  final price = double.tryParse(value);
  if (price == null || price <= 0) {
    return 'Le prix doit être un nombre positif';
  }
  return null;
}

String? validateQuantity(String? value) {
  if (value == null || value.isEmpty) {
    return 'La quantité est requise';
  }
  final quantity = double.tryParse(value);
  if (quantity == null || quantity <= 0) {
    return 'La quantité doit être un nombre positif';
  }
  return null;
}

String? validateDescription(String? value) {
  if (value == null || value.isEmpty) {
    return 'La description est requise';
  }
  if (value.length < 5) {
    return 'La description doit contenir au moins 5 caractères';
  }
  return null;
}