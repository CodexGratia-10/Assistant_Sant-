import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/patients_list_screen.dart';
import 'screens/protocols_list_screen.dart';
import 'screens/alerts_screen.dart';

void main() {
  runApp(const AssistantSanteApp());
}

class AssistantSanteApp extends StatelessWidget {
  const AssistantSanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistant Santé Communautaire',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    PatientsListScreen(),
    ProtocolsListScreen(),
    AlertsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Protocoles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade700,
        onTap: _onItemTapped,
      ),
    );
  }
}
