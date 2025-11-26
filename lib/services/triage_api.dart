import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class TriageApiClient {
  final String baseUrl;
  final http.Client _client;

  TriageApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? apiBaseUrl,
        _client = client ?? http.Client();

  Future<Map<String, dynamic>> start({int? patientId, int? relaisId, double? poids, String? rdtResult}) async {
    final uri = Uri.parse('$baseUrl/triage/start/');
    final payload = <String, dynamic>{};
    if (patientId != null) payload['patient'] = patientId;
    if (relaisId != null) payload['relais'] = relaisId;
    if (poids != null) payload['poids'] = poids;
    if (rdtResult != null) payload['rdt_result'] = rdtResult;

    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Start triage failed: ${resp.statusCode} ${resp.body}');
  }

  Future<Map<String, dynamic>> answer({required int sessionId, required String question, required dynamic value}) async {
    final uri = Uri.parse('$baseUrl/triage/$sessionId/answer/');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'value': value}),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Answer failed: ${resp.statusCode} ${resp.body}');
  }
}
