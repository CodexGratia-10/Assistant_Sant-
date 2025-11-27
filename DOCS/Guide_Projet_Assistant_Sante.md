# Guide Projet – Assistant Santé Communautaire

## 1. Vue d’ensemble
- Application mobile Flutter pour agents communautaires (offline-first).
- Base locale SQLite (patients, consultations, symptômes, vaccinations, grossesse, alertes).
- Backend Django/DRF optionnel pour triage paludisme côté serveur et historique.
- IA visible comme "Diagnostic guidé"/"Autres consultations" (pas de jargon technique pour l’utilisateur).

## 2. Démarrage rapide
### Prérequis
- Flutter 3.x (SDK installé et `flutter doctor` OK)
- Android SDK + émulateur ou appareil USB
- Python 3.10+ avec `pip`

### Lancer le Front (Flutter)
```powershell
# Depuis le dossier projet
cd "C:\Users\danvi\OneDrive\Desktop\Hackaton de Grace"
flutter clean
flutter pub get
flutter run
```
Notes Android:
- Si un avertissement NDK apparaît, utilisez `ndkVersion "27.0.12077973"` (déjà forcé dans `android/app/build.gradle.kts`).
- En cas de rendu OpenGL limité sur émulateur, basculer AVD sur "Hardware - GLES 3.1".

### Lancer le Backend (Django)

Chemin exact du backend: `C:\Users\danvi\OneDrive\Desktop\Hackaton de Grace\Backend\Assitant_Sante` (attention à l’orthographe et à la casse `Backend/Assitant_Sante`).

1) Ouvrir une session PowerShell et se placer dans le dossier backend
```powershell
cd "C:\Users\danvi\OneDrive\Desktop\Hackaton de Grace\Backend\Assitant_Sante"
```

2) Créer et activer l’environnement virtuel Python (une seule fois)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate
```

3) Installer les dépendances Python
```powershell
pip install --upgrade pip
pip install -r requirements.txt
```

4) Appliquer les migrations de base de données
```powershell
python manage.py migrate
```

5) (Optionnel) Créer un superutilisateur pour accéder à l’admin
```powershell
python manage.py createsuperuser
```

6) Lancer le serveur Django
```powershell
python manage.py runserver
```

Le serveur écoute par défaut sur `http://127.0.0.1:8000/`

- Swagger/Redoc (si activé): `http://127.0.0.1:8000/api/schema/swagger/`
- API triage: `http://127.0.0.1:8000/api/`

## 3. Structure du projet (simplifiée)
- `lib/` (Flutter)
  - `screens/` (UI: patients, consultation guidée, triage serveur, vaccination, grossesse, alertes)
  - `data/` (models + DAOs + DB)
  - `services/` (triage_api, vaccination_scheduler, pregnancy_tracker, decision trees)
  - `assets/decision_trees/` (arbres JSON locaux)
- `backend/assitant_sante/` (Django/DRF)
  - `apps/` (models, views, serializers, decision_engine)
  - `manage.py`, `requirements.txt`

## 4. Flux fonctionnels
### Patients
- Création via `PatientsListScreen` (prénom, nom, téléphone, sexe, année).
- Fiche patient (`PatientDetailScreen`) affiche infos + liste des consultations.

### Consultation locale (offline)
- `DiagnosisScreen`: diagnostic guidé à partir d’arbres décisionnels JSON.
- Les réponses sont persistées (`SymptomObservation`), la visite est complétée avec un résultat.
- Bouton de fin: `Terminer la consultation`.

### Consultation serveur (paludisme)
- `BackendTriageScreen`: questions séquencées depuis le backend.
- Aperçu des hypothèses et signes de danger à chaque réponse.
- À la fin, affichage en français (Hypothèses, Recommandation, Posologie). Bouton: `Terminer`.
- Création auto d’alerte "URGENT_REFERRAL" si danger.

### Mode offline (local) – options
- Sélecteur discret: `Mode offline` + bouton `Plus d'options` (bottom sheet) pour choisir la pathologie (Fièvre/Palu, Respiratoire, Diarrhée, Malnutrition).
- Carte d’aide affichant l’hypothèse et la recommandation calculées localement.

### Vaccination enfants
- `VaccinationScreen`: liste des vaccinations "scheduled"; actions `Administré` et `Replanifier`.
- Création d’un calendrier via `Nouveau Calendrier` (patient + date de naissance).
- Bandeau rappel: calendrier calculé à partir de la date saisie.
- `VaccinationScheduler` génère planning PEV + alertes (avant échéance).

### Suivi de grossesse (CPN)
- `PregnancyScreen`: liste grossesses actives; `Nouvelle Grossesse` (patiente, DDR, risque).
- `PregnancyManagementScreen`: résumé semaines, trimestre, terme; liste des visites CPN à venir.
- Bandeau rappel: dates calculées automatiquement depuis la DDR; bouton `Effectuée` pour accuser réception.
- `PregnancyTracker` crée dossier + 8 visites CPN (12,20,26,30,34,36,38,40 SA) avec alertes.

### Alertes & Rappels
- `AlertsScreen`: affiche les alertes `vaccination`, `pregnancy`, `followup` avec statut.
- Badge d’alertes en page d’accueil.

## 5. Intégration Front ↔ Back
### Côté Flutter
- Base URL et mode serveur dans `lib/config.dart` (`enableBackendTriage`).
- Client API: `lib/services/triage_api.dart` (start, answer, triage bloc).
- Écran: `lib/screens/backend_triage_screen.dart`.
- Persistences locales via DAOs (`VisitDao`, `ObservationDao`, etc.).

### Côté Django/DRF
- Routes principales (voir `Backend/Assitant_Sante/apps/urls.py`):
  - `POST /api/triage/start/` → démarre session interactive
  - `POST /api/triage/{session_id}/answer/` → enregistre réponse, renvoie question suivante ou résultat final
  - `POST /api/triage/` → triage bloc (direct, sans session)
  - CRUD: patients, diagnostics, sessions
- Moteur décisionnel palu: `decision_engine.py` applique règles (hypothèses, danger, posologie ACT).

## 6. Données & Persistance
- SQLite tables: `patient`, `visit`, `symptom_observation`, `vaccination`, `pregnancy`, `alert`.
- DAOs: CRUD + requêtes ciblées (ex: `getScheduled()` pour vaccination, `getCurrentPregnancy()` pour grossesse).
- Synchronisation serveur: non activée par défaut (roadmap).

## 7. UX & Libellés
- Libellés en français, pas de jargon IA côté utilisateur.
- Boutons cohérents: `Terminer la consultation`, `Nouveau Calendrier`, `Nouvelle Grossesse`, `Effectuée`.
- Bandeaux rappel (vaccination, grossesse) pour expliquer le calcul automatique.

## 8. Dépannage
- NDK Android: fixé à `27.0.12077973` dans `android/app/build.gradle.kts`.
- Rendu émulateur: adapter AVD si OpenGL limité.
- Réinitialiser build:
```powershell
flutter clean
flutter pub get
flutter run
```
- Backend:
```powershell
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## 9. Roadmap (extraits)
- Arbres additionnels (diarrhée, malnutrition, respiratoire) – couverture complète.
- Synchronisation serveur (diagnostics, visites, alertes).
- Multilingue (Fon, Yoruba), chiffrement DB, agrégation épidémiologique.

## 10. Références de fichiers
- `lib/screens/backend_triage_screen.dart` – Triage serveur & offline options
- `lib/screens/diagnosis_screen.dart` – Diagnostic guidé local
- `lib/screens/vaccination_screen.dart` – Vaccination enfants (bandeau + liste)
- `lib/screens/pregnancy_management_screen.dart` – Suivi patiente (bandeau + CPN)
- `lib/services/vaccination_scheduler.dart` – Génération calendrier vaccinal + alertes
- `lib/services/pregnancy_tracker.dart` – Création grossesse + visites CPN
- `backend/assitant_sante/apps/views.py` – API triage interactif/bloc
