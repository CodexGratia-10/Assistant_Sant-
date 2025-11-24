import 'package:flutter/material.dart';
import '../data/models/vaccination.dart';
import '../data/dao/tracking_dao.dart';
import '../services/vaccination_scheduler.dart';

class VaccinationCalendarScreen extends StatefulWidget {
  final String patientId;
  final DateTime birthDate;

  const VaccinationCalendarScreen({
    Key? key,
    required this.patientId,
    required this.birthDate,
  }) : super(key: key);

  @override
  State<VaccinationCalendarScreen> createState() => _VaccinationCalendarScreenState();
}

class _VaccinationCalendarScreenState extends State<VaccinationCalendarScreen> {
  final VaccinationDao _dao = VaccinationDao();
  final VaccinationScheduler _scheduler = VaccinationScheduler();

  List<Vaccination> _vaccinations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVaccinations();
  }

  Future<void> _loadVaccinations() async {
    setState(() => _loading = true);

    _vaccinations = await _dao.getByPatientId(widget.patientId);

    // Si aucune vaccination, générer le calendrier
    if (_vaccinations.isEmpty) {
      _vaccinations = await _scheduler.createVaccinationSchedule(widget.patientId, widget.birthDate);
    }

    // Trier par date
    _vaccinations.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    setState(() => _loading = false);
  }

  Future<void> _markAsAdministered(Vaccination vacc) async {
    await _scheduler.markVaccineAdministered(vacc.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vacc.vaccineName} marqué comme administré')),
    );

    _loadVaccinations();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendrier Vaccinal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final past = _vaccinations.where((v) => v.status == 'administered').toList();
    final upcoming = _vaccinations.where((v) => v.status == 'scheduled').toList();
    final overdue = upcoming.where((v) => v.isOverdue).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier Vaccinal'),
        backgroundColor: overdue.isNotEmpty ? Colors.red : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(past.length, upcoming.length, overdue.length),
          const SizedBox(height: 16),
          if (overdue.isNotEmpty) ...[
            Text(
              '⚠️ Vaccins en retard (${overdue.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ...overdue.map((v) => _buildVaccinationCard(v, isOverdue: true)),
            const SizedBox(height: 16),
          ],
          Text(
            'À venir (${upcoming.length - overdue.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...upcoming.where((v) => !v.isOverdue).map((v) => _buildVaccinationCard(v)),
          const SizedBox(height: 16),
          Text(
            'Administrés (${past.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green),
          ),
          const SizedBox(height: 8),
          ...past.map((v) => _buildVaccinationCard(v, isDone: true)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int done, int upcoming, int overdue) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat('Effectués', done, Colors.green),
            _buildStat('À venir', upcoming, Colors.blue),
            _buildStat('Retard', overdue, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildVaccinationCard(Vaccination vacc, {bool isOverdue = false, bool isDone = false}) {
    final ageInDays = vacc.dueDate.difference(widget.birthDate).inDays;
    final ageText = _getAgeText(ageInDays);

    Color? cardColor;
    if (isOverdue) cardColor = Colors.red.shade50;
    if (isDone) cardColor = Colors.green.shade50;

    return Card(
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue ? Colors.red : (isDone ? Colors.green : Colors.blue),
          child: Icon(
            isDone ? Icons.check : Icons.vaccines,
            color: Colors.white,
          ),
        ),
        title: Text(
          vacc.vaccineName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Âge: $ageText'),
            Text('Prévu: ${_formatDate(vacc.dueDate)}'),
            if (isDone && vacc.administeredDate != null)
              Text('Fait le: ${_formatDate(vacc.administeredDate!)}', style: const TextStyle(color: Colors.green)),
            if (isOverdue)
              Text(
                'RETARD: ${DateTime.now().difference(vacc.dueDate).inDays} jours',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: !isDone
            ? ElevatedButton(
                onPressed: () => _markAsAdministered(vacc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverdue ? Colors.red : Colors.green,
                ),
                child: const Text('Fait'),
              )
            : null,
      ),
    );
  }

  String _getAgeText(int days) {
    if (days == 0) return 'Naissance';
    if (days < 7) return '$days jours';
    if (days < 30) return '${(days / 7).floor()} semaines';
    final months = (days / 30).floor();
    return '$months mois';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
