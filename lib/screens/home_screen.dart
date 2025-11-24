import 'package:flutter/material.dart';
import 'patients_list_screen.dart';
import 'protocols_list_screen.dart';
import 'pregnancy_screen.dart';
import 'vaccination_screen.dart';
import 'alerts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            _buildActionCard(
              context,
              title: 'Nouvelle\nConsultation',
              icon: Icons.medical_services,
              color: Colors.green,
              onTap: () => _showPatientSelectionForConsultation(context),
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
              ),
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
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
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
    );
  }

  void _showPatientSelectionForConsultation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Consultation'),
        content: const Text(
          'Veuillez d\'abord sélectionner un patient depuis l\'écran Patients, puis lancer une consultation depuis sa fiche.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
