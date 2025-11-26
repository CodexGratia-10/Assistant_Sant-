"""Moteur de décision simple basé sur des règles pour le triage axé sur le paludisme.

Structure d'ENTRÉE (dictionnaire de symptômes attendu par l'API) :
{
"fievre": true,
"temperature": 38.7,
"duree_fievre_jours": 2,
"frissons": true,
"toux": false,
"diarrhee": false,
"vomissements": false,
"convulsions": false,
"prostration": false,
"incapacite_a_manger": false,
"paludisme_recent": true
}

Structure de SORTIE :
{
"hypotheses": [
{"code": "PALU_SIMPLE", "label": "Paludisme simple", "score": 0.78},
{"code": "PALU_GRAVE", "label": "Paludisme grave", "score": 0.15},
{"code": "AUTRE_INFECTION", "label": "Autre infection fébrile", "score": 0.40}
],
"signes_de_danger": ["convulsions"],
"prochaines_questions": ["frissons", "duree_fievre_jours"],
"recommandation": "Effectuer un test RDT pour confirmer le paludisme."
}

Approche de notation : pondérations additives simples normalisées de 0 à 1 par hypothèse.
Les signes de danger augmentent le score de PALU_GRAVE et déclenchent une recommandation de renvoi urgent.
"""

from typing import Dict, List, Optional

HYPOTHESES_DEF = {
    "PALU_SIMPLE": {
        "label": "Paludisme simple",
        "base": 0.4,
        "positive_weights": {
            "fievre": 0.2,
            "frissons": 0.15,
            "paludisme_recent": 0.1,
        },
        "negative_weights": {
            "toux": 0.05,  # réduire si les symptômes respiratoires prédominent
            "diarrhee": 0.05,
        },
    },
    "PALU_GRAVE": {
        "label": "Paludisme grave",
        "base": 0.15,
        "positive_weights": {
            "fievre": 0.1,
            "convulsions": 0.4,
            "prostration": 0.3,
            "incapacite_a_manger": 0.2,
        },
        "negative_weights": {},
    },
    "AUTRE_INFECTION": {
        "label": "Autre infection fébrile",
        "base": 0.3,
        "positive_weights": {
            "toux": 0.25,
            "diarrhee": 0.25,
            "vomissements": 0.15,
        },
        "negative_weights": {
            "frissons": 0.1,
        },
    },
}

DANGER_SIGNS = ["convulsions", "prostration", "incapacite_a_manger"]

QUESTION_PRIORITIES = [
    "fievre",
    "temperature",
    "duree_fievre_jours",
    "frissons",
    "convulsions",
    "prostration",
    "incapacite_a_manger",
    "toux",
    "diarrhee",
    "vomissements",
    "paludisme_recent",
]

CORE_QUESTIONS = [
    "fievre",
    "frissons",
    "temperature",
    "duree_fievre_jours",
    "convulsions",
    "prostration",
    "incapacite_a_manger",
]  # ensemble minimal pour finalisation sauf si les signes de danger déclenchent une alerte précoce


def compute_hypotheses(symptoms: Dict, poids: Optional[float] = None, rdt_result: Optional[str] = None) -> Dict:
    scores = {}
    for code, spec in HYPOTHESES_DEF.items():
        score = spec["base"]
        for s, w in spec["positive_weights"].items():
            if symptoms.get(s):
                score += w
        for s, w in spec["negative_weights"].items():
            if symptoms.get(s):
                score -= w
        scores[code] = max(score, 0.0)

    # Normaliser de 0 à 1 en divisant par le maximum possible (limiter à 1)
    max_score = max(scores.values()) or 1
    for code in scores:
        scores[code] = round(scores[code] / max_score, 2)

    danger = [d for d in DANGER_SIGNS if symptoms.get(d)]

    if danger:
        # Forcer le paludisme grave à un score maximal en cas de signes de danger
        scores["PALU_GRAVE"] = 1.0

    hypotheses = [
        {"code": code, "label": HYPOTHESES_DEF[code]["label"], "score": scores[code]}
        for code in scores
    ]
    hypotheses.sort(key=lambda h: h["score"], reverse=True)

    # Déterminer les prochaines questions (les premières manquantes dans la liste de priorité)
    next_q: List[str] = []
    for q in QUESTION_PRIORITIES:
        if q not in symptoms:
            next_q.append(q)
        if len(next_q) >= 3:
            break

    dosage = None
    if danger:
        recommendation = "Référer immédiatement au centre de santé (signes de gravité)."
    else:
        # Si paludisme suspecté
        top = hypotheses[0]["code"] if hypotheses else None
        if rdt_result == "POS" and top in ("PALU_SIMPLE", "PALU_GRAVE"):
            recommendation = "Initier traitement ACT selon poids." if top == "PALU_SIMPLE" else "Référer (paludisme grave) après mesures initiales." 
            if poids:
                dosage = compute_act_dosage(poids)
        elif top in ("PALU_SIMPLE", "PALU_GRAVE"):
            recommendation = "Effectuer un test RDT pour confirmer le paludisme."
        else:
            recommendation = "Continuer l'évaluation clinique et surveiller la fièvre."

    return {
        "hypotheses": hypotheses,
        "danger_signs": danger,
        "next_questions": next_q,
        "recommendation": recommendation,
        "dosage": dosage,
    }


def triage(symptoms: Dict, poids: Optional[float] = None, rdt_result: Optional[str] = None) -> Dict:
    """Point d'entrée public pour le classement par priorité."""
    return compute_hypotheses(symptoms, poids=poids, rdt_result=rdt_result)


def compute_act_dosage(poids: float) -> Dict:
    """Retourner le schéma posologique de l'AL (Artéméther-Luméfantrine) selon le poids.

    Référence des catégories simplifiées:
    5-14 kg: 1 comprimé 2x/jour pendant 3 jours
    15-24 kg: 2 comprimés 2x/jour pendant 3 jours
    25-34 kg: 3 comprimés 2x/jour pendant 3 jours
    >=35 kg: 4 comprimés 2x/jour pendant 3 jours
    <5 kg: référer (ne pas administrer sans avis médical).
    """
    if poids < 5:
        return {"regimen": "Référer (poids <5kg)", "tablets_per_dose": 0, "doses_per_day": 0, "days": 0}
    if poids <= 14:
        tablets = 1
    elif poids <= 24:
        tablets = 2
    elif poids <= 34:
        tablets = 3
    else:
        tablets = 4
    return {
        "regimen": "Artemether-Lumefantrine",
        "tablets_per_dose": tablets,
        "doses_per_day": 2,
        "days": 3,
        "total_tablets": tablets * 2 * 3,
    }


def next_question(answered: Dict) -> Optional[str]:
    """Retourner la prochaine question sans réponse selon l'ordre de priorité."""
    for q in QUESTION_PRIORITIES:
        if q not in answered:
            return q
    return None


def is_completed(answered: Dict) -> bool:
    # Terminé si toutes les questions principales sont répondues OU si un signe de danger est vrai
    danger_hit = any(answered.get(d) for d in DANGER_SIGNS)
    if danger_hit:
        return True
    return all(q in answered for q in CORE_QUESTIONS)
