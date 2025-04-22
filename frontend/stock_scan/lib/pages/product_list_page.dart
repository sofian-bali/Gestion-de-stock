import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

const String apiBaseUrl = 'https://gestion-de-stock-q402.onrender.com';

class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<dynamic> produits = [];
  List<dynamic> produitsFiltres = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    chargerProduits();
  }

  Future<void> chargerProduits() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse('$apiBaseUrl/produits');
      debugPrint("📤 Tentative de chargement des produits");
      debugPrint("🌐 URL complète: $url");

      // Test de connexion au serveur avant la requête principale
      final testUrl = Uri.parse('$apiBaseUrl/');
      final testClient = http.Client();
      try {
        final testResponse = await testClient.get(testUrl).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Le serveur ne répond pas au test de connexion');
          },
        );
        if (testResponse.statusCode != 200) {
          throw Exception("Le serveur ne répond pas correctement (${testResponse.statusCode})");
        }
        debugPrint("✅ Test de connexion au serveur réussi");
      } finally {
        testClient.close();
      }

      // Configuration de la requête principale
      final client = http.Client();
      try {
        final request = http.Request('GET', url);
        request.headers.addAll({
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
          'User-Agent': 'StockScan/1.0',
        });

        debugPrint("📤 Envoi de la requête principale...");
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint("⏱️ Timeout lors de la requête principale");
            throw TimeoutException('La connexion a pris trop de temps');
          },
        );

        debugPrint("📥 Réponse reçue - Status: ${streamedResponse.statusCode}");
        final response = await http.Response.fromStream(streamedResponse);
        debugPrint("📦 Corps de la réponse: ${response.body}");

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          setState(() {
            produits = data;
            produitsFiltres = data;
            isLoading = false;
          });
          debugPrint("✅ ${data.length} produits chargés avec succès");
        } else {
          debugPrint("❌ Erreur serveur: ${response.statusCode} - ${response.body}");
          setState(() {
            errorMessage = 'Erreur lors du chargement des produits (${response.statusCode})';
            isLoading = false;
          });
        }
      } finally {
        client.close();
      }
    } on SocketException catch (e) {
      debugPrint("🔌 Erreur SocketException: $e");
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
    } on TimeoutException {
      debugPrint("⏱️ Timeout lors de la requête");
      setState(() {
        errorMessage = 'Délai d\'attente dépassé - Le serveur ne répond pas';
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Erreur inattendue: $e");
      setState(() {
        errorMessage = 'Erreur inattendue: $e';
        isLoading = false;
      });
    }
  }

  void filtrerProduits(String query) {
    setState(() {
      produitsFiltres = produits.where((produit) {
        final nom = produit['nom'].toString().toLowerCase();
        final code = produit['code_barres'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        return nom.contains(searchQuery) || code.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text(
          'Liste des produits',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                onChanged: filtrerProduits,
                decoration: InputDecoration(
                  labelText: 'Rechercher un produit',
                  labelStyle: const TextStyle(color: Color(0xFF4E342E)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4E342E)),
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
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8D6E63),
                  ),
                ),
              )
            else if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: produitsFiltres.length,
                itemBuilder: (context, index) {
                  final produit = produitsFiltres[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFFECEBE4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        produit['nom'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code-barres: ${produit['code_barres']}',
                            style: const TextStyle(color: Color(0xFF4E342E)),
                          ),
                          Text(
                            'Stock: ${produit['quantite']}',
                            style: const TextStyle(color: Color(0xFF4E342E)),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF4E342E)),
                            onPressed: () async {
                              final url = Uri.parse('$apiBaseUrl/produits/${produit['code_barres']}/retirer');
                              final response = await http.patch(
                                url,
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({'quantite': 1}),
                              );
                              if (response.statusCode == 200) {
                                await chargerProduits();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4E342E)),
                            onPressed: () async {
                              final url = Uri.parse('$apiBaseUrl/produits/${produit['code_barres']}/ajouter');
                              final response = await http.patch(
                                url,
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({'quantite': 1}),
                              );
                              if (response.statusCode == 200) {
                                await chargerProduits();
                              }
                            },
                          ),
                          const SizedBox(width: 8), // Ajout d'espace après les boutons
                        ],
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Page de détails à venir")),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
} 