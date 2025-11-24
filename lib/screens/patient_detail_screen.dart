import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/patient.dart';
import '../data/models/visit.dart';
import '../data/dao/patient_dao.dart';
import '../data/dao/visit_dao.dart';
import 'diagnosis_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final PatientDao _patientDao = PatientDao();
  final VisitDao _visitDao = VisitDao();
  Patient? _patient;
  List<Visit> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final patient = await _patientDao.getById(widget.patientId);
    final visits = await _visitDao.getByPatientId(widget.patientId);
    setState(() {
      _patient = patient;
      _visits = visits;
      _isLoading = false;
    });
  }

  Future<void> _startNewConsultation() async {
    final visit = Visit(
      id: const Uuid().v4(),
      patientId: widget.patientId,
      visitType: 'consultation',
      startedAt: DateTime.now(),
    );
    await _visitDao.insert(visit);

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiagnosisScreen(
          patientId: widget.patientId,
          visitId: visit.id,
        ),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Patient ${_patient!.id.substring(0, 8)}'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _patient!.sex == 'M' ? Colors.blue : Colors.pink,
                        child: Icon(
                          _patient!.sex == 'M' ? Icons.male : Icons.female,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${_patient!.id.substring(0, 13)}...', style: const TextStyle(fontSize: 12)),
                          Text('Sexe: ${_patient!.sex ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                          Text('Année: ${_patient!.yearOfBirth ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Consultations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_visits.length}', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _visits.isEmpty
                ? Center(
                    child: Text('Aucune consultation', style: TextStyle(color: Colors.grey.shade600)),
                  )
                : ListView.builder(
                    itemCount: _visits.length,
                    itemBuilder: (context, index) {
                      final visit = _visits[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            visit.referralFlag ? Icons.local_hospital : Icons.assignment,
                            color: visit.referralFlag ? Colors.red : Colors.green,
                          ),
                          title: Text('Consultation - ${visit.visitType ?? 'N/A'}'),
                          subtitle: Text(_formatDate(visit.startedAt)),
                          trailing: visit.outcome != null
                              ? Chip(
                                  label: Text(visit.outcome!, style: const TextStyle(fontSize: 12)),
                                  backgroundColor: visit.referralFlag ? Colors.red.shade100 : Colors.green.shade100,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewConsultation,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Consultation'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
