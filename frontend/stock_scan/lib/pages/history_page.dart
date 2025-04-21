import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiBaseUrl = 'https://gestion-de-stock-q402.onrender.com';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> mouvements = [];

  @override
  void initState() {
    super.initState();
    fetchHistorique();
  }

  Future<void> fetchHistorique() async {
    final url = Uri.parse('$apiBaseUrl/produits-mouvements');

    try {
      final response = await http.get(url);
      print("Réponse API: ${response.body}"); // Ajouté
      if (response.statusCode == 200) {
        setState(() {
          mouvements = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'historique: $e"); // Ajouté
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text('Historique global'),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
      ),
      body: mouvements.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: mouvements.length,
              itemBuilder: (context, index) {
                final m = mouvements[index];
                final produit = m['produit'];
                final date = DateTime.parse(m['date_mouvement']).toLocal();
                final dateStr = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                String dateModifStr = '';
                if (produit != null && produit['date_modification'] != null) {
                  final modifDate = DateTime.parse(produit['date_modification']).toLocal();
                  dateModifStr = "Dernière modif : ${modifDate.day}/${modifDate.month}/${modifDate.year} ${modifDate.hour}:${modifDate.minute.toString().padLeft(2, '0')}";
                }

                return ListTile(
                  title: Text(
                    "${produit['nom']} — ${m['type']} (${m['quantite']})",
                    style: const TextStyle(color: Color(0xFF4E342E)),
                  ),
                  subtitle: Text(
                    "$dateStr\n$dateModifStr",
                    style: const TextStyle(color: Color(0xFF8D6E63)),
                  ),
                );
              },
            ),
    );
  }
}
