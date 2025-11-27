import 'package:flutter/material.dart';
import '../data/models/care_protocol.dart';

class ProtocolDetailScreen extends StatelessWidget {
  final CareProtocol protocol;

  const ProtocolDetailScreen({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    String cleaned = protocol.content
        .replaceAll(RegExp(r'^\s*[\*\-]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}', multiLine: true), '\n\n');
    return Scaffold(
      appBar: AppBar(
        title: Text(protocol.title),
        backgroundColor: Colors.purple.shade700,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec catégorie et maladie
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.purple.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      protocol.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    protocol.disease.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: protocol.keywords
                        .map((k) => Chip(
                              label: Text(k, style: const TextStyle(fontSize: 11)),
                              backgroundColor: Colors.purple.shade100,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // Contenu du protocole
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                cleaned,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
