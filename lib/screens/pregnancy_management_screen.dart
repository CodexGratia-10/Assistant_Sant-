import 'package:flutter/material.dart';
import '../data/models/pregnancy.dart';
import '../data/models/alert.dart';
import '../data/dao/tracking_dao.dart';
import '../services/pregnancy_tracker.dart';

class PregnancyManagementScreen extends StatefulWidget {
  final String patientId;

  const PregnancyManagementScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<PregnancyManagementScreen> createState() => _PregnancyManagementScreenState();
}

class _PregnancyManagementScreenState extends State<PregnancyManagementScreen> {
  final PregnancyDao _dao = PregnancyDao();
  final AlertDao _alertDao = AlertDao();
  final PregnancyTracker _tracker = PregnancyTracker();

  Pregnancy? _currentPregnancy;
  List<Alert> _upcomingVisits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    _currentPregnancy = await _dao.getCurrentPregnancy(widget.patientId);

    if (_currentPregnancy != null) {
      _upcomingVisits = await _alertDao.getUpcomingAlerts(widget.patientId, 'pregnancy');
    }

    setState(() => _loading = false);
  }

  Future<void> _createPregnancy() async {
    final lmpDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 60)),
      firstDate: DateTime.now().subtract(const Duration(days: 280)),
      lastDate: DateTime.now(),
      helpText: 'Date des dernières règles (DDR)',
    );

    if (lmpDate == null) return;

    await _tracker.createPregnancyTracking(widget.patientId, lmpDate);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grossesse enregistrée. 8 visites programmées.')),
    );

    _loadData();
  }

  Future<void> _markVisitCompleted(Alert alert) async {
    alert.status = 'acknowledged';
    await _alertDao.update(alert);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi de Grossesse')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de Grossesse'),
        actions: [
          if (_currentPregnancy == null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createPregnancy,
              tooltip: 'Enregistrer nouvelle grossesse',
            ),
        ],
      ),
      body: _currentPregnancy == null
          ? _buildNoPregnancy()
          : _buildCurrentPregnancy(),
    );
  }

  Widget _buildNoPregnancy() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pregnant_woman, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Aucune grossesse active', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createPregnancy,
            icon: const Icon(Icons.add),
            label: const Text('Enregistrer une grossesse'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPregnancy() {
    final p = _currentPregnancy!;
    final weeksPregnant = p.weeksPregnant;
    final trimester = p.trimester;
    final dueDate = p.estimatedDueDate;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.pink.shade50,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rappel', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Les dates CPN sont calculées automatiquement à partir de la date des dernières règles (DDR) que vous avez saisie.',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                const SizedBox(height: 4),
                if (p.lastMenstrualPeriod != null)
                  Text(
                    'DDR: ${_formatDate(p.lastMenstrualPeriod!)} – Terme estimé: ${dueDate != null ? _formatDate(dueDate) : '-'}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pregnant_woman,
                      size: 48,
                      color: p.riskLevel == 'high' ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$weeksPregnant semaines',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Trimestre $trimester',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'DDR',
                  p.lastMenstrualPeriod != null
                      ? _formatDate(p.lastMenstrualPeriod!)
                      : '-',
                ),
                _buildInfoRow(
                  'Terme estimé',
                  dueDate != null ? _formatDate(dueDate) : '-',
                ),
                _buildInfoRow('Niveau de risque', _translateRisk(p.riskLevel)),
                if (p.notes != null && p.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Notes: ${p.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Visites CPN à venir',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ..._upcomingVisits.map((alert) => _buildVisitCard(alert)),
        if (_upcomingVisits.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Toutes les visites ont été effectuées ou sont déjà passées.'),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildVisitCard(Alert alert) {
    final isUrgent = alert.isUrgent;

    return Card(
      color: isUrgent ? Colors.red.shade50 : null,
      child: ListTile(
        leading: Icon(
          Icons.event,
          color: isUrgent ? Colors.red : Colors.blue,
        ),
        title: Text(alert.message),
        subtitle: Text(_formatDate(alert.targetDate)),
        trailing: alert.status == 'pending'
            ? ElevatedButton(
                onPressed: () => _markVisitCompleted(alert),
                child: const Text('Effectuée'),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _translateRisk(String risk) {
    switch (risk) {
      case 'high':
        return 'Élevé';
      case 'normal':
        return 'Normal';
      default:
        return risk;
    }
  }
}
