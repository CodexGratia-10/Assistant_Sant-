import 'package:uuid/uuid.dart';
import '../data/models/pregnancy.dart';
import '../data/models/alert.dart';
import '../data/dao/tracking_dao.dart';

class PregnancyTracker {
  final PregnancyDao _pregnancyDao = PregnancyDao();
  final AlertDao _alertDao = AlertDao();

  // Calendrier CPN (Consultations Prénatales) - OMS/Bénin
  static List<Map<String, dynamic>> getPNCSchedule(DateTime lmpDate) {
    final schedules = [
      {'visit': 'CPN1', 'name': 'Consultation 1', 'weeks': 12},
      {'visit': 'CPN2', 'name': 'Consultation 2', 'weeks': 20},
      {'visit': 'CPN3', 'name': 'Consultation 3', 'weeks': 26},
      {'visit': 'CPN4', 'name': 'Consultation 4', 'weeks': 30},
      {'visit': 'CPN5', 'name': 'Consultation 5', 'weeks': 34},
      {'visit': 'CPN6', 'name': 'Consultation 6', 'weeks': 36},
      {'visit': 'CPN7', 'name': 'Consultation 7', 'weeks': 38},
      {'visit': 'CPN8', 'name': 'Consultation 8', 'weeks': 40},
    ];

    return schedules.map((s) {
      final date = lmpDate.add(Duration(days: (s['weeks'] as int) * 7));
      return {
        'visit': s['visit'],
        'name': s['name'],
        'dueDate': date,
      };
    }).toList();
  }

  Future<void> createPregnancyTracking(
    String patientId,
    DateTime lmpDate, {
    String riskLevel = 'normal',
  }) async {
    // Create pregnancy record
    final pregnancy = Pregnancy(
      id: const Uuid().v4(),
      patientId: patientId,
      lastMenstrualPeriod: lmpDate,
      riskLevel: riskLevel,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _pregnancyDao.insert(pregnancy);

    // Create PNC alerts
    final schedule = getPNCSchedule(lmpDate);
      for (final visit in schedule) {
        final week = visit['weeks'] as int;
        final dueDate = visit['dueDate'] as DateTime;
        // Only schedule future visits
        if (dueDate.isAfter(DateTime.now())) {
          final alert = Alert(
            id: const Uuid().v4(),
            patientId: patientId,
            type: 'pregnancy',
            code: 'PNC_VISIT_$week',
            targetDate: dueDate,
            status: 'pending',
            createdAt: DateTime.now(),
            message: 'Visite CPN prévue à ${week} SA',
          );
          await _alertDao.insert(alert);
        }
      }
  }

  Future<Map<String, dynamic>> getPregnancyStatus(String patientId) async {
    final currentPregnancy = await _pregnancyDao.getCurrentPregnancy(patientId);
    if (currentPregnancy == null) return {};

    final weeks = currentPregnancy.weeksPregnant;
    final dueDate = currentPregnancy.estimatedDueDate;
    final trimester = weeks != null && weeks > 0
        ? (weeks <= 13 ? 1 : (weeks <= 27 ? 2 : 3))
        : null;

    return {
      'pregnancy': currentPregnancy,
      'weeksPregnant': weeks,
      'dueDate': dueDate,
      'trimester': trimester,
      'riskLevel': currentPregnancy.riskLevel,
    };
  }
}
