import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/models/care_protocol.dart';

class ProtocolService {
  static List<CareProtocol>? _cachedProtocols;

  Future<List<CareProtocol>> loadProtocols() async {
    if (_cachedProtocols != null) return _cachedProtocols!;

    final jsonString = await rootBundle.loadString('assets/protocols/care_protocols.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> protocolsList = data['protocols'];

    _cachedProtocols = protocolsList.map((p) {
      return CareProtocol(
        id: p['id'],
        disease: p['disease'],
        category: p['category'],
        title: p['title'],
        content: p['content'],
        keywords: List<String>.from(p['keywords']),
      );
    }).toList();

    return _cachedProtocols!;
  }

  Future<List<CareProtocol>> searchProtocols(String query) async {
    final protocols = await loadProtocols();
    final lowerQuery = query.toLowerCase();

    return protocols.where((p) {
      return p.title.toLowerCase().contains(lowerQuery) ||
          p.disease.toLowerCase().contains(lowerQuery) ||
          p.content.toLowerCase().contains(lowerQuery) ||
          p.keywords.any((k) => k.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<List<CareProtocol>> getByDisease(String disease) async {
    final protocols = await loadProtocols();
    return protocols.where((p) => p.disease == disease).toList();
  }

  Future<CareProtocol?> getById(String id) async {
    final protocols = await loadProtocols();
    return protocols.firstWhere((p) => p.id == id);
  }

  Future<List<CareProtocol>> getAllProtocols() async {
    return await loadProtocols();
  }
}
