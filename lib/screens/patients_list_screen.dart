import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/patient.dart';
import '../data/dao/patient_dao.dart';
import 'patient_detail_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final PatientDao _patientDao = PatientDao();
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    var patients = await _patientDao.getAll();

    // Si aucun patient, en créer quelques-uns pour démarrer la démo
    if (patients.isEmpty) {
      final now = DateTime.now();
      final demoPatients = [
        Patient(id: const Uuid().v4(), sex: 'F', yearOfBirth: now.year - 25, createdAt: now, updatedAt: now),
        Patient(id: const Uuid().v4(), sex: 'M', yearOfBirth: now.year - 4, createdAt: now, updatedAt: now),
        Patient(id: const Uuid().v4(), sex: 'F', yearOfBirth: now.year - 1, createdAt: now, updatedAt: now),
      ];
      for (final p in demoPatients) {
        await _patientDao.insert(p);
      }
      patients = await _patientDao.getAll();
    }
    setState(() {
      _patients = patients;
      _isLoading = false;
    });
  }

  Future<void> _createNewPatient() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _NewPatientDialog(),
    );

    if (result != null) {
      final patient = Patient(
        id: const Uuid().v4(),
        sex: result['sex'],
        yearOfBirth: result['yearOfBirth'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _patientDao.insert(patient);
      _loadPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Aucun patient enregistré', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _patients.length,
                  itemBuilder: (context, index) {
                    final patient = _patients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: patient.sex == 'M' ? Colors.blue : Colors.pink,
                          child: Icon(
                            patient.sex == 'M' ? Icons.male : Icons.female,
                            color: Colors.white,
                          ),
                        ),
                        title: Text('Patient ${patient.id.substring(0, 8)}'),
                        subtitle: Text(
                          'Année: ${patient.yearOfBirth ?? 'N/A'} • ${patient.sex ?? 'N/A'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailScreen(patientId: patient.id),
                            ),
                          );
                          _loadPatients();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPatient,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau Patient'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _NewPatientDialog extends StatefulWidget {
  const _NewPatientDialog();

  @override
  State<_NewPatientDialog> createState() => _NewPatientDialogState();
}

class _NewPatientDialogState extends State<_NewPatientDialog> {
  String? _selectedSex;
  final _yearController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau Patient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Sexe'),
            value: _selectedSex,
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Masculin')),
              DropdownMenuItem(value: 'F', child: Text('Féminin')),
            ],
            onChanged: (val) => setState(() => _selectedSex = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(labelText: 'Année de naissance'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final year = int.tryParse(_yearController.text);
            Navigator.pop(context, {
              'sex': _selectedSex,
              'yearOfBirth': year,
            });
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
