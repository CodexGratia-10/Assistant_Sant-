from rest_framework import serializers
from .models import Patient, DiagnosticPaludisme, SyncQueue, BaseRelais, TriageSession
from django.db import transaction

from .models import RDTResult

class TriageRequestSerializer(serializers.Serializer):
	symptomes = serializers.DictField(required=False, default=dict)
	poids = serializers.FloatField(required=False, allow_null=True)
	rdt_result = serializers.ChoiceField(choices=RDTResult.choices, required=False, allow_null=True)
	save = serializers.BooleanField(required=False, default=False)
	patient = serializers.IntegerField(required=False, allow_null=True)
	relais = serializers.IntegerField(required=False, allow_null=True)

class TriageResponseSerializer(serializers.Serializer):
	hypotheses = serializers.ListField(child=serializers.DictField())
	danger_signs = serializers.ListField(child=serializers.CharField())
	next_questions = serializers.ListField(child=serializers.CharField())
	recommendation = serializers.CharField()
	dosage = serializers.DictField(allow_null=True, required=False)
	session_id = serializers.IntegerField(required=False)

class InteractiveStartSerializer(serializers.Serializer):
	patient = serializers.IntegerField(required=False, allow_null=True)
	relais = serializers.IntegerField(required=False, allow_null=True)
	poids = serializers.FloatField(required=False, allow_null=True)
	rdt_result = serializers.ChoiceField(choices=RDTResult.choices, required=False, allow_null=True)

class InteractiveStartResponseSerializer(serializers.Serializer):
	session_id = serializers.IntegerField()
	question = serializers.CharField(allow_null=True)

class InteractiveAnswerSerializer(serializers.Serializer):
	question = serializers.CharField()
	# Accepte booléen, nombre, chaîne -> champ JSON générique
	value = serializers.JSONField()

class InteractiveAnswerPreviewResponseSerializer(serializers.Serializer):
	completed = serializers.BooleanField()
	next_question = serializers.CharField(allow_null=True)
	preview_hypotheses = serializers.ListField(child=serializers.DictField())
	danger_signs = serializers.ListField(child=serializers.CharField())
	session_id = serializers.IntegerField()

class InteractiveAnswerFinalResponseSerializer(serializers.Serializer):
	completed = serializers.BooleanField()
	final_output = serializers.DictField()
	session_id = serializers.IntegerField()
	diagnostic_created = serializers.BooleanField()


class PatientSerializer(serializers.ModelSerializer):
	class Meta:
		model = Patient
		fields = [
			'id','code','nom','age','sexe','village','relais','poids_kg','date_creation','updated_at'
		]
		read_only_fields = ['id','date_creation','updated_at','code']

	def create(self, validated_data):
		# Attendre que relais soit fourni explicitement car pas de couche d'authentification
		relais = validated_data.get('relais')
		if not relais:
			raise serializers.ValidationError({'relais': 'Requis'})
		if not validated_data.get('code'):
			validated_data['code'] = f"P{relais.id}-{Patient.objects.count()+1}"
		return super().create(validated_data)

class BaseRelaisSerializer(serializers.ModelSerializer):
	class Meta:
		model = BaseRelais
		fields = ['id', 'nom', 'village', 'telephone', 'updated_at']
		read_only_fields = ['id', 'updated_at']
		
        
class DiagnosticPaludismeSerializer(serializers.ModelSerializer):
	patient_detail = PatientSerializer(source='patient', read_only=True)

	class Meta:
		model = DiagnosticPaludisme
		fields = [
			'id','patient','patient_detail','relais','symptomes','test_type','test_result',
			'classification','danger_signs','recommendation','protocol_version','date','updated_at'
		]
		read_only_fields = ['id','date','updated_at','protocol_version']

	def create(self, validated_data):
		if not validated_data.get('relais'):
			raise serializers.ValidationError({'relais': 'Requis'})
		validated_data['protocol_version'] = 'v1'
		return super().create(validated_data)


class SyncQueueSerializer(serializers.ModelSerializer):
	class Meta:
		model = SyncQueue
		fields = [
			'id','model_name','object_id','operation','data','synced','retry_count','last_attempt_at','date','updated_at'
		]
		read_only_fields = ['id','retry_count','last_attempt_at','date','updated_at']


class TriageSessionSerializer(serializers.ModelSerializer):
	class Meta:
		model = TriageSession
		fields = [
			'id','patient','relais','symptomes','engine_output','rdt_result','poids_utilise',
			'answered','completed','final_output','created_at','updated_at'
		]
		read_only_fields = ['id','engine_output','answered','completed','final_output','created_at','updated_at']

	def create(self, validated_data):
		# Assurez-vous que engine_output est présent lors de l'insertion dans la base de données pour éviter les erreurs NOT NULL
		if 'engine_output' not in validated_data or validated_data.get('engine_output') is None:
			validated_data['engine_output'] = {}
		# Assurez-vous que answered est présent lors de l'insertion dans la base de données pour éviter les erreurs NOT NULL
		if 'answered' not in validated_data or validated_data.get('answered') is None:
			validated_data['answered'] = {}
		return super().create(validated_data)


class SyncOperationSerializer(serializers.Serializer):
	client_id = serializers.CharField(required=False, allow_null=True)
	model = serializers.CharField()  # e.g. Patient, DiagnosticPaludisme
	operation = serializers.ChoiceField(choices=['CREATE', 'UPDATE', 'DELETE'])
	data = serializers.DictField()
	idempotency_key = serializers.CharField(required=False, allow_null=True)


class SyncBatchRequestSerializer(serializers.Serializer):
	operations = SyncOperationSerializer(many=True)


class SyncOperationResultSerializer(serializers.Serializer):
	client_id = serializers.CharField(required=False, allow_null=True)
	status = serializers.ChoiceField(choices=['ok', 'error'])
	server_id = serializers.IntegerField(required=False, allow_null=True)
	error = serializers.CharField(required=False, allow_null=True)


class SyncBatchResponseSerializer(serializers.Serializer):
	results = SyncOperationResultSerializer(many=True)
 
