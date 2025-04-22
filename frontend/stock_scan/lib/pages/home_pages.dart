import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'add_product_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'product_list_page.dart';
import 'history_page.dart';

const String apiBaseUrl = 'https://gestion-de-stock-q402.onrender.com';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nomProduit = '';
  String codeBarres = 'Aucun code scanné';
  String messageErreur = '';
  bool isServerReachable = false;
  String typeConnexion = 'Non détecté';
  TextEditingController quantiteController = TextEditingController(text: '1');
  int? quantiteProduit;
  List<Map<String, dynamic>> mouvements = [];
  List<dynamic> genre = [];
  List<dynamic> noteTete = [];
  List<dynamic> noteCoeur = [];
  List<dynamic> noteFond = [];
  String? dupe;

  Future<void> scannerCodeBarres() async {
    try {
      var result = await BarcodeScanner.scan();
      final code = result.rawContent.trim();
      debugPrint("Code scanné brut : $code");
      debugPrint("Type de code : ${result.type}");

      if (code.isNotEmpty && code.length >= 8) {
        setState(() {
          codeBarres = code;
        });
        debugPrint("Code validé et stocké : $code");
        chercherProduit(code);
      } else {
        debugPrint("Code invalide - Longueur : ${code.length}");
        _showDialog('Code invalide', 'Le code scanné est vide ou trop court.');
      }
    } catch (e) {
      debugPrint("Erreur lors du scan : $e");
      setState(() {
        codeBarres = 'Erreur : $e';
      });
    }
  }

  Future<void> chercherProduit(String code) async {
    if (code.isEmpty) {
      setState(() {
        messageErreur = "Code vide, annulation de l'appel API";
      });
      return;
    }

    final url = Uri.parse('$apiBaseUrl/produits/$code');
    debugPrint("🔍 Tentative de recherche du produit avec le code: $code");
    debugPrint("🌐 URL complète: $url");

    setState(() {
      messageErreur = "Tentative de connexion à la base de données...";
    });

    try {
      // Vérification de la connexion Internet
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception("Aucune connexion Internet disponible");
      }
      debugPrint("📡 Type de connexion: $connectivityResult");

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
          final produit = jsonDecode(response.body);
          debugPrint("✅ Produit trouvé: ${produit['nom']} (${produit['code_barres']})");
          setState(() {
            messageErreur = "Connexion à la base de données réussie ✓";
            nomProduit = produit['nom'] ?? '';
            quantiteProduit = produit['quantite'];
            genre = produit['genre'] ?? [];
            noteTete = produit['note_tete'] ?? [];
            noteCoeur = produit['note_coeur'] ?? [];
            noteFond = produit['note_fond'] ?? [];
            dupe = produit['dupe'];
          });
          await chargerMouvements(code);
        } else if (response.statusCode == 404) {
          debugPrint("❌ Produit non trouvé pour le code: $code");
          setState(() {
            messageErreur = "Produit non trouvé dans la base de données";
          });
          debugPrint("🔄 Appel de _showDialog avec isProduitIntrouvable=true et codeProduit=$code");
          _showDialog(
            'Produit introuvable',
            'Ce produit n\'existe pas encore dans la base de données.\n\nVoulez-vous l\'ajouter maintenant ?',
            isProduitIntrouvable: true,
            codeProduit: code,
          );
        } else if (response.statusCode == 500) {
          debugPrint("⚠️ Erreur serveur 500: ${response.body}");
          setState(() {
            messageErreur = "Produit non trouvé - Voulez-vous l'ajouter ?";
          });
          debugPrint("🔄 Appel de _showDialog avec isProduitIntrouvable=true et codeProduit=$code");
          _showDialog(
            'Produit introuvable',
            'Ce produit n\'existe pas encore dans la base de données.\n\n'
            'Voulez-vous l\'ajouter maintenant ?',
            isProduitIntrouvable: true,
            codeProduit: code,
          );
        } else {
          debugPrint("⚠️ Erreur serveur: ${response.statusCode} - ${response.body}");
          setState(() {
            messageErreur = "Erreur base de données (${response.statusCode})";
          });
          _showDialog(
            'Erreur serveur',
            'Impossible de récupérer les données. Détails :\n\n'
            '• Code d\'erreur : ${response.statusCode}\n'
            '• Message : ${response.body}\n\n'
            'Veuillez réessayer ou contacter l\'administrateur.',
          );
        }
      } finally {
        client.close();
      }
    } on SocketException catch (e) {
      debugPrint("🔌 Erreur SocketException: $e");
      setState(() {
        messageErreur = "Erreur de connexion à la base de données";
      });
      _showDialog(
        'Erreur de connexion',
        'Impossible de se connecter à la base de données. Vérifiez que :\n\n'
        '• Le serveur est en ligne\n'
        '• L\'URL de l\'API est correcte\n'
        '• La base de données est accessible\n'
        '• Votre connexion Internet est active\n'
        '• Votre WiFi n\'a pas de restrictions de sécurité',
      );
    } on TimeoutException {
      debugPrint("⏱️ Timeout lors de la requête");
      setState(() {
        messageErreur = "Délai d'attente dépassé - La base de données ne répond pas";
      });
      _showDialog(
        'Erreur de connexion',
        'La base de données ne répond pas. Vérifiez que :\n\n'
        '• Le serveur est en ligne\n'
        '• La base de données est accessible\n'
        '• Votre connexion Internet est stable\n'
        '• Votre WiFi n\'a pas de restrictions de sécurité',
      );
    } catch (e) {
      debugPrint("❌ Erreur inattendue: $e");
      setState(() {
        messageErreur = "Erreur inattendue: $e";
      });
      _showDialog('Erreur', 'Une erreur inattendue s\'est produite: $e');
    }
  }

  Future<void> chargerMouvements(String code) async {
    final url = Uri.parse('$apiBaseUrl/produits/$code/mouvements');
    debugPrint("Chargement des mouvements - URL: $url");
    try {
      final response = await http.get(url);
      debugPrint("Réponse mouvements - Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("Mouvements chargés: ${data.length}");
        setState(() {
          mouvements = List<Map<String, dynamic>>.from(data);
        });
      } else {
        debugPrint("Erreur lors du chargement des mouvements: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des mouvements: $e");
    }
  }

  Future<void> modifierStock(String type) async {
    final quantite = int.tryParse(quantiteController.text.trim()) ?? 1;
    final url = Uri.parse('$apiBaseUrl/produits/$codeBarres/$type');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'quantite': quantite}),
    );

    if (response.statusCode == 200) {
      final produit = jsonDecode(response.body);
      setState(() {
        quantiteProduit = produit['quantite'];
      });
      await chercherProduit(codeBarres);
    } else {
      _showDialog('Erreur', 'Impossible de modifier le stock');
    }
  }

  Future<void> verifierConnexion() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          typeConnexion = 'WiFi';
          break;
        case ConnectivityResult.mobile:
          typeConnexion = 'Données mobiles';
          break;
        case ConnectivityResult.ethernet:
          typeConnexion = 'Ethernet';
          break;
        case ConnectivityResult.vpn:
          typeConnexion = 'VPN';
          break;
        case ConnectivityResult.bluetooth:
          typeConnexion = 'Bluetooth';
          break;
        case ConnectivityResult.other:
          typeConnexion = 'Autre';
          break;
        case ConnectivityResult.none:
          typeConnexion = 'Aucune connexion';
          break;
      }
    });
  }

  Future<void> testerConnexionServeur() async {
    setState(() {
      messageErreur = "Test de connexion au serveur...";
      isServerReachable = false;
    });

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse('$apiBaseUrl/'));
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Connection': 'keep-alive',
        'User-Agent': 'StockScan/1.0',
      });

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Le serveur ne répond pas');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          messageErreur = "Serveur accessible ✓";
          isServerReachable = true;
        });
      } else {
        setState(() {
          messageErreur = "Serveur accessible mais erreur ${response.statusCode}";
          isServerReachable = false;
        });
      }
      client.close();
    } catch (e) {
      setState(() {
        messageErreur = "Erreur de connexion: $e";
        isServerReachable = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    verifierConnexion();
    testerConnexionServeur();
  }

  void _showDialog(String titre, String message, {bool isProduitIntrouvable = false, String? codeProduit}) {
    debugPrint("📣 Affichage de la popup : $titre | Introuvable : $isProduitIntrouvable | Code : $codeProduit");
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
        title: Text(titre),
        content: Text(message),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isProduitIntrouvable)
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF8D6E63),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () async {
                      debugPrint("🔄 Redirection vers la page d'ajout de produit avec le code: $codeProduit");
                      Navigator.of(context).pop();
                      try {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddProductPage(codeBarres: codeProduit ?? ''),
                          ),
                        );
                        debugPrint("✅ Retour de la page d'ajout : $result");
                        if (result == true) {
                          await Future.delayed(const Duration(seconds: 2));
                          await chercherProduit(codeProduit ?? '');
                        }
                      } catch (e) {
                        debugPrint("❌ Erreur lors de l'ajout du produit: $e");
                        _showDialog(
                          'Erreur',
                          'Une erreur est survenue lors de l\'ajout du produit.\n\n'
                          'Détails : $e\n\n'
                          'Veuillez réessayer ou contacter l\'administrateur.',
                        );
                      }
                    },
                    child: const Text('Ajouter ce produit'),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF8D6E63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        toolbarHeight: 100,
        title: Row(
          children: [
            Image.asset(
              'assets/fragrancebali-high-resolution-logo-transparent.png',
              height: 60,
            ),
            const SizedBox(width: 12),
            const Text(
              'Gestion de stock',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Zone de débogage
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isServerReachable ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isServerReachable ? Colors.green : Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isServerReachable ? Icons.check_circle : Icons.error,
                          color: isServerReachable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isServerReachable ? 'Serveur accessible' : 'Serveur inaccessible',
                          style: TextStyle(
                            color: isServerReachable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Type de connexion : $typeConnexion',
                        style: const TextStyle(color: Colors.black)),
                    Text('Code scanné : $codeBarres',
                        style: const TextStyle(color: Colors.black)),
                    Text('URL appelée : $apiBaseUrl/produits/$codeBarres',
                        style: const TextStyle(color: Colors.black, fontSize: 12)),
                    if (messageErreur.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('État : $messageErreur',
                            style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: testerConnexionServeur,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8D6E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Tester la connexion'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Configuration réseau'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Type de connexion : $typeConnexion'),
                                    const SizedBox(height: 16),
                                    const Text('Conseils :'),
                                    const SizedBox(height: 8),
                                    const Text('• Vérifiez que votre WiFi est activé'),
                                    const Text('• Assurez-vous d\'être connecté au bon réseau'),
                                    const Text('• Essayez de redémarrer votre routeur'),
                                    const Text('• Vérifiez les paramètres de proxy'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8D6E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Aide réseau'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (nomProduit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFECEBE4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🧴 Parfum : $nomProduit',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
                        if (quantiteProduit != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('📦 Stock : $quantiteProduit',
                                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E))),
                          ),
                        if (genre.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('🧑‍🤝‍🧑 Genre : ${genre.join(', ')}',
                                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E))),
                          ),
                        if (noteTete.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text('🍋 Notes de tête : ${noteTete.join(', ')}',
                                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E))),
                          ),
                        if (noteCoeur.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('🌸 Notes de cœur : ${noteCoeur.join(', ')}',
                                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E))),
                          ),
                        if (noteFond.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('🌿 Notes de fond : ${noteFond.join(', ')}',
                                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E))),
                          ),
                        if (dupe != null && dupe!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text('🧪 Dupe : $dupe',
                                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Color(0xFF4E342E))),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: TextField(
                  controller: quantiteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantité à modifier',
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
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: scannerCodeBarres,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBCAAA4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Scanner un produit'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddProductPage(codeBarres: ''),
                          ),
                        );
                        if (result == true) {
                          await Future.delayed(const Duration(seconds: 2));
                          setState(() {
                            codeBarres = 'Aucun code scanné';
                            nomProduit = '';
                            quantiteProduit = null;
                            genre = [];
                            noteTete = [];
                            noteCoeur = [];
                            noteFond = [];
                            dupe = null;
                            mouvements = [];
                          });
                        }
                      } catch (e) {
                        debugPrint("❌ Erreur lors de l'ajout du produit: $e");
                        _showDialog(
                          'Erreur',
                          'Une erreur est survenue lors de l\'ajout du produit.\n\n'
                          'Détails : $e\n\n'
                          'Veuillez réessayer ou contacter l\'administrateur.',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D6E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('➕ Ajouter un produit'),
                  ),
                  if (messageErreur.contains("Produit non trouvé"))
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddProductPage(codeBarres: codeBarres),
                              ),
                            );
                            if (result == true) {
                              await Future.delayed(const Duration(seconds: 2));
                              await chercherProduit(codeBarres);
                            }
                          } catch (e) {
                            debugPrint("❌ Erreur lors de l'ajout du produit: $e");
                            _showDialog(
                              'Erreur',
                              'Une erreur est survenue lors de l\'ajout du produit.\n\n'
                              'Détails : $e\n\n'
                              'Veuillez réessayer ou contacter l\'administrateur.',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D6E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Ajouter un nouveau produit'),
                      ),
                    ),
                ],
              ),
              if (codeBarres != 'Aucun code scanné')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => modifierStock('ajouter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBCAAA4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('➕ Ajouter au stock'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => modifierStock('retirer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBCAAA4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('➖ Retirer du stock'),
                    ),
                  ],
                  
                ),
                const SizedBox(height: 40),

              if (codeBarres != 'Aucun code scanné')
                const SizedBox(height: 30),
              if (mouvements.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Historique des mouvements',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: mouvements.length,
                          itemBuilder: (context, index) {
                            final m = mouvements[index];
                            final date = DateTime.parse(m['date_mouvement']).toLocal();
                            final dateStr = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                            return ListTile(
                              title: Text("${m['type']} - ${m['quantite']}",
                                  style: const TextStyle(color: Color(0xFF4E342E))),
                              subtitle: Text(dateStr,
                                  style: const TextStyle(color: Color(0xFF8D6E63))),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              // Always add spacing before the global history button/navbar
              const SizedBox(height: 40),

              // Button for 'Voir l'historique global'
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HistoryPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("Voir l'historique global"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}