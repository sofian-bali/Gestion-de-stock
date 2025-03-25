import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_product_page.dart';

class HomePage extends StatefulWidget {
  // ignore: use_super_parameters
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nomProduit = '';
  String codeBarres = 'Aucun code scanné';
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
      final code = result.rawContent;
 
      if (code.isNotEmpty) {
        setState(() {
          codeBarres = code;
        });
        debugPrint("Code scanné : $code");
        chercherProduit(code);
      }
    } catch (e) {
      setState(() {
        codeBarres = 'Erreur : $e';
      });
    }
  }

  Future<void> chercherProduit(String code) async {
    final url = Uri.parse('http://192.168.1.154:3000/produits/$code');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final produit = jsonDecode(response.body);
        setState(() {
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
        _showDialog('Produit introuvable', 'Ce produit n\'existe pas encore.');
      } else {
        _showDialog('Erreur', 'Impossible de récupérer les données');
      }
    } catch (e) {
      _showDialog('Erreur', 'Exception : $e');
    }
  }

  Future<void> chargerMouvements(String code) async {
    final url = Uri.parse('http://192.168.1.154:3000/produits/$code/mouvements');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          mouvements = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      // silence l'erreur pour éviter les pop-ups
    }
  }

  Future<void> modifierStock(String type) async {
    final quantite = int.tryParse(quantiteController.text.trim()) ?? 1;
    final url = Uri.parse('http://192.168.1.154:3000/produits/$codeBarres/$type');
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

  void _showDialog(String titre, String message) {
    final isProduitIntrouvable = titre == 'Produit introuvable';

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
        actions: [
          if (isProduitIntrouvable)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF8D6E63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // fermer la boîte de dialogue
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProductPage(codeBarres: codeBarres),
                  ),
                );
                if (result == true) {
                  chercherProduit(codeBarres);
                }
              },
              child: const Text('Ajouter ce produit'),
            ),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [             
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8D6E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Voir l\'historique global'),
            ),
          ],
        ),
      ),
    );
  }
}