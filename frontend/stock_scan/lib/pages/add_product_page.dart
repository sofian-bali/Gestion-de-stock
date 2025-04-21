import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

const String apiBaseUrl = 'https://gestion-de-stock-q402.onrender.com';

class AddProductPage extends StatefulWidget {
  final String codeBarres;

  const AddProductPage({super.key, required this.codeBarres});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _noteTeteController = TextEditingController();
  final TextEditingController _noteCoeurController = TextEditingController();
  final TextEditingController _noteFondController = TextEditingController();
  final TextEditingController _dupeController = TextEditingController();

  Future<void> ajouterProduit() async {
    final nom = _nomController.text.trim();
    final quantite = int.tryParse(_quantiteController.text.trim());
    final genre = _genreController.text.trim();
    final noteTete = _noteTeteController.text.trim();
    final noteCoeur = _noteCoeurController.text.trim();
    final noteFond = _noteFondController.text.trim();
    final dupe = _dupeController.text.trim();

    // Validation des champs obligatoires
    if (nom.isEmpty) {
      _showMessage('Le nom du produit est obligatoire');
      return;
    }
    if (quantite == null || quantite < 0) {
      _showMessage('La quantité doit être un nombre positif');
      return;
    }
    if (genre.isEmpty) {
      _showMessage('Le genre est obligatoire');
      return;
    }
    if (noteTete.isEmpty) {
      _showMessage('Les notes de tête sont obligatoires');
      return;
    }
    if (noteCoeur.isEmpty) {
      _showMessage('Les notes de cœur sont obligatoires');
      return;
    }
    if (noteFond.isEmpty) {
      _showMessage('Les notes de fond sont obligatoires');
      return;
    }

    final url = Uri.parse('$apiBaseUrl/produits');
    debugPrint("🔍 Tentative d'ajout du produit : $nom (${widget.codeBarres})");
    debugPrint("🌐 URL complète : $url");

    try {
      // Préparation des données avec une structure simplifiée
      final data = {
        'code_barres': widget.codeBarres,
        'nom': nom,
        'quantite': quantite,
        'genre': genre.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'note_tete': noteTete.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'note_coeur': noteCoeur.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'note_fond': noteFond.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'dupe': dupe.isEmpty ? null : dupe,
      };

      debugPrint("📤 Données à envoyer : ${jsonEncode(data)}");
      debugPrint("🌐 URL de la requête : $url");

      // Envoi de la requête avec des en-têtes simplifiés
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Le serveur ne répond pas dans le délai imparti');
        },
      );

      debugPrint("📥 Réponse reçue - Status: ${response.statusCode}");
      debugPrint("📦 Corps de la réponse: ${response.body}");
      debugPrint("🔍 En-têtes de la réponse: ${response.headers}");

      if (response.statusCode == 201) {
        _showMessage('Produit ajouté avec succès', success: true);
      } else if (response.statusCode == 500) {
        debugPrint("⚠️ Erreur serveur 500: ${response.body}");
        final errorMessage = response.body.isNotEmpty 
            ? response.body 
            : 'Erreur inconnue du serveur';
        _showMessage(
          'Erreur lors de l\'ajout du produit\n\n'
          'Détails : $errorMessage\n\n'
          'Veuillez vérifier que :\n'
          '• Le code-barres est unique\n'
          '• Les données sont au bon format\n'
          '• Le serveur est accessible\n'
          '• Les champs sont correctement remplis\n\n'
          'Données envoyées :\n${jsonEncode(data)}',
        );
      } else if (response.statusCode == 400) {
        debugPrint("⚠️ Erreur client 400: ${response.body}");
        _showMessage(
          'Données invalides\n\n'
          'Détails : ${response.body}\n\n'
          'Veuillez vérifier le format des données saisies.',
        );
      } else {
        debugPrint("⚠️ Erreur serveur: ${response.statusCode} - ${response.body}");
        _showMessage(
          'Erreur inattendue\n\n'
          'Code : ${response.statusCode}\n'
          'Message : ${response.body}\n\n'
          'Données envoyées :\n${jsonEncode(data)}',
        );
      }
    } on TimeoutException catch (e) {
      debugPrint("⏱️ Timeout: $e");
      _showMessage(
        'Délai d\'attente dépassé\n\n'
        'Le serveur ne répond pas. Veuillez réessayer plus tard.',
      );
    } on SocketException catch (e) {
      debugPrint("🔌 Erreur SocketException: $e");
      _showMessage(
        'Erreur de connexion\n\n'
        'Impossible de se connecter au serveur. Vérifiez que :\n'
        '• Votre connexion Internet est active\n'
        '• Le serveur est accessible\n'
        '• L\'URL de l\'API est correcte',
      );
    } catch (e) {
      debugPrint("❌ Erreur inattendue: $e");
      _showMessage(
        'Une erreur inattendue s\'est produite\n\n'
        'Détails : $e\n\n'
        'Veuillez réessayer ou contacter l\'administrateur.',
      );
    }
  }

  void _showMessage(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5F5F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4E342E),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF4E342E),
        ),
        title: Text(success ? 'Succès' : 'Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF8D6E63),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              if (success) {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text('Ajouter un produit'),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Code-barres : ${widget.codeBarres}', style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E))),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom du produit',
                    labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                    filled: true,
                    fillColor: const Color(0xFFECEBE4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Color(0xFF4E342E)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantiteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantité',
                    labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                    filled: true,
                    fillColor: const Color(0xFFECEBE4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Color(0xFF4E342E)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _genreController,
                  decoration: InputDecoration(
                    labelText: 'Genre (séparés par des virgules)',
                    labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                    filled: true,
                    fillColor: const Color(0xFFECEBE4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Color(0xFF4E342E)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteTeteController,
                  decoration: InputDecoration(
                    labelText: 'Notes de tête (séparées par des virgules)',
                    labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                    filled: true,
                    fillColor: const Color(0xFFECEBE4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Color(0xFF4E342E)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteCoeurController,
                  decoration: InputDecoration(
                    labelText: 'Notes de cœur (séparées par des virgules)',
                    labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                    filled: true,
                    fillColor: const Color(0xFFECEBE4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Color(0xFF4E342E)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteFondController,
                  decoration: InputDecoration(
                    labelText: 'Notes de fond (séparées par des virgules)',
                    labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                    filled: true,
                    fillColor: const Color(0xFFECEBE4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Color(0xFF4E342E)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dupeController,
                  decoration: InputDecoration(
                    labelText: 'Dupe (optionnel)',
                    labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                    filled: true,
                    fillColor: const Color(0xFFECEBE4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Color(0xFF4E342E)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: ajouterProduit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D6E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Ajouter le produit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
