import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
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
        cleanedResponse = cleanedResponse
            .replaceAll('```json', '')
            .replaceAll('```', '');
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
        .prompt(
          parts: [
            Part.text('''
      Je suis en train de contruire un liste de mes achats et je souhaite que m'aide a la remplir en me proposant 5 element que je pourrais y ajouter
      voici son etat actuel
      ${jsonEncode(items.map((element) => {"name": element.name, "price": element.price, "quantity": element.quantity}).toList())}
      '''),
            Part.text('''  
      Générez un JSON valide représentant les éléments que je pourais ajouter a ma liste suivants le modele suivant : 
      - items : une liste d'achats, chaque achat ayant :
        - name : nom de l'élément (chaîne).
        - price : prix en XAF (nombre décimal).
        - quantity : quantité nécessaire (entier).
        

      Exemple de réponse :
      {
        "items": [
          {
            "name": "Oignons",
            "price": 100.00,
            "quantity": 2,
          },
          {
            "name": "huile(litre)",
            "price": 1500.00,
            "quantity": 1,
          }
        ]
      }

      Retournez uniquement le JSON, sans texte, commentaires, ou backticks. Assurez-vous que le JSON est complet et bien formé.
      '''),
          ],
        )
        .then((response) {
          if (response != null) {
            callback(response.output as String);
          }
        });
  }

  Future<String> transcriptTextToList(String audio) async {
    print("Début de la transcription");

    try {
      final responce = await gemini.prompt(
        parts: [
          Part.text('''
  voici des paroles d'une personne desirant produire une liste de ses achats pour cela j'ai recuillit cequ'elle a dit que voici "$audio"

'''),
          Part.text('''
Générez un JSON valide représentant les éléments d'une liste tel qu'énoncés dans les paroles si dessus en essayant d'eviter les doublons 
et de renseigner que les champs qui on ete enoncer sinon tu laisse la valeur par defaut correspondant au type de donne.
Le résultat doit respecter la structure suivante:
- name: nom de l'élément (chaîne)
- price: prix unitaire (si dans l'audio il a été mentionné le prix total, fais la division si possible) en XAF (nombre décimal)
- quantity: quantité nécessaire (si dans l'audio il n'a pas été mentionné la quantité, marque 1) (entier)

Exemple de réponse:
{
  "items": [
    {
      "name": "Oignons",
      "price": 100.00,
      "quantity": 2
    },
    {
      "name": "huile(litre)",
      "price": 1500.00,
      "quantity": 1
    }
  ]
}

Retournez uniquement le JSON, sans texte, commentaires, ou backticks. Assurez-vous que le JSON est complet et bien formé.
'''),
        ],
      );
      print("Fin de la transcription");
      if (responce == null ||
          responce.output == null ||
          responce.output!.isEmpty) {
        return Future.error('La réponse Gemini est vide');
      }

      // Nettoyer la réponse pour s'assurer que c'est du JSON valide
      String jsonStr = responce.output!.trim();

      // Supprimer les backticks de code si présents
      if (jsonStr.startsWith("```json") && jsonStr.endsWith("```")) {
        jsonStr = jsonStr.substring(7, jsonStr.length - 3).trim();
      } else if (jsonStr.startsWith("```") && jsonStr.endsWith("```")) {
        jsonStr = jsonStr.substring(3, jsonStr.length - 3).trim();
      }

      // Vérifier que c'est du JSON valide
      try {
        json.decode(jsonStr);
        return jsonStr;
      } catch (e) {
        debugPrint("JSON invalide reçu: $jsonStr");
        return Future.error('La réponse n\'est pas au format JSON valide: $e');
      }
    } catch (e, stackTrace) {
      debugPrint("Erreur lors de la transcription: $e");
      debugPrint(stackTrace.toString());
      return Future.error('Erreur lors de la transcription: $e');
    }
  }
}
