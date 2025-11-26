"""
URL configuration for Assitant_Sante project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

def home(request):
    return HttpResponse("Bienvenue sur la page d'accueil de votre projet Django")


    # class SpectacularAPIView(View):
    #     def get(self, request, *args, **kwargs):
    #         return HttpResponse(
    #             "Schema generation is unavailable because drf_spectacular is not installed.",
    #             status=501,
    #         )

    # class SpectacularSwaggerView(View):
    #     def get(self, request, *args, **kwargs):
    #         return HttpResponse(
    #             "Swagger UI is unavailable because drf_spectacular is not installed.",
    #             status=501,
    #         )

    # class SpectacularRedocView(View):
    #     def get(self, request, *args, **kwargs):
    #         return HttpResponse(
    #             "Redoc UI is unavailable because drf_spectacular is not installed.",
    #             status=501,
    #         )

urlpatterns = [
    path('', home),  # Route racine avec page d'accueil simple
    path('admin/', admin.site.urls),
    path('schema/', SpectacularAPIView.as_view(), name='schema'),
    path('schema/swagger-ui/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/', include('apps.urls')),  # Vos API ici
    path('redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]
