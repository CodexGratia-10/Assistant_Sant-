import 'package:flutter/material.dart';
import '../services/protocol_service.dart';
import '../data/models/care_protocol.dart';
import 'protocol_detail_screen.dart';

class ProtocolsListScreen extends StatefulWidget {
  const ProtocolsListScreen({super.key});

  @override
  State<ProtocolsListScreen> createState() => _ProtocolsListScreenState();
}

class _ProtocolsListScreenState extends State<ProtocolsListScreen> {
  final ProtocolService _protocolService = ProtocolService();
  List<CareProtocol> _protocols = [];
  List<CareProtocol> _filteredProtocols = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProtocols();
    _searchController.addListener(_filterProtocols);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProtocols() async {
    setState(() => _isLoading = true);
    final protocols = await _protocolService.getAllProtocols();
    setState(() {
      _protocols = protocols;
      _filteredProtocols = protocols;
      _isLoading = false;
    });
  }

  void _filterProtocols() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProtocols = _protocols.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            p.keywords.any((k) => k.toLowerCase().contains(query));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protocoles de Soins'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un protocole...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredProtocols.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun protocole trouvé',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProtocols.length,
                          itemBuilder: (context, index) {
                            final protocol = _filteredProtocols[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getCategoryColor(protocol.category),
                                  child: Icon(_getCategoryIcon(protocol.category), color: Colors.white),
                                ),
                                title: Text(protocol.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${protocol.disease} • ${protocol.category}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProtocolDetailScreen(protocol: protocol),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'treatment':
        return Colors.green;
      case 'diagnosis':
        return Colors.blue;
      case 'prevention':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'treatment':
        return Icons.medical_services;
      case 'diagnosis':
        return Icons.search;
      case 'prevention':
        return Icons.shield;
      default:
        return Icons.description;
    }
  }
}
