import 'dart:convert';

import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:to_buy/models/buy_item.dart';

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

  Future<String> GetMEnuByBudget(String budget) async {
    Future<String> response = Future.value('');
    if (budget.isEmpty) {
      return Future.error('Budget vide');
    }
    return await gemini
        .prompt(
          parts: [
            Part.text('''
      Générez un JSON valide représentant un plat CAMEROUNAIS  avec une liste d'ingrédients pour la préparation d'un plat caerounais exple(Ndole,poulet Dg,riz avec sauce d'arrachide,poisson braise,poulet braise,Taro,eru ......et plein d'autre a toi de choisir en fonction de la saison)  AVEC UN BUDGET DE $budget FCFA. L'objet doit avoir :
      - name : le nom du plat (chaîne).
      - ingredients : une liste d' ingrédients complee neccessaire a la realisation du plat, chaque ingrédient ayant :
        - name : nom de l'ingrédient (chaîne).
        - description : description de l'utilisation (chaîne).
        - price : prix en XAF (nombre décimal).
        - quantity : quantité nécessaire (entier).

      NB: la somme des prix des ingrédients * la quantite doit être inférieure a $budget.

      Exemple de réponse :
      {
        "name": "Nom du menu",
        "ingredients": [
          
          {
            "name": "Oignons",
            "description": "Pour la marinade et la sauce",
            "price": 500.00,
            "quantity": 2
          }
          {
            "name": "huile(litre)",
            "description": "Pour la friture",
            "price": 1500.00,
            "quantity": 1
          },
         
        ]
      }

      Retournez uniquement le JSON, sans texte, commentaires, ou backticks. Assurez-vous que le JSON est complet et bien formé.
      '''),
          ],
        )
        .then((response) {
          if (response == null) {
            return Future.error('Erreur de réponse null');
          } else {
            return Future.value(response.output);
          }
        })
        .onError((error, stackTrace) {
          print('Erreur: $error');
          return Future.error('Erreur lors de la récupération des données');
        });
  }

  void getItemsWithOrder(List<BuyItem> items, void Function(String) callback) {
    gemini
        .promptStream(
          parts: [
            Part.text('''
      Je suis en train de contruire un liste de mes achats et je souhaite que m'aide a la remplir
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
            "price": 500.00,
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
        .listen((response) {
          if (response != null) {
            callback(response.output as String);
          }
        });
  }
}
