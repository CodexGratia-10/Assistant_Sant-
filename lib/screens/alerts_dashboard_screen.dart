import 'package:flutter/material.dart';
import '../data/models/alert.dart';
import '../data/dao/tracking_dao.dart';

class AlertsDashboardScreen extends StatefulWidget {
  final String patientId;

  const AlertsDashboardScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<AlertsDashboardScreen> createState() => _AlertsDashboardScreenState();
}

class _AlertsDashboardScreenState extends State<AlertsDashboardScreen> {
  final AlertDao _alertDao = AlertDao();

  List<Alert> _alerts = [];
  bool _loading = true;
  String _filter = 'all'; // all, urgent, pregnancy, vaccination, followup

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);

    if (_filter == 'all') {
      _alerts = await _alertDao.getPendingAlerts(widget.patientId);
    } else {
      _alerts = await _alertDao.getUpcomingAlerts(widget.patientId, _filter);
    }

    // Trier par urgence et date
    _alerts.sort((a, b) {
      if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
      return a.targetDate.compareTo(b.targetDate);
    });

    setState(() => _loading = false);
  }

  Future<void> _acknowledgeAlert(Alert alert) async {
    alert.status = 'acknowledged';
    await _alertDao.update(alert);
    _loadAlerts();
  }

  Future<void> _dismissAlert(Alert alert) async {
    alert.status = 'dismissed';
    await _alertDao.update(alert);
    _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final urgentCount = _alerts.where((a) => a.isUrgent).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alertes (${_alerts.length})'),
        backgroundColor: urgentCount > 0 ? Colors.red : null,
        actions: [
          if (urgentCount > 0)
            Chip(
              label: Text('$urgentCount urgentes', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _alerts.isEmpty
                    ? _buildEmptyState()
                    : _buildAlertsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('Toutes'),
            selected: _filter == 'all',
            onSelected: (_) => setState(() {
              _filter = 'all';
              _loadAlerts();
            }),
          ),
          FilterChip(
            label: const Text('Urgentes'),
            selected: _filter == 'urgent',
            onSelected: (_) => setState(() {
              _filter = 'urgent';
              _loadAlerts();
            }),
          ),
          FilterChip(
            label: const Text('Grossesse'),
            selected: _filter == 'pregnancy',
            onSelected: (_) => setState(() {
              _filter = 'pregnancy';
              _loadAlerts();
            }),
          ),
          FilterChip(
            label: const Text('Vaccination'),
            selected: _filter == 'vaccination',
            onSelected: (_) => setState(() {
              _filter = 'vaccination';
              _loadAlerts();
            }),
          ),
          FilterChip(
            label: const Text('Suivi'),
            selected: _filter == 'followup',
            onSelected: (_) => setState(() {
              _filter = 'followup';
              _loadAlerts();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucune alerte',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      itemCount: _alerts.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final isUrgent = alert.isUrgent;
    final daysUntil = alert.targetDate.difference(DateTime.now()).inDays;

    IconData icon;
    Color iconColor;

    switch (alert.type) {
      case 'pregnancy':
        icon = Icons.pregnant_woman;
        iconColor = Colors.purple;
        break;
      case 'vaccination':
        icon = Icons.vaccines;
        iconColor = Colors.blue;
        break;
      case 'followup':
        icon = Icons.follow_the_signs;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notification_important;
        iconColor = Colors.grey;
    }

    if (isUrgent) iconColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isUrgent ? Colors.red.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          alert.message,
          style: TextStyle(
            fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTargetDate(daysUntil, alert.targetDate)),
            if (isUrgent)
              const Text(
                '⚠️ URGENT - À traiter immédiatement',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'acknowledge',
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Traité'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'dismiss',
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Ignorer'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'acknowledge') {
              _acknowledgeAlert(alert);
            } else if (value == 'dismiss') {
              _dismissAlert(alert);
            }
          },
        ),
      ),
    );
  }

  String _formatTargetDate(int daysUntil, DateTime targetDate) {
    final dateStr = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

    if (daysUntil < 0) {
      return 'EN RETARD de ${-daysUntil} jour(s) - Prévu: $dateStr';
    } else if (daysUntil == 0) {
      return "AUJOURD'HUI - $dateStr";
    } else if (daysUntil == 1) {
      return 'DEMAIN - $dateStr';
    } else if (daysUntil <= 7) {
      return 'Dans $daysUntil jours - $dateStr';
    } else {
      return 'Prévu: $dateStr';
    }
  }
}
