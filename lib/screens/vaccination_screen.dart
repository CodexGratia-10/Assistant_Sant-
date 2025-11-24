import 'package:flutter/material.dart';
import '../data/dao/tracking_dao.dart';
import '../data/dao/patient_dao.dart';
import '../data/models/vaccination.dart';
import '../data/models/patient.dart';
import '../services/vaccination_scheduler.dart';

class VaccinationScreen extends StatefulWidget {
  const VaccinationScreen({super.key});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  final VaccinationDao _vaccinationDao = VaccinationDao();
  final PatientDao _patientDao = PatientDao();
  List<Map<String, dynamic>> _upcomingVaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingVaccinations();
  }

  Future<void> _loadUpcomingVaccinations() async {
    setState(() => _isLoading = true);
    final pending = await _vaccinationDao.getPending();
    final vaccinations = <Map<String, dynamic>>[];

    for (final vac in pending) {
      final patient = await _patientDao.getById(vac.patientId);
      if (patient != null) {
        vaccinations.add({'vaccination': vac, 'patient': patient});
      }
    }

    // Trier par date
    vaccinations.sort((a, b) {
      final vacA = a['vaccination'] as Vaccination;
      final vacB = b['vaccination'] as Vaccination;
      return vacA.dueDate.compareTo(vacB.dueDate);
    });

    setState(() {
      _upcomingVaccinations = vaccinations;
      _isLoading = false;
    });
  }

  Future<void> _addNewVaccinationSchedule() async {
    final patients = await _patientDao.getAll();

    if (!mounted) return;

    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun patient enregistré')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _NewVaccinationDialog(patients: patients),
    );

    if (result != null) {
      final scheduler = VaccinationScheduler();
      await scheduler.createVaccinationSchedule(
        result['patientId'],
        result['birthDate'],
      );
      _loadUpcomingVaccinations();
    }
  }

  Future<void> _markAsAdministered(Vaccination vac) async {
    final updated = Vaccination(
      id: vac.id,
      patientId: vac.patientId,
      vaccineCode: vac.vaccineCode,
      vaccineName: vac.vaccineName,
      dueDate: vac.dueDate,
      administeredDate: DateTime.now(),
      status: 'done',
    );
    await _vaccinationDao.update(updated);
    _loadUpcomingVaccinations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccination Enfants'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _upcomingVaccinations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vaccines, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Aucune vaccination prévue', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _upcomingVaccinations.length,
                  itemBuilder: (context, index) {
                    final vaccination = _upcomingVaccinations[index]['vaccination'] as Vaccination;
                    final patient = _upcomingVaccinations[index]['patient'] as Patient;
                    return _buildVaccinationCard(vaccination, patient);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewVaccinationSchedule,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Calendrier'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildVaccinationCard(Vaccination vaccination, Patient patient) {
    final isOverdue = vaccination.dueDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isOverdue ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isOverdue ? Colors.red : Colors.orange,
                  child: const Icon(Icons.vaccines, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccination.vaccineName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('Patient ${patient.id.substring(0, 8)} - ${patient.yearOfBirth ?? 'N/A'}'),
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
                      _formatDate(vaccination.dueDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _markAsAdministered(vaccination),
                  icon: const Icon(Icons.check),
                  label: const Text('Administré'),
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
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NewVaccinationDialog extends StatefulWidget {
  final List<Patient> patients;

  const _NewVaccinationDialog({required this.patients});

  @override
  State<_NewVaccinationDialog> createState() => _NewVaccinationDialogState();
}

class _NewVaccinationDialogState extends State<_NewVaccinationDialog> {
  String? _selectedPatientId;
  DateTime? _birthDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau Calendrier Vaccinal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Patient'),
            value: _selectedPatientId,
            items: widget.patients
                .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.id.substring(0, 8)} - ${p.yearOfBirth ?? 'N/A'}'),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedPatientId = val),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date de naissance'),
            subtitle: Text(_birthDate != null
                ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                : 'Non définie'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365)),
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _birthDate = date);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedPatientId != null && _birthDate != null
              ? () {
                  Navigator.pop(context, {
                    'patientId': _selectedPatientId,
                    'birthDate': _birthDate,
                  });
                }
              : null,
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
