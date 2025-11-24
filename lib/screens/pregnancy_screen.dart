import 'package:flutter/material.dart';
import '../data/dao/tracking_dao.dart';
import '../data/dao/patient_dao.dart';
import '../data/models/pregnancy.dart';
import '../data/models/patient.dart';
import '../services/pregnancy_tracker.dart';

class PregnancyScreen extends StatefulWidget {
  const PregnancyScreen({super.key});

  @override
  State<PregnancyScreen> createState() => _PregnancyScreenState();
}

class _PregnancyScreenState extends State<PregnancyScreen> {
  final PregnancyDao _pregnancyDao = PregnancyDao();
  final PatientDao _patientDao = PatientDao();
  List<Map<String, dynamic>> _activePregnancies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivePregnancies();
  }

  Future<void> _loadActivePregnancies() async {
    setState(() => _isLoading = true);
    final allPregnancies = await _pregnancyDao.getAll();
    final active = <Map<String, dynamic>>[];

    for (final pregnancy in allPregnancies) {
      if (pregnancy.status == 'active') {
        final patient = await _patientDao.getById(pregnancy.patientId);
        if (patient != null) {
          active.add({'pregnancy': pregnancy, 'patient': patient});
        }
      }
    }

    setState(() {
      _activePregnancies = active;
      _isLoading = false;
    });
  }

  Future<void> _addNewPregnancy() async {
    final patients = await _patientDao.getAll();
    final femalePatients = patients.where((p) => p.sex == 'F').toList();

    if (!mounted) return;

    if (femalePatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune patiente enregistrée')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _NewPregnancyDialog(patients: femalePatients),
    );

    if (result != null) {
      final tracker = PregnancyTracker();
      await tracker.createPregnancyTracking(
        result['patientId'],
        result['lmpDate'],
        riskLevel: result['riskLevel'] ?? 'normal',
      );
      _loadActivePregnancies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi Grossesse'),
        backgroundColor: Colors.pink.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activePregnancies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pregnant_woman, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Aucune grossesse active', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _activePregnancies.length,
                  itemBuilder: (context, index) {
                    final pregnancy = _activePregnancies[index]['pregnancy'] as Pregnancy;
                    final patient = _activePregnancies[index]['patient'] as Patient;
                    return _buildPregnancyCard(pregnancy, patient);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPregnancy,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Grossesse'),
        backgroundColor: Colors.pink,
      ),
    );
  }

  Widget _buildPregnancyCard(Pregnancy pregnancy, Patient patient) {
    final weeks = pregnancy.weeksPregnant ?? 0;
    final trimester = pregnancy.trimester ?? 1;
    final dueDate = pregnancy.estimatedDueDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.pink,
                  child: const Icon(Icons.pregnant_woman, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patiente ${patient.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('Année: ${patient.yearOfBirth ?? 'N/A'}'),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('Semaines', '$weeks SA', Colors.pink),
                _buildInfoColumn('Trimestre', '$trimester', Colors.purple),
                _buildInfoColumn(
                  'Terme',
                  dueDate != null ? _formatDate(dueDate) : '-',
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRiskColor(pregnancy.riskLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getRiskIcon(pregnancy.riskLevel), color: _getRiskColor(pregnancy.riskLevel)),
                  const SizedBox(width: 8),
                  Text(
                    'Risque: ${pregnancy.riskLevel}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRiskColor(pregnancy.riskLevel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'normal':
      default:
        return Colors.green;
    }
  }

  IconData _getRiskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'normal':
      default:
        return Icons.check_circle;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NewPregnancyDialog extends StatefulWidget {
  final List<Patient> patients;

  const _NewPregnancyDialog({required this.patients});

  @override
  State<_NewPregnancyDialog> createState() => _NewPregnancyDialogState();
}

class _NewPregnancyDialogState extends State<_NewPregnancyDialog> {
  String? _selectedPatientId;
  DateTime? _lmpDate;
  String _riskLevel = 'normal';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle Grossesse'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Patiente'),
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
            title: const Text('Date dernières règles'),
            subtitle: Text(_lmpDate != null
                ? '${_lmpDate!.day}/${_lmpDate!.month}/${_lmpDate!.year}'
                : 'Non définie'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 30)),
                firstDate: DateTime.now().subtract(const Duration(days: 280)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _lmpDate = date);
              }
            },
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Niveau de risque'),
            value: _riskLevel,
            items: const [
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'high', child: Text('Élevé')),
            ],
            onChanged: (val) => setState(() => _riskLevel = val ?? 'normal'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedPatientId != null && _lmpDate != null
              ? () {
                  Navigator.pop(context, {
                    'patientId': _selectedPatientId,
                    'lmpDate': _lmpDate,
                    'riskLevel': _riskLevel,
                  });
                }
              : null,
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
