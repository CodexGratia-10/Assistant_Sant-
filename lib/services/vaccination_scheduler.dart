import 'package:uuid/uuid.dart';
import '../data/models/vaccination.dart';
import '../data/models/alert.dart';
import '../data/dao/tracking_dao.dart';

class VaccinationScheduler {
  final VaccinationDao _vaccinationDao = VaccinationDao();
  final AlertDao _alertDao = AlertDao();

  // Calendrier vaccinal Bénin (PEV - Programme Élargi de Vaccination)
  static List<Map<String, dynamic>> getSchedule(DateTime birthDate) {
    return [
      {'code': 'BCG', 'name': 'BCG', 'daysAfterBirth': 0},
      {'code': 'POLIO_0', 'name': 'Polio 0', 'daysAfterBirth': 0},
      {'code': 'PENTA_1', 'name': 'Pentavalent 1', 'daysAfterBirth': 42}, // 6 semaines
      {'code': 'POLIO_1', 'name': 'Polio 1', 'daysAfterBirth': 42},
      {'code': 'PNEUMO_1', 'name': 'Pneumocoque 1', 'daysAfterBirth': 42},
      {'code': 'ROTA_1', 'name': 'Rotavirus 1', 'daysAfterBirth': 42},
      {'code': 'PENTA_2', 'name': 'Pentavalent 2', 'daysAfterBirth': 70}, // 10 semaines
      {'code': 'POLIO_2', 'name': 'Polio 2', 'daysAfterBirth': 70},
      {'code': 'PNEUMO_2', 'name': 'Pneumocoque 2', 'daysAfterBirth': 70},
      {'code': 'ROTA_2', 'name': 'Rotavirus 2', 'daysAfterBirth': 70},
      {'code': 'PENTA_3', 'name': 'Pentavalent 3', 'daysAfterBirth': 98}, // 14 semaines
      {'code': 'POLIO_3', 'name': 'Polio 3', 'daysAfterBirth': 98},
      {'code': 'PNEUMO_3', 'name': 'Pneumocoque 3', 'daysAfterBirth': 98},
      {'code': 'IPV', 'name': 'Polio injectable', 'daysAfterBirth': 98},
      {'code': 'MEASLES_1', 'name': 'Rougeole 1', 'daysAfterBirth': 270}, // 9 mois
      {'code': 'YELLOW_FEVER', 'name': 'Fièvre jaune', 'daysAfterBirth': 270},
      {'code': 'MEASLES_2', 'name': 'Rougeole 2', 'daysAfterBirth': 450}, // 15 mois
    ];
  }

  Future<List<Vaccination>> createVaccinationSchedule(String patientId, DateTime birthDate) async {
    final schedule = getSchedule(birthDate);
    final vaccinations = <Vaccination>[];

    for (final vaccine in schedule) {
      final dueDate = birthDate.add(Duration(days: vaccine['daysAfterBirth'] as int));
      
      final vaccination = Vaccination(
        id: const Uuid().v4(),
        patientId: patientId,
        vaccineCode: vaccine['code'] as String,
        vaccineName: vaccine['name'] as String,
        dueDate: dueDate,
        status: 'scheduled',
      );

      await _vaccinationDao.insert(vaccination);
      vaccinations.add(vaccination);

      // Créer une alerte 7 jours avant
      final alertDate = dueDate.subtract(const Duration(days: 7));
      if (alertDate.isAfter(DateTime.now())) {
        final alert = Alert(
          id: const Uuid().v4(),
          patientId: patientId,
          type: 'vaccination',
          code: 'VACCINE_DUE_${vaccine['code']}',
          message: 'Vaccin ${vaccine['name']} prévu le ${_formatDate(dueDate)}',
          targetDate: alertDate,
          status: 'pending',
          createdAt: DateTime.now(),
        );
        await _alertDao.insert(alert);
      }
    }
    
    return vaccinations;
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> markVaccineAdministered(String vaccinationId) async {
    final vaccinations = await _vaccinationDao.getPending();
    final vaccination = vaccinations.firstWhere((v) => v.id == vaccinationId);
    
    vaccination.administeredDate = DateTime.now();
    vaccination.status = 'administered';

    await _vaccinationDao.update(vaccination);
  }
}
