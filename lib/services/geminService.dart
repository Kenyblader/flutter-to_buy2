import 'dart:convert';
import 'dart:math';

import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:to_buy/models/buy_item.dart';

class Geminservice {
  static const String _geminiKey = "AIzaSyCjar5DiTdrsbD5fJiC6Ab138euQCc1mtM";
  late Gemini gemini;

  static void init() {
    Gemini.init(apiKey: _geminiKey);
  }

  Geminservice() {
    gemini = Gemini.instance;
  }

  Gemini getInstance() {
    return gemini;
  }

  Future<String> GetMEnuByBudget(String budget) async {
    if (budget.isEmpty) {
      return Future.error('Budget vide');
    }

    // Générer un nombre aléatoire pour encourager la variabilité
    final random = Random().nextInt(1000);

    try {
      final response = await gemini.prompt(
        parts: [
          Part.text('''
Générez un JSON valide représentant une liste d'ingrédients pour la préparation d'un plat camerounais authentique adapté au budget exact de $budget FCFA (variante #$random).

Le plat doit être choisi parmi les plats camerounais traditionnels, en tenant compte du budget pour déterminer sa complexité :
- Pour un petit budget (<5000 FCFA), privilégiez des plats simples avec des ingrédients abordables.
- Pour un budget moyen (5000-10000 FCFA), optez pour des plats intermédiaires avec plus d'ingrédients.
- Pour un budget élevé (>10000 FCFA), choisissez des plats élaborés avec des ingrédients de qualité ou en plus grande quantité.

L'objet JSON doit avoir :
- name : le nom du plat (chaîne, unique à chaque requête, reflétant le budget).
- ingredients : une liste d'ingrédients nécessaires à la réalisation du plat, chaque ingrédient ayant :
  - name : nom de l'ingrédient (chaîne).
  - description : description de l'utilisation (chaîne).
  - price : prix en XAF (nombre décimal, basé sur les prix actuels du marché camerounais).
  - quantity : quantité nécessaire (nombre décimal).

NB : La somme des prix des ingrédients × la quantité doit être aussi proche que possible de $budget FCFA, sans le dépasser. Les prix doivent refléter les coûts réels au Cameroun (par exemple, oignons ~500 XAF/kg, huile ~1500 XAF/litre). Assurez-vous que le plat et les ingrédients varient à chaque requête en fonction du budget.

Exemple de réponse :
{
  "name": "Plat Camerounais",
  "ingredients": [
    {
      "name": "Oignons",
      "description": "Pour la marinade et la sauce",
      "price": 500.00,
      "quantity": 2
    },
    {
      "name": "Huile",
      "description": "Pour la friture",
      "price": 1500.00,
      "quantity": 1
    }
  ]
}

Retournez uniquement le JSON, sans texte, commentaires, ou backticks. Assurez-vous que le JSON est complet et bien formé.
'''),
        ],
        generationConfig: GenerationConfig(
          temperature: 0.9, // Augmenté pour plus de variabilité
          topK: 40,
          topP: 0.95,
        ),
      );

      if (response == null || response.output == null) {
        print('Erreur: Réponse Gemini null pour budget: $budget');
        return Future.error('Erreur de réponse null');
      }

      print('Réponse Gemini brute pour budget $budget: ${response.output}');
      String cleanedResponse = response.output!.trim();

      // Nettoyer les backticks ou marqueurs JSON
      if (cleanedResponse.contains('```json')) {
        cleanedResponse = cleanedResponse.replaceAll('```json', '').replaceAll('```', '');
      } else if (cleanedResponse.contains('```')) {
        cleanedResponse = cleanedResponse.replaceAll('```', '');
      }

      print('Réponse Gemini nettoyée pour budget $budget: $cleanedResponse');
      return cleanedResponse;
    } catch (error) {
      print('Erreur Gemini pour budget $budget: $error');
      return Future.error('Erreur lors de la récupération des données: $error');
    }
  }

  void getItemsWithOrder(List<BuyItem> items, void Function(String) callback) {
    gemini
        .promptStream(
      parts: [
        Part.text('''
Je suis en train de construire une liste de mes achats et je souhaite que vous m'aidiez à la remplir.
Voici son état actuel :
${jsonEncode(items.map((element) => {"name": element.name, "price": element.price, "quantity": element.quantity}).toList())}
'''),
        Part.text('''
Générez un JSON valide représentant les éléments que je pourrais ajouter à ma liste selon le modèle suivant :
- items : une liste d'achats, chaque achat ayant :
  - name : nom de l'élément (chaîne).
  - price : prix en XAF (nombre décimal).
  - quantity : quantité nécessaire (entier).

Exemple de réponse :
{
  "items": [
    {
      "name": "Oignons",
      "price": 500.00,
      "quantity": 2
    },
    {
      "name": "Huile (litre)",
      "price": 1500.00,
      "quantity": 1
    }
  ]
}

Retournez uniquement le JSON, sans texte, commentaires, ou backticks. Assurez-vous que le JSON est complet et bien formé.
'''),
      ],
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
      ),
    )
        .listen((response) {
      if (response != null && response.output != null) {
        callback(response.output as String);
      }
    });
  }
}