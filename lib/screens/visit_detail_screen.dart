import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/dao/visit_dao.dart';
import '../data/dao/observation_dao.dart';
import '../data/models/visit.dart';
import '../data/models/symptom_observation.dart';
import '../data/models/vital_sign.dart';
import '../data/models/malaria_rdt.dart';

class VisitDetailScreen extends StatefulWidget {
  final String visitId;

  const VisitDetailScreen({super.key, required this.visitId});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final VisitDao _visitDao = VisitDao();
  final ObservationDao _observationDao = ObservationDao();

  Visit? _visit;
  List<VitalSign> _vitals = [];
  List<SymptomObservation> _symptoms = [];
  MalariaRDT? _rdt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await _visitDao.getById(widget.visitId);
    if (v != null) {
      final vit = await _observationDao.getVitalSignsByVisitId(v.id);
      final sym = await _observationDao.getSymptomsByVisitId(v.id);
      final rdt = await _observationDao.getMalariaRDTByVisitId(v.id);
      setState(() {
        _visit = v;
        _vitals = vit;
        _symptoms = sym;
        _rdt = rdt;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    final f = DateFormat('dd/MM/yyyy HH:mm');
    return f.format(dt);
  }

  String _buildTextReport() {
    if (_visit == null) return 'Consultation introuvable';
    final v = _visit!;
    final sb = StringBuffer();

    sb.writeln('Assistant Santé – Consultation');
    sb.writeln('--------------------------------');
    sb.writeln('Visite ID      : ${v.id}');
    sb.writeln('Patient ID     : ${v.patientId}');
    sb.writeln('Type           : ${v.visitType ?? 'consultation'}');
    sb.writeln('Début          : ${_fmtDate(v.startedAt)}');
    sb.writeln('Fin            : ${_fmtDate(v.completedAt)}');
    sb.writeln('Issue          : ${v.outcome ?? 'N/A'}');
    sb.writeln('Référence      : ${v.referralFlag ? 'Oui' : 'Non'}');
    sb.writeln('Sync           : ${v.syncStatus}');
    sb.writeln('');

    sb.writeln('[Signes vitaux]');
    if (_vitals.isEmpty) {
      sb.writeln('- Aucun');
    } else {
      for (final vit in _vitals) {
        sb.writeln('- ${vit.type}: ${vit.value} ${vit.unit} @ ${_fmtDate(vit.capturedAt)}');
      }
    }
    sb.writeln('');

    sb.writeln('[Symptômes]');
    if (_symptoms.isEmpty) {
      sb.writeln('- Aucun');
    } else {
      for (final s in _symptoms) {
        final val = s.value ?? (s.numericValue?.toString() ?? '');
        sb.writeln('- ${s.code}: ${val.isEmpty ? '—' : val} @ ${_fmtDate(s.capturedAt)}');
      }
    }
    sb.writeln('');

    sb.writeln('[RDT Paludisme]');
    if (_rdt == null) {
      sb.writeln('- Non saisi');
    } else {
      sb.writeln('- Effectué : ${_rdt!.performed ? 'Oui' : 'Non'}');
      sb.writeln('- Résultat : ${_rdt!.result ?? '—'}');
      sb.writeln('- Date     : ${_fmtDate(_rdt!.capturedAt)}');
    }

    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail consultation'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _visit == null
              ? const Center(child: Text('Consultation introuvable'))
              : Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _buildTextReport(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
