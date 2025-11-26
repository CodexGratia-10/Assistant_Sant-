from django.urls import include, path
from rest_framework.routers import DefaultRouter
from drf_spectacular.views import SpectacularSwaggerView, SpectacularRedocView
from .views import PatientViewSet,BaseRelaisViewSet, DiagnosticPaludismeViewSet, TriageSessionViewSet, TriageAPIView, InteractiveTriageStartAPIView, InteractiveTriageAnswerAPIView, SyncCommitAPIView

router = DefaultRouter()
router.register(r'patients', PatientViewSet, basename='patient' )
router.register(r'relais', BaseRelaisViewSet, basename='relais')
router.register(r'diagnostics', DiagnosticPaludismeViewSet, basename='diagnosticpaludisme')
router.register(r'triages', TriageSessionViewSet, basename='triagesession')

urlpatterns = [
    path('', include(router.urls)),
    path('triage/', TriageAPIView.as_view(), name='triage'),
	path('triage/start/', InteractiveTriageStartAPIView.as_view(), name='triage-start'),
	path('triage/<int:session_id>/answer/', InteractiveTriageAnswerAPIView.as_view(), name='triage-answer'),
	path('sync/commit/', SyncCommitAPIView.as_view(), name='sync-commit'),
    path('schema/swagger-ui/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),  # root -> docs
    path('redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]