import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final Map produit;

  const ProductDetailPage({Key? key, required this.produit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final genre = List<String>.from(produit['genre'] ?? []);
    final noteTete = List<String>.from(produit['note_tete'] ?? []);
    final noteCoeur = List<String>.from(produit['note_coeur'] ?? []);
    final noteFond = List<String>.from(produit['note_fond'] ?? []);
    final dupe = produit['dupe'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du produit'),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F5F0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              produit['nom'] ?? 'Nom inconnu',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E342E),
              ),
            ),
            const SizedBox(height: 12),
            Text('Code-barres : ${produit['code_barres'] ?? 'N/A'}'),
            const SizedBox(height: 12),
            Text('Quantité en stock : ${produit['quantite'] ?? 'N/A'}'),
            const Divider(height: 30),
            if (genre.isNotEmpty)
              Text('Genre : ${genre.join(', ')}', style: const TextStyle(fontSize: 16)),
            if (noteTete.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Notes de tête : ${noteTete.join(', ')}',
                    style: const TextStyle(fontSize: 16)),
              ),
            if (noteCoeur.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Notes de cœur : ${noteCoeur.join(', ')}',
                    style: const TextStyle(fontSize: 16)),
              ),
            if (noteFond.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Notes de fond : ${noteFond.join(', ')}',
                    style: const TextStyle(fontSize: 16)),
              ),
            if (dupe != null && dupe.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Dupe : $dupe', style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }
}
