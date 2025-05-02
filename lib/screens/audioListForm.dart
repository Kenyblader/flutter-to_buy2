import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:to_buy/components/record_widget.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/screens/item_form_screen.dart';
import 'package:to_buy/screens/propse_menu.dart';
import 'package:to_buy/services/firestore_service.dart';
import 'package:to_buy/services/geminService.dart';

class Audiolistform extends StatefulWidget {
  const Audiolistform({super.key});

  @override
  State<StatefulWidget> createState() => _AudiolistformState();
}

class _AudiolistformState extends State<Audiolistform> {
  final SpeechToText _speechToText = SpeechToText();
  bool isPermit = false;
  bool isListening = false;
  String recognizedText = '';
  List<ElementAffich> _items = [];
  List<BuyItem> _saveditems = [];

  @override
  void initState() {
    super.initState(); // Super doit être appelé en premier
    _initializeSpeech(); // Appel de la méthode d'initialisation sans await
  }

  // Méthode séparée pour l'initialisation asynchrone
  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) => print("Erreur d'initialisation: $error"),
        onStatus: (status) => print("Status: $status"),
      );

      if (mounted) {
        // Vérifier si le widget est toujours monté
        setState(() {
          isPermit = available;
        });
      }

      if (!available && mounted) {
        // Demander la permission explicitement si nécessaire
        isPermit = await _speechToText.hasPermission;
        setState(() {});
      }
    } catch (e) {
      print("Erreur lors de l'initialisation de speech_to_text: $e");
      if (mounted) {
        setState(() {
          isPermit = false;
        });
      }
    }
  }

  List<ElementAffich>? parseCustomJsonString(String jsonString) {
    try {
      var cleanedJson = jsonString.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7, cleanedJson.length - 3).trim();
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3, cleanedJson.length - 3).trim();
      }

      print('Réponse JSON brute : $cleanedJson');

      final jsonData = jsonDecode(cleanedJson) as Map<String, dynamic>;
      final List<ElementAffich> dish =
          jsonData['items']
              .map<ElementAffich>((data) => ElementAffich.fromJson(data))
              .toList();
      return dish;
    } catch (error, stackTrace) {
      print('Erreur Gemini : $error');
      print('Trace de la pile : $stackTrace');
      return null;
    }
  }

  Future<void> _startRecord() async {
    try {
      // Vérifier si la reconnaissance est disponible
      if (!isPermit) {
        print("La reconnaissance vocale n'est pas disponible");
        return;
      }

      // Réinitialiser le texte reconnu
      setState(() {
        recognizedText = '';
        isListening = true;
      });

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30), // Limiter à 30 secondes
        pauseFor: const Duration(
          seconds: 5,
        ), // Pause après 3 secondes de silence
        partialResults: true,
        localeId: "fr_FR", // Définir la langue si nécessaire (français ici)
      );
    } catch (e) {
      print("Erreur lors du démarrage de l'enregistrement: $e");
      if (mounted) {
        setState(() {
          isListening = false;
        });

        // Afficher un message d'erreur à l'utilisateur
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur d'enregistrement: $e")));
      }
    }
  }

  // Méthode pour traiter les résultats intermédiaires
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      recognizedText = result.recognizedWords;
    });

    // On ne traite avec Gemini que si le résultat est final
    // pour éviter des appels API inutiles
  }

  // Méthode pour traiter les résultats finaux avec Gemini
  Future<void> _processWithGemini(String result) async {
    if (result.isEmpty) {
      print("Aucun texte reconnu à transcrire");
      return;
    }

    try {
      String words = result;
      print("Texte reconnu à transcrire: $words");

      // Traitement avec Gemini
      String iaList = await Geminservice().transcriptTextToList(words);
      print("Résultat de Gemini: $iaList");

      // Ici vous pouvez traiter le résultat (afficher un dialogue, remplir un formulaire, etc.)
      if (mounted) {
        // Exemple: afficher le résultat dans un dialogue
        final iaElemnt = parseCustomJsonString(iaList);
        if (iaElemnt == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "erreur de transcription de texte en liste, veuiller reesayer plus tard",
              ),
            ),
          );
          return;
        }
        setState(() {
          _items.addAll(iaElemnt);
        });
      }
    } catch (e) {
      print("Erreur lors du traitement avec Gemini: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de traitement: $e")));
      }
    }
  }

  // Afficher le résultat dans un dialogue
  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Résultat de la transcription'),
            content: SingleChildScrollView(child: Text(result)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Future<void> _stopRecord() async {
    try {
      await _speechToText.stop();

      if (mounted) {
        setState(() {
          isListening = false;
        });

        // Si nous avons du texte reconnu et que l'arrêt est manuel (pas automatique)
        // nous pouvons traiter avec Gemini ici
        if (recognizedText.isNotEmpty) {
          // final result = SpeechRecognitionResult([recognizedText], true);
          _processWithGemini(recognizedText);
        }
      }
    } catch (e) {
      print("Erreur lors de l'arrêt de l'enregistrement: $e");
    }
  }

  void _onDismissed(int index, DismissDirection direction) {
    setState(() {
      if (direction == DismissDirection.startToEnd) {
        _items[index].isSelected = true;
      } else if (direction == DismissDirection.endToStart) {
        _items[index].isSelected = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio List Form')),
      body: Column(
        children: [
          // Afficher le statut actuel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              isListening
                  ? 'Écoute en cours...'
                  : (isPermit
                      ? 'Appuyez sur le bouton pour parler'
                      : 'Permission refusée'),
              style: TextStyle(fontSize: 16),
            ),
          ),

          // Afficher le texte reconnu
          if (recognizedText.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Text(
                        recognizedText,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bouton d'enregistrement
          Expanded(
            child: Center(
              child:
                  isPermit
                      ? RecordButton(
                        onRecordStart: _startRecord,
                        onRecordStop: _stopRecord,
                        isRecording: isListening,
                      )
                      : ElevatedButton(
                        onPressed: _initializeSpeech,
                        child: Text('Demander la permission'),
                      ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Dismissible(
                  key: Key(item.name),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    _onDismissed(index, direction);
                    return false;
                  },
                  child: Card(
                    elevation: 3,
                    color: item.isSelected ? Colors.green[50] : Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.desctiption,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${formatDouble(item.price)} XAF x ${formatDouble(item.quantity)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      leading: const Icon(
                        Icons.shopping_cart,
                        color: Colors.blueAccent,
                      ),
                      trailing: Text(
                        '${formatDouble(item.quantity * item.price)} XAF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final service = FirestoreService();
          for (var item in _items) {
            if (item.isSelected) {
              _saveditems.add(
                BuyItem(
                  name: item.name,
                  price: item.price,
                  quantity: item.quantity,
                ),
              );
            }
          }
          if (_saveditems.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aucun article sélectionné')),
            );
            return;
          }

          var generatedList = BuyList(
            name: "generated list ${DateTime.now().millisecond}",
            description: "preparation de audio ${DateTime.now().millisecond}",
            items: _saveditems,
          );
          service
              .addBuyList(generatedList, _saveditems)
              .then((value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Liste créée avec succès')),
                );
                Navigator.pop(context, generatedList);
              })
              .catchError((error) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur : $error')));
              });
        },
        backgroundColor: Colors.blueAccent,
        elevation: 6,
        child: const Text('Save', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }
}
