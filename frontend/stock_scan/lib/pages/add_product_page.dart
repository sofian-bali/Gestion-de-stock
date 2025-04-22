import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

const String apiBaseUrl = 'https://gestion-de-stock-q402.onrender.com';

class AddProductPage extends StatefulWidget {
  final String? codeBarres;
  
  const AddProductPage({Key? key, this.codeBarres}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _codeBarresController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _genreController = TextEditingController();
  final _noteTeteController = TextEditingController();
  final _noteCoeurController = TextEditingController();
  final _noteFondController = TextEditingController();
  final _dupeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.codeBarres != null) {
      _codeBarresController.text = widget.codeBarres!;
    }
  }

  Future<void> _ajouterProduit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/produits'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': _nomController.text,
          'code_barres': _codeBarresController.text.isEmpty ? null : _codeBarresController.text,
          'quantite': int.parse(_quantiteController.text),
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produit ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de l\'ajout du produit: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _codeBarresController.dispose();
    _quantiteController.dispose();
    _genreController.dispose();
    _noteTeteController.dispose();
    _noteCoeurController.dispose();
    _noteFondController.dispose();
    _dupeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text(
          widget.codeBarres != null ? 'Ajouter un produit' : 'Nouveau produit',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.codeBarres != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Code-barres : ${widget.codeBarres}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                ),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom du produit',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFECEBE4),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              if (widget.codeBarres == null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeBarresController,
                  decoration: InputDecoration(
                    labelText: 'Code-barres (optionnel)',
                    labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFECEBE4),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantiteController,
                decoration: InputDecoration(
                  labelText: 'Quantité initiale',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFECEBE4),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
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
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _ajouterProduit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Ajouter le produit',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
