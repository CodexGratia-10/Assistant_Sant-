# 📂 Structure Complète du Projet

```
Hackaton de Grace/
│
├── 📱 android/                          # Configuration Android (auto-généré)
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/example/assistant_sante/
│   │           └── MainActivity.kt
│   ├── build.gradle.kts
│   └── settings.gradle.kts
│
├── 🎨 assets/                           # Ressources embarquées
│   └── decision_trees/
│       └── malaria_tree.json            # ⭐ Arbre décisionnel paludisme
│
├── 📚 lib/                              # Code source principal
│   ├── main.dart                        # ⭐ Point d'entrée + menu
│   │
│   ├── data/                            # Couche données
│   │   ├── db/
│   │   │   ├── schema.sql               # ⭐ Schéma SQLite (10 tables)
│   │   │   └── database_service.dart    # Service init DB
│   │   │
│   │   ├── models/                      # Modèles de données
│   │   │   ├── patient.dart
│   │   │   ├── visit.dart
│   │   │   ├── symptom_observation.dart
│   │   │   ├── vital_sign.dart
│   │   │   └── malaria_rdt.dart
│   │   │
│   │   ├── dao/                         # Data Access Objects
│   │   │   ├── patient_dao.dart
│   │   │   ├── visit_dao.dart
│   │   │   └── observation_dao.dart
│   │   │
│   │   └── decision_tree/
│   │       └── decision_tree.dart       # ⭐ Moteur IA
│   │
│   └── screens/                         # Écrans UI
│       ├── patients_list_screen.dart    # Liste patients
│       ├── patient_detail_screen.dart   # Détail + historique
│       └── diagnosis_screen.dart        # ⭐ Diagnostic guidé
│
├── 🧪 test/                             # Tests
│   └── widget_test.dart                 # Tests de base
│
├── 📄 Configuration
│   ├── pubspec.yaml                     # ⭐ Dépendances
│   ├── pubspec.lock                     # Versions lockées
│   ├── analysis_options.yaml            # Règles lint
│   └── .gitignore                       # Exclusions Git
│
└── 📖 Documentation
    ├── README.md                        # ⭐ Documentation principale
    ├── QUICKSTART.md                    # Démarrage rapide
    ├── DEVELOPMENT.md                   # Guide développeur
    ├── PROJECT_SUMMARY.md               # Résumé complet
    ├── VALIDATION.md                    # ✅ Checklist validation
    ├── COMMANDS.md                      # Commandes essentielles
    ├── ARCHITECTURE.md                  # Ce fichier
    └── Contexte.txt                     # Cahier des charges
```

## 📊 Statistiques

### Fichiers par Catégorie
- **Code source Dart**: 15 fichiers
- **Configuration**: 4 fichiers
- **Documentation**: 7 fichiers
- **Assets**: 1 fichier JSON
- **Total**: ~27 fichiers principaux

### Répartition du Code
```
lib/
├── screens/         3 fichiers  (~800 lignes)
├── data/models/     5 fichiers  (~200 lignes)
├── data/dao/        3 fichiers  (~200 lignes)
├── data/db/         2 fichiers  (~100 lignes)
└── main.dart        1 fichier   (~160 lignes)
─────────────────────────────────────────────
Total:              14 fichiers  ~1460 lignes
```

## 🎯 Fichiers Clés

### Pour Utilisateur
1. **QUICKSTART.md** - Installation en 5 min
2. **README.md** - Vue d'ensemble
3. **COMMANDS.md** - Commandes utiles

### Pour Développeur
1. **lib/main.dart** - Point d'entrée
2. **lib/data/db/schema.sql** - Structure DB
3. **assets/decision_trees/malaria_tree.json** - Arbre IA
4. **DEVELOPMENT.md** - Extensions

### Pour Product Owner
1. **PROJECT_SUMMARY.md** - Résumé exécutif
2. **VALIDATION.md** - Checklist livrables
3. **Contexte.txt** - Cahier des charges

## 🗂️ Organisation par Couche

### Couche Présentation (UI)
```
screens/
├── patients_list_screen.dart      # Liste + création
├── patient_detail_screen.dart     # Détail + consultations
└── diagnosis_screen.dart          # Diagnostic interactif
```

### Couche Business Logic
```
data/decision_tree/
└── decision_tree.dart             # Moteur décisionnel
```

### Couche Accès Données
```
data/dao/
├── patient_dao.dart               # CRUD patients
├── visit_dao.dart                 # CRUD consultations
└── observation_dao.dart           # CRUD observations
```

### Couche Données
```
data/models/
├── patient.dart                   # Entité Patient
├── visit.dart                     # Entité Consultation
├── symptom_observation.dart       # Entité Symptôme
├── vital_sign.dart                # Entité Signe vital
└── malaria_rdt.dart               # Entité Test RDT
```

### Couche Persistance
```
data/db/
├── schema.sql                     # DDL (CREATE TABLE)
└── database_service.dart          # Connexion SQLite
```

## 🔄 Flux de Données

```
┌─────────────────────────────────────────┐
│  User Interface (Screens)               │
│  ┌──────────┬───────────┬────────────┐  │
│  │ List     │  Detail   │  Diagnosis │  │
│  └────┬─────┴─────┬─────┴──────┬─────┘  │
└───────┼───────────┼────────────┼────────┘
        │           │            │
        ▼           ▼            ▼
┌─────────────────────────────────────────┐
│  Business Logic                         │
│  ┌──────────────────────────────────┐   │
│  │   Decision Engine (IA)           │   │
│  └──────────────────────────────────┘   │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Data Access Layer (DAOs)               │
│  ┌────────┬──────────┬──────────────┐   │
│  │Patient │ Visit    │ Observation  │   │
│  └────┬───┴────┬─────┴──────┬───────┘   │
└───────┼────────┼────────────┼───────────┘
        │        │            │
        ▼        ▼            ▼
┌─────────────────────────────────────────┐
│  SQLite Database (Local)                │
│  ┌──────┬───────┬──────────────────┐    │
│  │Tables│ FKs   │ Indexes          │    │
│  └──────┴───────┴──────────────────┘    │
└─────────────────────────────────────────┘
```

## 🎨 Patterns Utilisés

- **Repository Pattern**: DAOs abstraient l'accès DB
- **Model-View Pattern**: Séparation UI/Données
- **Factory Pattern**: fromMap() pour désérialisation
- **Singleton Pattern**: DatabaseService.instance
- **Strategy Pattern**: Decision Tree interchangeable

## 📦 Dépendances Externes

```yaml
sqflite: ^2.3.0        # Base SQLite
path: ^1.8.3           # Gestion chemins
uuid: ^4.0.0           # Génération UUID
collection: ^1.18.0    # Utilitaires collections
```

## 🔐 Sécurité par Couche

### UI Layer
- Validation inputs utilisateur
- Sanitization données affichées

### Business Layer
- Règles métier (signes gravité)
- Limites système claires

### Data Layer
- Pseudo-anonymisation (UUID)
- Pas de PII en clair

### Persistence Layer
- SQLite local uniquement
- Foreign keys contraintes
- Audit trail

## 🚀 Points d'Extension

### Ajouter une Maladie
1. Créer JSON dans `assets/decision_trees/`
2. Créer écran diagnostic (copier diagnosis_screen.dart)
3. Ajouter au menu principal

### Ajouter une Table
1. Éditer `schema.sql`
2. Créer modèle dans `data/models/`
3. Créer DAO dans `data/dao/`

### Ajouter un Écran
1. Créer dans `screens/`
2. Router depuis `main.dart`
3. Utiliser DAOs existants

## 📱 Build Targets

```
android/                    # Android (API 21+)
[ios/]                      # iOS (non configuré)
[web/]                      # Web (non configuré)
[windows/linux/macos/]      # Desktop (non configuré)
```

## 🔧 Configuration Environnement

### Requis
- Flutter SDK ≥ 3.0.0
- Dart SDK (inclus Flutter)
- Android SDK (pour build APK)

### Optionnel
- VS Code + Flutter extension
- Android Studio
- Git

## 📈 Évolution Projet

### v1.0 (Actuel) ✅
- Paludisme uniquement
- Offline complet
- Patients + Consultations

### v1.1 (À venir)
- Diarrhée, Malnutrition
- Alertes vaccination
- UI multilingue

### v2.0 (Futur)
- Synchronisation serveur
- Agrégation épidémio
- DHIS2 export

---

**Cette structure est évolutive, modulaire et prête pour scaling.**
