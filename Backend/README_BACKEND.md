# Backend Django – Assistant Santé Communautaire

Documentation en français pour le démarrage et l'intégration du backend (triage paludisme + gestion des entités de base) avec l'application Flutter.

## 1. Objectif
Ce backend fournit :
- API REST pour Patients, Relais, Diagnostics paludisme, Sessions de triage
- Moteur de triage paludisme basé sur règles (`decision_engine.py`)
- Documentation OpenAPI (Swagger / Redoc)
- Point d’entrée pour futur module de synchronisation

## 2. Prérequis
- Python 3.11+
- Pip / Virtualenv
- (Optionnel) Postman ou curl pour tester

## 3. Installation
```powershell
# Depuis le dossier racine du projet ou directement dans Backend/
cd Backend/Assitant_Sante

python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Installer dépendances
pip install -r ..\requirements.txt

# Appliquer migrations
python manage.py migrate
```

## 4. Variables d’environnement (développement)
```powershell
$env:DJANGO_SECRET_KEY = "dev-secret"
$env:DJANGO_DEBUG = "True"
$env:DJANGO_ALLOWED_HOSTS = "127.0.0.1,localhost"
```
En production, définir `DJANGO_DEBUG=False` et fournir une vraie clé secrète.

## 5. Lancement du serveur
```powershell
python manage.py runserver 0.0.0.0:8000
```
- API racine: `http://localhost:8000/api/`
- Swagger: `http://localhost:8000/schema/swagger-ui/`
- Redoc: `http://localhost:8000/redoc/`

Sur émulateur Android, l’app Flutter utilise `http://10.0.2.2:8000/api`.

## 6. Endpoints principaux
| Ressource | Méthode | URL | Description |
|-----------|---------|-----|-------------|
| Patients | GET/POST | `/api/patients/` | Liste / création |
| Patients | GET | `/api/patients/{id}/` | Détail |
| Diagnostics Palu | GET/POST | `/api/diagnostics/` | Enregistrer diagnostic |
| Diagnostic dernier patient | GET | `/api/diagnostics/patient/{patient_id}/latest/` | Dernier diag |
| Triage bloc | POST | `/api/triage/` | Calcul immédiat (payload symptômes) |
| Triage interactif start | POST | `/api/triage/start/` | Crée session + première question |
| Triage interactif answer | POST | `/api/triage/{session_id}/answer/` | Répond + question suivante ou final |
| Sync batch | POST | `/api/sync/commit/` | Applique opérations (prototype) |

## 7. Format triage interactif
### Démarrage
```json
POST /api/triage/start/
{
  "patient": 12,
  "relais": 3,
  "poids": 18.5,
  "rdt_result": "POS"
}
```
Réponse :
```json
{ "session_id": 45, "question": "fievre" }
```

### Réponse à une question
```json
POST /api/triage/45/answer/
{ "question": "fievre", "value": true }
```
Réponse (aperçu ou final selon complétion):
```json
{
 "completed": false,
 "next_question": "temperature",
 "preview_hypotheses": [ {"code": "PALU_SIMPLE", "label": "Paludisme simple", "score": 0.6 } ],
 "danger_signs": [],
 "session_id": 45
}
```
Ou final :
```json
{
 "completed": true,
 "final_output": {
   "hypotheses": [...],
   "danger_signs": [],
   "recommendation": "Effectuer un test RDT pour confirmer le paludisme.",
   "dosage": null
 },
 "session_id": 45,
 "diagnostic_created": true
}
```

## 8. Intégration Flutter
- Fichier `lib/config.dart` : `apiBaseUrl` et activation du mode serveur.
- Client API : `lib/services/triage_api.dart`
- Écran triage serveur : `lib/screens/backend_triage_screen.dart`
- Sélecteur de mode dans la fiche patient (`patient_detail_screen.dart`) : choix Local vs Serveur.

### Flux côté app
1. L’utilisateur ouvre un patient.
2. Il clique sur “Consultation”.
3. Choix : “Diagnostic Local” (arbre JSON embarqué) ou “Triage Serveur Palu”.
4. En mode serveur : les questions viennent du backend, chaque réponse met à jour l’aperçu des hypothèses.
5. Fin : recommandations + éventuelle posologie ACT calculée.

## 9. CORS & Accès
- `django-cors-headers` activé.
- En debug: `CORS_ALLOW_ALL_ORIGINS = True` (ne pas conserver en prod).
- Pour restreindre en prod: définir `DJANGO_DEBUG=False` et remplir `CORS_ALLOWED_ORIGINS`.

## 10. Évolutions possibles
- Authentification JWT (`djangorestframework-simplejwt`)
- Ajout endpoints grossesse, vaccination, alertes pour sync.
- Extension moteur à diarrhée / IRA / malnutrition (pondérations supplémentaires).
- Idempotency robuste pour `sync/commit`.

## 11. Tests rapides
```powershell
# Lancer shell Django
python manage.py shell

# Exemple création rapide
from apps.models import BaseRelais, Patient
r = BaseRelais.objects.create(nom="Relais 1", village="Kouandé", telephone="+229000000")
p = Patient.objects.create(nom="Test", age=7, sexe="M", village="Kouandé", relais=r)
```

## 12. Sécurité (à renforcer)
- Secret key via env OK.
- Manque : Auth, rate limiting, audit détaillé, filtrage IP.
- Ajouter plus tard avant production.

## 13. FAQ
**Pourquoi 10.0.2.2 ?** Sur émulateur Android cela pointe vers localhost machine hôte.
**Pourquoi règles et pas ML ?** Plus transparent, validable rapidement par équipes médicales, fonctionnel offline.
**Comment étendre ?** Ajouter poids dans recommandations, nouveaux champs dans `QUESTION_PRIORITIES`, mettre à jour pondérations.

---
_Ce backend est un socle MVP : privilégie simplicité, transparence et rapidité pour démonstration terrain._
