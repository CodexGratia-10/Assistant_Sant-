import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/dao/tracking_dao.dart';
import '../data/models/alert.dart';

class PregnancyCpnScreen extends StatefulWidget {
  final String patientId;
  const PregnancyCpnScreen({super.key, required this.patientId});

  @override
  State<PregnancyCpnScreen> createState() => _PregnancyCpnScreenState();
}

class _PregnancyCpnScreenState extends State<PregnancyCpnScreen> {
  final AlertDao _alertDao = AlertDao();
  bool _loading = true;
  List<Alert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    try {
      final alerts = await _alertDao.getByPatientId(widget.patientId);
      setState(() {
        _alerts = alerts.where((a) => a.type == 'pregnancy' && a.code.startsWith('CPN_')).toList();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markCpnDone(Alert alert) async {
    await _alertDao.markAcknowledged(alert.id);
    await _loadAlerts();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CPN marquée comme effectuée')));
  }

  Future<void> _scheduleNextCpn({DateTime? base}) async {
    final nextDate = (base ?? DateTime.now()).add(const Duration(days: 28));
    final nextAlert = Alert(
      id: const Uuid().v4(),
      patientId: widget.patientId,
      type: 'pregnancy',
      code: 'CPN_SUIVANTE',
      targetDate: nextDate,
      status: 'pending',
      createdAt: DateTime.now(),
      message: 'Prochaine CPN prévue le ${nextDate.day}/${nextDate.month}/${nextDate.year}',
    );
    await _alertDao.insert(nextAlert);
    await _loadAlerts();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prochaine CPN planifiée')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi Grossesse - CPN')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Agenda des CPN', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _alerts.length,
                      itemBuilder: (ctx, i) {
                        final a = _alerts[i];
                        return Card(
                          child: ListTile(
                            title: Text(a.message.isNotEmpty ? a.message : a.code),
                            subtitle: Text('Échéance: ${a.targetDate.day}/${a.targetDate.month}/${a.targetDate.year} — Statut: ${a.status}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (a.status != 'done')
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    tooltip: 'CPN effectuée',
                                    onPressed: () => _markCpnDone(a),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.schedule),
                                  tooltip: 'Planifier prochaine CPN',
                                  onPressed: () => _scheduleNextCpn(base: a.targetDate),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _scheduleNextCpn(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter CPN (4 semaines)'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  )
                ],
              ),
            ),
    );
  }
}
