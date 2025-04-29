import 'package:flutter_gemini/flutter_gemini.dart';

class Geminservice {
  static String _geminiKey = "AIzaSyCjar5DiTdrsbD5fJiC6Ab138euQCc1mtM";
  // ignore: prefer_typing_uninitialized_variables
  late Gemini gemini;

  static init() {
    Gemini.init(apiKey: _geminiKey);
  }

  Geminservice() {
    gemini = Gemini.instance;
  }
  Gemini getInstance() {
    return gemini;
  } // To here.
}
