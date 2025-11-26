from django.contrib import admin

# Register your models here.
from .models import BaseRelais, Patient, DiagnosticPaludisme, SyncQueue, TriageSession

admin.site.register(BaseRelais)
admin.site.register(Patient)
admin.site.register(DiagnosticPaludisme)
admin.site.register(SyncQueue)
admin.site.register(TriageSession)