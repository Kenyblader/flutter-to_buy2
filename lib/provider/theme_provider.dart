import 'package:flutter/material.dart';

class Themeprovider extends ChangeNotifier {
  bool isDark = false;
  ThemeData get themeData {
    return isDark ? ThemeData.dark() : ThemeData.light();
  }

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }
}
