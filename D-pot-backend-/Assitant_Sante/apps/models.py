from django.db import models


SEXE_CHOICES = [
    ("M", "Masculin"),
    ("F", "Feminin"),
]

PALU_CLASSIFICATION_CHOICES = [
    ("SIMPLE", "Paludisme simple"),
    ("GRAVE", "Paludisme grave"),
    ("NON_SUSPECT", "Non suspect"),
]

TEST_TYPE_CHOICES = [
    ("RDT", "Test rapide"),
    ("GO", "Goutte epaisse"),
    ("NONE", "Non realise"),
]

class RDTResult(models.TextChoices):
    POS = "POS", "Positif"
    NEG = "NEG", "Negatif"
    IND = "IND", "Indetermine"

class BaseRelais(models.Model):
    nom = models.CharField(max_length=100)
    village = models.CharField(max_length=100)
    telephone = models.CharField(max_length=20)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"BaseRelais {self.nom} ({self.village})"


class Patient(models.Model):
    code = models.CharField(max_length=20, unique=True, blank=True, db_index=True)  # identifiant anonymise
    nom = models.CharField(max_length=120)
    age = models.IntegerField()
    sexe = models.CharField(max_length=1, choices=SEXE_CHOICES)
    village = models.CharField(max_length=100)
    relais = models.ForeignKey(BaseRelais, on_delete=models.CASCADE)
    poids_kg = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    date_creation = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Patient {self.nom}"


class DiagnosticPaludisme(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    relais = models.ForeignKey(BaseRelais, on_delete=models.CASCADE)
    symptomes = models.JSONField()
    test_type = models.CharField(max_length=4, choices=TEST_TYPE_CHOICES, default="RDT")
    test_result = models.CharField(max_length=3, choices=RDTResult.choices, null=True, blank=True)
    classification = models.CharField(max_length=12, choices=PALU_CLASSIFICATION_CHOICES)
    danger_signs = models.JSONField(default=dict, blank=True)
    recommendation = models.TextField()
    protocol_version = models.CharField(max_length=20, default="v1")
    date = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Diag {self.patient_id} {self.classification} {self.date.date()}"


class SyncQueue(models.Model):
    model_name = models.CharField(max_length=50)
    object_id = models.CharField(max_length=50)
    operation = models.CharField(max_length=10, choices=[("CREATE", "CREATE"), ("UPDATE", "UPDATE"), ("DELETE", "DELETE")])
    data = models.JSONField()
    synced = models.BooleanField(default=False)
    retry_count = models.PositiveSmallIntegerField(default=0)
    last_attempt_at = models.DateTimeField(null=True, blank=True)
    date = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Sync {self.model_name} {self.object_id} synced={self.synced}"


class TriageSession(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.SET_NULL, null=True, blank=True)
    relais = models.ForeignKey(BaseRelais, on_delete=models.SET_NULL, null=True, blank=True)
    symptomes = models.JSONField()
    engine_output = models.JSONField()
    rdt_result = models.CharField(max_length=3, choices=RDTResult.choices, null=True, blank=True)
    poids_utilise = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    answered = models.JSONField(default=dict)  # incremental answers
    completed = models.BooleanField(default=False)
    final_output = models.JSONField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Triage {self.id} patient={self.patient_id}"


