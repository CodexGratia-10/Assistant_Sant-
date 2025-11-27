import 'package:flutter/material.dart';
import 'patients_list_screen.dart';
import 'protocols_list_screen.dart';
import 'pregnancy_screen.dart';
import 'vaccination_screen.dart';
import 'alerts_screen.dart';
import '../data/dao/tracking_dao.dart';
import '../config.dart';
import 'backend_triage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pendingAlerts = 0;
  final AlertDao _alertDao = AlertDao();

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final count = await _alertDao.getAllPendingCount();
    if (!mounted) return;
    setState(() => _pendingAlerts = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Santé Communautaire'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionCard(
              context,
              title: 'Patients',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientsListScreen()),
              ),
            ),
            if (enableBackendTriage)
              _buildActionCard(
                context,
                title: 'Autres\nConsultations',
                icon: Icons.chat_bubble,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BackendTriageScreen()),
                ),
              ),
            _buildActionCard(
              context,
              title: 'Suivi\nGrossesse',
              icon: Icons.pregnant_woman,
              color: Colors.pink,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PregnancyScreen()),
              ),
            ),
            _buildActionCard(
              context,
              title: 'Vaccination\nEnfant',
              icon: Icons.vaccines,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VaccinationScreen()),
              ),
            ),
            _buildActionCard(
              context,
              title: 'Protocoles\nde Soins',
              icon: Icons.book,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProtocolsListScreen()),
              ),
            ),
            _buildActionCard(
              context,
              title: 'Alertes &\nRappels',
              icon: Icons.notifications_active,
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsScreen()),
              ).then((_) => _loadBadges()),
              badgeCount: _pendingAlerts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 64, color: color),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
