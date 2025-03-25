import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

    if (nom.isEmpty || quantite == null || quantite < 0) {
      _showMessage('Champs invalides');
      return;
    }

    final url = Uri.parse('https://gestion-de-stock-q402.onrender.com/produits');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code_barres': widget.codeBarres,
          'nom': nom,
          'quantite': quantite,
          'genre': _genreController.text.trim().split(','),
          'note_tete': _noteTeteController.text.trim().split(','),
          'note_coeur': _noteCoeurController.text.trim().split(','),
          'note_fond': _noteFondController.text.trim().split(','),
          'dupe': _dupeController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _showMessage('Produit ajouté avec succès', success: true);
      } else {
        _showMessage('Erreur à l\'ajout : ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Erreur : $e');
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Code-barres : ${widget.codeBarres}', style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E))),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom du produit',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  filled: true,
                  fillColor: Color(0xFFECEBE4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.label, color: Color(0xFF4E342E)),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantiteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  filled: true,
                  fillColor: Color(0xFFECEBE4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.confirmation_number, color: Color(0xFF4E342E)),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genreController,
                decoration: InputDecoration(
                  labelText: 'Genre (séparé par virgule)',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  filled: true,
                  fillColor: Color(0xFFECEBE4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.male, color: Color(0xFF4E342E)),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteTeteController,
                decoration: InputDecoration(
                  labelText: 'Notes de tête (séparées par virgule)',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  filled: true,
                  fillColor: Color(0xFFECEBE4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.water_drop, color: Color(0xFF4E342E)),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCoeurController,
                decoration: InputDecoration(
                  labelText: 'Notes de cœur (séparées par virgule)',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  filled: true,
                  fillColor: Color(0xFFECEBE4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.favorite, color: Color(0xFF4E342E)),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteFondController,
                decoration: InputDecoration(
                  labelText: 'Notes de fond (séparées par virgule)',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  filled: true,
                  fillColor: Color(0xFFECEBE4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.spa, color: Color(0xFF4E342E)),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dupeController,
                decoration: InputDecoration(
                  labelText: 'Dupe (facultatif)',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  filled: true,
                  fillColor: Color(0xFFECEBE4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.copy, color: Color(0xFF4E342E)),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: ajouterProduit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBCAAA4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Ajouter le produit'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
