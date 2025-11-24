import 'package:flutter/material.dart';
import '../data/dao/tracking_dao.dart';
import '../data/dao/patient_dao.dart';
import '../data/models/alert.dart';
import '../data/models/patient.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AlertDao _alertDao = AlertDao();
  final PatientDao _patientDao = PatientDao();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final allAlerts = await _alertDao.getAll();
    final alertsWithPatients = <Map<String, dynamic>>[];

    for (final alert in allAlerts) {
      if (alert.status == 'pending') {
        Patient? patient;
        if (alert.patientId != null) {
          patient = await _patientDao.getById(alert.patientId!);
        }
        alertsWithPatients.add({'alert': alert, 'patient': patient});
      }
    }

    // Trier par date cible
    alertsWithPatients.sort((a, b) {
      final alertA = a['alert'] as Alert;
      final alertB = b['alert'] as Alert;
      return alertA.targetDate.compareTo(alertB.targetDate);
    });

    setState(() {
      _alerts = alertsWithPatients;
      _isLoading = false;
    });
  }

  Future<void> _markAsAcknowledged(Alert alert) async {
    final updated = Alert(
      id: alert.id,
      patientId: alert.patientId,
      type: alert.type,
      code: alert.code,
      targetDate: alert.targetDate,
      status: 'acknowledged',
      createdAt: alert.createdAt,
      message: alert.message,
    );
    await _alertDao.update(updated);
    _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes & Rappels'),
        backgroundColor: Colors.red.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Aucune alerte en attente', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index]['alert'] as Alert;
                    final patient = _alerts[index]['patient'] as Patient?;
                    return _buildAlertCard(alert, patient);
                  },
                ),
    );
  }

  Widget _buildAlertCard(Alert alert, Patient? patient) {
    final isOverdue = alert.targetDate.isBefore(DateTime.now());
    final isUrgent = alert.targetDate.difference(DateTime.now()).inDays <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isOverdue ? Colors.red.shade50 : (isUrgent ? Colors.orange.shade50 : null),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getAlertTypeColor(alert.type),
                  child: Icon(_getAlertTypeIcon(alert.type), color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.message,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (patient != null)
                        Text(
                          'Patient ${patient.id.substring(0, 8)} - ${patient.yearOfBirth ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date prévue', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(alert.targetDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _markAsAcknowledged(alert),
                  icon: const Icon(Icons.check),
                  label: const Text('Traité'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (isOverdue)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('En retard', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            else if (isUrgent)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Bientôt', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getAlertTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return Colors.orange;
      case 'pregnancy':
        return Colors.pink;
      case 'followup':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return Icons.vaccines;
      case 'pregnancy':
        return Icons.pregnant_woman;
      case 'followup':
        return Icons.medical_services;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
