const express = require("express");
const cors = require("cors");
require("dotenv").config();
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();
const app = express();

app.use(cors());
app.use(express.json());

// Test route
app.get("/", (req, res) => {
  res.send("API stock OK !");
});

// Ajouter un produit
app.post("/produits", async (req, res) => {
  const { code_barres, nom, quantite, genre, note_tete, note_coeur, note_fond } = req.body;

  if (!code_barres || !nom || quantite === undefined) {
    return res.status(400).json({ error: "Champs manquants" });
  }

  try {
    const produit = await prisma.produit.create({
      data: {
        code_barres,
        nom,
        quantite,
        genre,
        note_tete,
        note_coeur,
        note_fond,
      },
    });

    res.status(201).json(produit);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur lors de la création du produit" });
  }
});

// ✅ Lancement du serveur
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Serveur lancé sur le port ${PORT}`);
});

// Obtenir un produit par code-barres
app.get("/produits/:code_barres", async (req, res) => {
  const { code_barres } = req.params;

  try {
    const produit = await prisma.produit.findUnique({
      where: { code_barres },
    });

    if (!produit) {
      return res.status(404).json({ error: "Produit non trouvé" });
    }

    res.json(produit);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur lors de la récupération du produit" });
  }
});

// Retirer une quantité du stock d'un produit
app.patch("/produits/:code_barres/retirer", async (req, res) => {
  const { code_barres } = req.params;
  const { quantite } = req.body;

  if (!quantite || quantite <= 0) {
    return res.status(400).json({ error: "Quantité invalide" });
  }

  try {
    const produit = await prisma.produit.findUnique({
      where: { code_barres },
    });

    if (!produit) {
      return res.status(404).json({ error: "Produit non trouvé" });
    }

    if (produit.quantite < quantite) {
      return res.status(400).json({ error: "Stock insuffisant" });
    }

    const produitMisAJour = await prisma.produit.update({
      where: { code_barres },
      data: {
        quantite: produit.quantite - quantite,
        date_modification: new Date(),
      },
    });

    await prisma.mouvementStock.create({
      data: {
        type: "retirer",
        quantite,
        produitId: produit.id,
      },
    });

    res.json(produitMisAJour);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur lors de la mise à jour du stock" });
  }
});

// Ajouter une quantité au stock d'un produit
app.patch("/produits/:code_barres/ajouter", async (req, res) => {
  const { code_barres } = req.params;
  const { quantite } = req.body;

  if (!quantite || quantite <= 0) {
    return res.status(400).json({ error: "Quantité invalide" });
  }

  try {
    const produit = await prisma.produit.findUnique({
      where: { code_barres },
    });

    if (!produit) {
      return res.status(404).json({ error: "Produit non trouvé" });
    }

    const produitMisAJour = await prisma.produit.update({
      where: { code_barres },
      data: {
        quantite: produit.quantite + quantite,
        date_modification: new Date(),
      },
    });

    await prisma.mouvementStock.create({
      data: {
        type: "ajouter",
        quantite,
        produitId: produit.id,
      },
    });

    res.json(produitMisAJour);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur lors de l'ajout au stock" });
  }
});

app.get("/produits-mouvements", async (req, res) => {
  console.log("✅ Route /produits-mouvements appelée");
  try {
    const mouvements = await prisma.mouvementStock.findMany({
      orderBy: { date_mouvement: 'desc' },
      include: { produit: true },
    });
    res.json(mouvements);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur lors de la récupération des mouvements" });
  }
});
