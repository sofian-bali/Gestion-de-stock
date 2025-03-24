# Gestion de stock 📦

## 🪧 À propos

Gestion de stock est une application mobile développée pour la société FragranceBali. Elle permet de gérer efficacement l’inventaire des produits via le scan de code-barres. L’application offre des fonctionnalités comme :
- Ajout de produit
- Suivi de stock en temps réel
- Historique des mouvements
- Consultation des notes (olfactives) et genre du parfum
- Gestion des dupes

## 📚 Table des matières

- 🪧 [À propos](#à-propos)
- 📦 [Prérequis](#prérequis)
- 🚀 [Installation](#installation)
- ⚙️ [API](#api)
- 🤝 [Contribution](#contribution)
- 🛠️ [Langages & Frameworks](#langages--frameworks)

## 📦 Prérequis

Avant de commencer, assurez-vous d'avoir :

- **Node.js** : pour le backend. [Node.js](https://nodejs.org/)
- **Flutter** : pour le frontend. [Flutter](https://docs.flutter.dev/get-started/install)
- Un éditeur de code (VSCode recommandé)
- Un compte Supabase ou Railway pour héberger la base de données PostgreSQL

## 🚀 Installation

### 📂 Clonage du projet

```bash
git clone https://github.com/sofian-bali/Gestion-de-stock.git
cd Gestion-de-stock
```

### 🔧 Vérification Flutter

```bash
flutter doctor
```

Corrigez les erreurs s'il y en a.

### 📲 Lancer l’application Flutter

```bash
cd frontend/stock_scan
flutter pub get
flutter run
```

### 🔧 Lancer le backend Node.js

```bash
cd backend
npm install
npx prisma generate
npm run start
```

L’API sera disponible sur [http://localhost:3000](http://localhost:3000)

## 📦 Build

### 🤖 Android

```bash
flutter build apk
```

### 🍏 iOS

```bash
flutter build ios
```

### 🖥️ Web

```bash
flutter build web
```

## ⚙️ API

- **GET /produits/:code_barres** → Récupère un produit par code-barres
- **POST /produits** → Ajoute un produit
- **PATCH /produits/:code_barres/ajouter** → Ajoute du stock
- **PATCH /produits/:code_barres/retirer** → Retire du stock
- **GET /produits/:code_barres/mouvements** → Historique du produit
- **GET /produits-mouvements** → Tous les mouvements

## 🤝 Contribution

Projet développé par :

- [@sofian-bali](https://github.com/sofian-bali)
- [@MaximeLemesle](https://github.com/MaximeLemesle)

## 🛠️ Langages & Frameworks

<img src="https://img.shields.io/badge/Framework-Flutter-blue?style=flat&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Code-Dart-336791?style=flat&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Code-Node.js-339933?style=flat&logo=node.js&logoColor=whitee" />
<img src="https://img.shields.io/badge/Framework-Express.js-lightgray?style=flat&logo=express&logoColor=white"/>
<img src="https://img.shields.io/badge/ORM-Prisma-2D3748?style=flat&logo=prisma&logoColor=white" />
<img src="https://img.shields.io/badge/Database-PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white" />
