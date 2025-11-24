# Assistant Santé Communautaire

Application mobile Flutter pour l'aide au diagnostic et le suivi des patients en zones rurales et péri-urbaines du Bénin.

## 🎯 Objectif

Équiper les relais communautaires d'un outil intelligent pour :
- Pré-diagnostic des maladies courantes (paludisme, malnutrition, infections)
- Suivi des femmes enceintes et enfants
- Accès aux protocoles de soin officiels (offline)
- Synchronisation des données pour surveillance épidémiologique

## 🏗️ Architecture

### Stack Technique
- **Frontend**: Flutter (Dart)
- **Base de données locale**: SQLite (via sqflite)
- **Stockage offline**: Tous les protocoles et arbres de décision embarqués
- **IA**: Arbre de décision JSON + moteur de règles

### Structure du Projet

```
lib/
├── data/
│   ├── db/
│   │   ├── schema.sql              # Schéma SQLite complet
│   │   └── database_service.dart   # Service d'initialisation DB
│   ├── models/                     # Modèles de données
│   │   ├── patient.dart
│   │   ├── visit.dart
│   │   ├── symptom_observation.dart
│   │   ├── vital_sign.dart
│   │   └── malaria_rdt.dart
│   ├── dao/                        # Data Access Objects
│   │   ├── patient_dao.dart
│   │   ├── visit_dao.dart
│   │   └── observation_dao.dart
│   └── decision_tree/
│       └── decision_tree.dart      # Moteur d'évaluation
├── screens/                        # Écrans de l'application
│   ├── patients_list_screen.dart
│   ├── patient_detail_screen.dart
│   └── diagnosis_screen.dart
└── main.dart                       # Point d'entrée

assets/
└── decision_trees/
    └── malaria_tree.json           # Arbre décisionnel paludisme
```

## 📊 Modèle de Données

### Tables principales
- **patient**: Informations pseudo-anonymes (sexe, année naissance)
- **visit**: Consultations et visites
- **symptom_observation**: Symptômes observés
- **vital_sign**: Signes vitaux (température, fréquence respiratoire)
- **malaria_rdt**: Résultats tests rapides paludisme
- **pregnancy**: Suivi grossesse
- **vaccination**: Calendrier vaccinal
- **alert**: Alertes et rappels automatiques
- **audit_log**: Journal d'audit
- **sync_event**: File de synchronisation

## 🌳 Arbre de Décision (Paludisme)

L'arbre JSON structure le diagnostic :
- **Nodes**: Questions, actions, logique, décisions
- **Outcomes**: Résultats avec niveau d'urgence et actions
- **Scoring**: Système de pondération symptômes
- **Flags**: Détection signes de gravité

Exemple de flux :
1. Fièvre présente ? → Oui
2. Température → 38.5°C
3. Durée → 2 jours
4. Symptômes associés → Frissons, céphalées
5. RDT disponible ? → Oui
6. Résultat → Positif
7. **Outcome**: Paludisme simple suspecté

## 🚀 Installation et Lancement

### Prérequis
- Flutter SDK (≥3.0.0)
- Android Studio / VS Code
- Émulateur Android ou device physique

### Étapes

```powershell
# Cloner le projet
cd "c:\Users\danvi\OneDrive\Desktop\Hackaton de Grace"

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

### Première utilisation
1. Créer un nouveau patient (bouton +)
2. Sélectionner le patient
3. Démarrer une consultation
4. Suivre le diagnostic guidé
5. Voir le résultat et l'action recommandée

## 🔒 Sécurité et Confidentialité

### Implémenté
- Pseudo-anonymisation (pas de nom complet, année au lieu de date)
- Stockage local uniquement (pas de serveur dans cette version)
- Clés primaires UUID

### À implémenter (Phase 2)
- Chiffrement SQLite (SQLCipher)
- Authentification relais (PIN/biométrie)
- Rotation des clés
- Transmission TLS pour sync

## 📱 Fonctionnalités Actuelles

✅ Gestion des patients (CRUD)
✅ Consultations avec diagnostic guidé
✅ Arbre décisionnel paludisme interactif
✅ Stockage offline complet
✅ Interface conversationnelle intuitive
✅ Triage par niveau d'urgence (vert/orange/rouge)
✅ Base de données SQLite

## 🔜 Roadmap

### Phase 2 (Court terme)
- [ ] Arbres décisionnels: diarrhée, malnutrition, infections respiratoires
- [ ] Système d'alertes grossesse (PNC)
- [ ] Calendrier vaccinal automatique
- [ ] UI iconographique multilingue (Fon, Yoruba)
- [ ] Chiffrement base de données

### Phase 3 (Moyen terme)
- [ ] Module de synchronisation serveur
- [ ] Agrégation épidémiologique
- [ ] Détection d'épidémies (EWMA)
- [ ] Export DHIS2
- [ ] Mode vocal (ASR)

### Phase 4 (Long terme)
- [ ] Intégration caméra (MUAC, colorimétrie)
- [ ] Apprentissage fédéré
- [ ] Interopérabilité nationale complète

## 🧪 Tests

```powershell
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

## 📚 Protocoles Médicaux

Les arbres de décision sont basés sur :
- Directives du Ministère de la Santé du Bénin
- Protocoles OMS pour soins primaires
- PCIME (Prise en Charge Intégrée des Maladies de l'Enfant)

**⚠️ Important**: Cette application est un **outil d'aide à la décision**. Elle ne remplace pas le jugement clinique ni la consultation médicale. Les cas graves doivent toujours être référés.

## 👥 Contribution

Pour ajouter un nouvel arbre de décision :
1. Créer le JSON dans `assets/decision_trees/`
2. Suivre le format de `malaria_tree.json`
3. Définir nodes, outcomes, scoring
4. Ajouter à `pubspec.yaml` (section assets)
5. Tester avec différents scénarios

## 📄 Licence

Ce projet est développé dans le cadre du Hackathon de Grace pour l'amélioration de l'accès aux soins de santé primaires au Bénin.

## 📞 Contact & Support

Pour questions techniques ou médicales, contacter l'équipe du projet.

---

**Vision**: Démultiplier l'impact des relais communautaires avec l'IA, sans déshumaniser le lien soignant-patient.
