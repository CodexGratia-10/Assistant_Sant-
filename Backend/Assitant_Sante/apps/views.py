from django.shortcuts import render
from rest_framework import viewsets, views, status, generics
from .models import Patient, BaseRelais,  DiagnosticPaludisme, SyncQueue, TriageSession
from .serializers import (
	PatientSerializer,
	DiagnosticPaludismeSerializer,
	BaseRelaisSerializer,
	SyncQueueSerializer,
	TriageSessionSerializer,
	TriageRequestSerializer,
	TriageResponseSerializer,
	InteractiveStartSerializer,
	InteractiveStartResponseSerializer,
	InteractiveAnswerSerializer,
	InteractiveAnswerPreviewResponseSerializer,
	InteractiveAnswerFinalResponseSerializer,
	SyncBatchRequestSerializer,
	SyncBatchResponseSerializer,
)
from django.db import transaction
from rest_framework.response import Response
from rest_framework.decorators import action
from .decision_engine import triage, next_question, is_completed
try:
	from drf_spectacular.utils import extend_schema  # type: ignore[import]
except Exception:
	# drf-spectacular not installed or import cannot be resolved in this environment;
	# provide a no-op fallback so the views remain usable without the package.
	def extend_schema(*args, **kwargs):
		def decorator(obj):
			return obj
		return decorator


class BaseRelaisViewSet(viewsets.ModelViewSet):
    queryset = BaseRelais.objects.all()
    serializer_class = BaseRelaisSerializer

class PatientViewSet(BaseRelaisViewSet):
	serializer_class = PatientSerializer

	def get_queryset(self):
		return Patient.objects.all().order_by('-updated_at')


class DiagnosticPaludismeViewSet(BaseRelaisViewSet):
	serializer_class = DiagnosticPaludismeSerializer

	def get_queryset(self):
		return DiagnosticPaludisme.objects.all().order_by('-date')

	@action(detail=False, methods=['get'], url_path='patient/(?P<patient_id>[^/.]+)/latest')
	def latest_for_patient(self, request, patient_id=None):
		diag = DiagnosticPaludisme.objects.filter(patient_id=patient_id).order_by('-date').first()
		if not diag:
			return Response({'detail': 'Aucun diagnostic'}, status=404)
		serializer = self.get_serializer(diag)
		return Response(serializer.data)


class SyncQueueViewSet(BaseRelaisViewSet):
	serializer_class = SyncQueueSerializer

	def get_queryset(self):
		return SyncQueue.objects.order_by('-date')


@extend_schema(
	request=TriageRequestSerializer,
	responses={200: TriageResponseSerializer},
	summary="Triage bloc",
	description="Calcul immédiat des hypothèses à partir du paquet de symptômes. Option save=true pour stocker la session.")
class TriageAPIView(generics.GenericAPIView):
	serializer_class = TriageRequestSerializer

	def post(self, request):
		ser = self.get_serializer(data=request.data)
		ser.is_valid(raise_exception=True)
		data = ser.validated_data
		symptoms = data.get('symptomes', {})
		if not isinstance(symptoms, dict):
			return Response({'detail': 'symptomes doit être un objet'}, status=400)
		poids_val = data.get('poids')
		rdt_result = data.get('rdt_result')
		result = triage(symptoms, poids=poids_val, rdt_result=rdt_result)
		if data.get('save'):
			session = TriageSession.objects.create(
				patient_id=data.get('patient'),
				relais_id=data.get('relais'),
				symptomes=symptoms,
				engine_output=result,
				rdt_result=rdt_result,
				poids_utilise=poids_val,
			)
			result['session_id'] = session.id
		return Response(result, status=200)


class TriageSessionViewSet(BaseRelaisViewSet):
	serializer_class = TriageSessionSerializer

	def get_queryset(self):
		return TriageSession.objects.order_by('-created_at')


@extend_schema(
	request=InteractiveStartSerializer,
	responses={201: InteractiveStartResponseSerializer},
	summary="Démarrer triage interactif",
	description="Crée une session et retourne la première question.")
class InteractiveTriageStartAPIView(generics.GenericAPIView):
	serializer_class = InteractiveStartSerializer

	def post(self, request):
		ser = self.get_serializer(data=request.data)
		ser.is_valid(raise_exception=True)
		data = ser.validated_data
		session = TriageSession.objects.create(
			patient_id=data.get('patient'),
			relais_id=data.get('relais'),
			symptomes={},
			engine_output={},
			rdt_result=data.get('rdt_result'),
			poids_utilise=data.get('poids'),
			answered={},
		)
		first_q = next_question(session.answered)
		return Response({"session_id": session.id, "question": first_q}, status=201)


@extend_schema(
	request=InteractiveAnswerSerializer,
	responses={200: InteractiveAnswerFinalResponseSerializer},
	summary="Répondre à une question",
	description="Enregistre une réponse et renvoie la suivante ou le diagnostic final.")
class InteractiveTriageAnswerAPIView(generics.GenericAPIView):
	serializer_class = InteractiveAnswerSerializer

	def post(self, request, session_id: int):
		ser = self.get_serializer(data=request.data)
		ser.is_valid(raise_exception=True)
		data = ser.validated_data
		try:
			session = TriageSession.objects.get(id=session_id)
		except TriageSession.DoesNotExist:
			return Response({'detail': 'Session introuvable'}, status=404)

		if session.completed:
			return Response({'detail': 'Session déjà terminée', 'final_output': session.final_output}, status=200)

		question = data.get('question')
		raw_value = data.get('value')
		if question is None:
			return Response({'detail': 'question requise'}, status=400)

		# Validation & conversion des types attendus
		QUESTION_TYPES = {
			'fievre': 'bool',
			'frissons': 'bool',
			'temperature': 'number',
			'duree_fievre_jours': 'number',
			'convulsions': 'bool',
			'prostration': 'bool',
			'incapacite_a_manger': 'bool',
			'toux': 'bool',
			'diarrhee': 'bool',
			'vomissements': 'bool',
			'paludisme_recent': 'bool',
		}

		expected_type = QUESTION_TYPES.get(question)
		if expected_type is None:
			return Response({'detail': f'Question inconnue: {question}'}, status=400)

		def to_bool(v):
			if isinstance(v, bool):
				return v
			if isinstance(v, str):
				if v.lower() in ['true','1','oui','vrai','yes','y']:
					return True
				if v.lower() in ['false','0','non','faux','no','n']:
					return False
			if isinstance(v, (int, float)):
				return bool(v)
			raise ValueError('Valeur bool invalide')

		def to_number(v):
			if isinstance(v, (int,float)):
				return float(v)
			if isinstance(v, str):
				return float(v.replace(',', '.'))
			raise ValueError('Valeur numérique invalide')

		try:
			if expected_type == 'bool':
				value = to_bool(raw_value)
			else:
				value = to_number(raw_value)
		except ValueError as e:
			return Response({'detail': str(e)}, status=400)

		# Enregistrer la réponse
		answered = session.answered or {}
		answered[question] = value
		session.answered = answered

		# Mettre à jour le snapshot des symptômes (symptômes cumulés)
		symptomes = session.symptomes or {}
		symptomes[question] = value
		session.symptomes = symptomes

		# Vérifier la complétion
		completed_flag = is_completed(answered)
		session.completed = completed_flag

		if completed_flag:
			result = triage(symptomes, poids=session.poids_utilise, rdt_result=session.rdt_result)
			session.engine_output = result
			session.final_output = result
			session.save()

			# Auto création DiagnosticPaludisme si palu suspecté
			hypotheses = result.get('hypotheses', [])
			top_code = hypotheses[0]['code'] if hypotheses else None
			if top_code in ['PALU_SIMPLE','PALU_GRAVE']:
				classification = 'GRAVE' if (top_code == 'PALU_GRAVE' or result.get('danger_signs')) else 'SIMPLE'
				try:
					DiagnosticPaludisme.objects.create(
						patient=session.patient,
						relais=session.relais,
						symptomes=session.symptomes,
						test_type='RDT' if session.rdt_result else 'NONE',
						test_result=session.rdt_result,
						classification=classification,
						danger_signs={'signs': result.get('danger_signs', [])},
						recommendation=result.get('recommendation'),
						protocol_version='v1',
					)
				except Exception as diag_err:
					# On retourne quand même le résultat, mais avec info erreur diag
					return Response({
						'completed': True,
						'final_output': result,
						'session_id': session.id,
						'diagnostic_created': False,
						'diagnostic_error': str(diag_err),
					}, status=200)
				return Response({
					'completed': True,
					'final_output': result,
					'session_id': session.id,
					'diagnostic_created': True,
				}, status=200)

			return Response({
				'completed': True,
				'final_output': result,
				'session_id': session.id,
				'diagnostic_created': False,
			}, status=200)
		else:
			# aperçu des hypothèses provisoires
			preview = triage(symptomes, poids=session.poids_utilise, rdt_result=session.rdt_result)
			session.engine_output = preview
			next_q = next_question(answered)
			session.save()
			return Response({
				'completed': False,
				'next_question': next_q,
				'preview_hypotheses': preview.get('hypotheses'),
				'danger_signs': preview.get('danger_signs'),
				'session_id': session.id
			}, status=200)



@extend_schema(
	request=SyncBatchRequestSerializer,
	responses={200: SyncBatchResponseSerializer},
	summary="Batch sync commit",
	description="Apply a batch of client-side operations (CREATE/UPDATE/DELETE). Returns per-item results and server_id mappings for created objects.")
class SyncCommitAPIView(views.APIView):
	"""Accepte une liste d'opérations et les applique transactionnellement lorsque cela est possible.

	Client payload example:
	{
	  "operations": [
		 {"client_id": "tmp-1", "model": "Patient", "operation": "CREATE", "data": {...}},
		 {"client_id": "tmp-2", "model": "DiagnosticPaludisme", "operation": "CREATE", "data": {...}}
	  ]
	}
	"""

	def post(self, request):
		serializer = SyncBatchRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		ops = serializer.validated_data['operations']

		results = []

		# Essayez d'appliquer toutes les opérations dans une transaction de base de données pour maintenir l'atomicité autant que possible
		with transaction.atomic():
			for op in ops:
				client_id = op.get('client_id')
				model_name = op.get('model')
				operation = op.get('operation')
				data = op.get('data')
				idemp = op.get('idempotency_key')

				res = {'client_id': client_id, 'status': 'error'}

				try:
					if model_name == 'Patient':
						if operation == 'CREATE':
							# validate relais existence via serializer
							ser = PatientSerializer(data=data)
							ser.is_valid(raise_exception=True)
							obj = ser.save()
							SyncQueue.objects.create(model_name='Patient', object_id=str(obj.id), operation='CREATE', data=data, synced=True)
							res.update({'status': 'ok', 'server_id': obj.id})
						elif operation == 'UPDATE':
							obj = Patient.objects.get(id=data.get('id'))
							ser = PatientSerializer(obj, data=data, partial=True)
							ser.is_valid(raise_exception=True)
							ser.save()
							SyncQueue.objects.create(model_name='Patient', object_id=str(obj.id), operation='UPDATE', data=data, synced=True)
							res.update({'status': 'ok', 'server_id': obj.id})
						elif operation == 'DELETE':
							obj = Patient.objects.get(id=data.get('id'))
							obj.delete()
							SyncQueue.objects.create(model_name='Patient', object_id=str(data.get('id')), operation='DELETE', data=data, synced=True)
							res.update({'status': 'ok'})
						else:
							res.update({'error': 'Unknown operation'})

					elif model_name == 'DiagnosticPaludisme':
						if operation == 'CREATE':
							ser = DiagnosticPaludismeSerializer(data=data)
							ser.is_valid(raise_exception=True)
							obj = ser.save()
							SyncQueue.objects.create(model_name='DiagnosticPaludisme', object_id=str(obj.id), operation='CREATE', data=data, synced=True)
							res.update({'status': 'ok', 'server_id': obj.id})
						else:
							res.update({'error': 'Only CREATE supported for DiagnosticPaludisme in batch'})

					elif model_name == 'TriageSession':
						if operation == 'CREATE':
							ser = TriageSessionSerializer(data=data)
							ser.is_valid(raise_exception=True)
							obj = ser.save()
							SyncQueue.objects.create(model_name='TriageSession', object_id=str(obj.id), operation='CREATE', data=data, synced=True)
							res.update({'status': 'ok', 'server_id': obj.id})
						elif operation == 'UPDATE':
							obj = TriageSession.objects.get(id=data.get('id'))
							ser = TriageSessionSerializer(obj, data=data, partial=True)
							ser.is_valid(raise_exception=True)
							ser.save()
							SyncQueue.objects.create(model_name='TriageSession', object_id=str(obj.id), operation='UPDATE', data=data, synced=True)
							res.update({'status': 'ok', 'server_id': obj.id})
						else:
							res.update({'error': 'Unsupported operation for TriageSession'})

					else:
						res.update({'error': f'Unsupported model: {model_name}'})

				except Exception as e:
					# enregistrer l'échec dans SyncQueue pour le débogage
					SyncQueue.objects.create(model_name=model_name, object_id=str(data.get('id') or ''), operation=operation, data=data, synced=False)
					res.update({'status': 'error', 'error': str(e)})

				results.append(res)

		return Response({'results': results}, status=200)

