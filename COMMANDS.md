# 🚀 Commandes Essentielles - Assistant Santé

## Navigation

```powershell
# Aller dans le dossier du projet
cd "c:\Users\danvi\OneDrive\Desktop\Hackaton de Grace"
```

## Installation & Configuration

```powershell
# Installer les dépendances (déjà fait)
flutter pub get

# Vérifier l'environnement Flutter
flutter doctor

# Mettre à jour Flutter (optionnel)
flutter upgrade
```

## Lancement de l'Application

```powershell
# Lancer en mode debug
flutter run

# Lancer en mode release (plus rapide)
flutter run --release

# Lancer avec logs détaillés
flutter run -v
```

## Build APK

```powershell
# Build APK debug
flutter build apk

# Build APK release (optimisé)
flutter build apk --release

# Build App Bundle (pour Play Store)
flutter build appbundle --release
```

**APK généré dans**: `build\app\outputs\flutter-apk\app-release.apk`

## Gestion des Émulateurs

```powershell
# Lister les émulateurs disponibles
flutter emulators

# Créer un nouvel émulateur
flutter emulators --create

# Lancer un émulateur
flutter emulators --launch <emulator_id>

# Lister les devices connectés
flutter devices
```

## Développement

```powershell
# Analyse statique du code
flutter analyze

# Analyse du dossier lib/ uniquement
flutter analyze lib/

# Formater le code
flutter format lib/

# Nettoyer le cache
flutter clean

# Nettoyer puis réinstaller
flutter clean; flutter pub get
```

## Tests

```powershell
# Lancer les tests unitaires
flutter test

# Lancer les tests avec coverage
flutter test --coverage

# Lancer un test spécifique
flutter test test/decision_tree_test.dart
```

## Base de Données

```powershell
# Voir le chemin de la base (dans l'app via code)
# Android: /data/data/com.example.assistant_sante/databases/assistant_sante.db

# Réinitialiser la base (désinstaller/réinstaller l'app)
flutter clean
flutter run
```

## Maintenance

```powershell
# Mettre à jour les dépendances
flutter pub upgrade

# Vérifier dépendances obsolètes
flutter pub outdated

# Analyser la taille de l'APK
flutter build apk --analyze-size
```

## Déploiement

```powershell
# Installer APK sur device connecté
flutter install

# Build et install en une commande
flutter run --release

# Désinstaller
adb uninstall com.example.assistant_sante
```

## Logs & Debug

```powershell
# Voir les logs en temps réel
flutter logs

# Logs Android uniquement
adb logcat

# Nettoyer les logs
adb logcat -c
```

## Raccourcis en Mode Run

Pendant que l'app tourne (`flutter run`):

- `r` - Hot reload (recharge rapide)
- `R` - Hot restart (redémarrage complet)
- `q` - Quitter
- `h` - Aide
- `d` - Détacher (laisser tourner)
- `v` - Ouvrir DevTools
- `w` - Dump widget hierarchy

## Fichiers Importants

```powershell
# Éditer l'arbre de décision
notepad "assets\decision_trees\malaria_tree.json"

# Éditer le schéma DB
notepad "lib\data\db\schema.sql"

# Éditer la config
notepad "pubspec.yaml"

# Voir les dépendances installées
type "pubspec.lock"
```

## Utilitaires Windows

```powershell
# Ouvrir le dossier dans l'explorateur
start .

# Ouvrir VS Code dans le projet
code .

# Compter les lignes de code
Get-ChildItem -Path lib -Recurse -Filter *.dart | Get-Content | Measure-Object -Line
```

## Dépannage Rapide

```powershell
# Problème de cache
flutter clean
flutter pub get
flutter run

# Problème Gradle (Android)
cd android
.\gradlew clean
cd ..
flutter run

# Réinitialiser complètement
flutter clean
Remove-Item -Recurse -Force .dart_tool
Remove-Item -Recurse -Force build
flutter pub get
flutter run
```

## Workflow Complet

```powershell
# 1. Ouvrir le projet
cd "c:\Users\danvi\OneDrive\Desktop\Hackaton de Grace"

# 2. Vérifier l'état
flutter doctor
flutter devices

# 3. Analyser le code
flutter analyze lib/

# 4. Lancer l'app
flutter run

# 5. Tester (pendant que l'app tourne)
# - Créer patient
# - Nouvelle consultation
# - Tester diagnostic

# 6. Build APK final
flutter build apk --release

# 7. Installer sur device physique
flutter install
```

## Variables d'Environnement Utiles

```powershell
# Voir le SDK Flutter
echo $env:FLUTTER_ROOT

# Voir le SDK Android
echo $env:ANDROID_HOME

# Ajouter Flutter au PATH (si nécessaire)
$env:PATH += ";C:\path\to\flutter\bin"
```

## Commandes Git (optionnel)

```powershell
# Initialiser repo
git init
git add .
git commit -m "Initial commit - Assistant Santé Communautaire"

# Créer branche dev
git checkout -b dev

# Voir le statut
git status

# Historique
git log --oneline
```

## Performance

```powershell
# Profiler l'app
flutter run --profile

# Build avec optimisation
flutter build apk --release --obfuscate --split-debug-info=symbols/

# Analyser la performance
flutter drive --target=test_driver/perf_test.dart
```

## Documentation Auto

```powershell
# Générer documentation API
dart doc .

# Ouvrir la doc générée
start doc\api\index.html
```

---

## ⚡ Commandes les Plus Utilisées

```powershell
# TOP 5
flutter run                    # Lancer l'app
flutter build apk --release    # Build production
flutter clean                  # Nettoyer
flutter analyze lib/           # Vérifier le code
flutter pub get                # Installer dépendances
```

---

**Copier-coller ces commandes directement dans PowerShell.**
