import 'package:flutter/material.dart';
import '../services/triage_api.dart';

class BackendTriageScreen extends StatefulWidget {
  const BackendTriageScreen({super.key});

  @override
  State<BackendTriageScreen> createState() => _BackendTriageScreenState();
}

class _BackendTriageScreenState extends State<BackendTriageScreen> {
  final TriageApiClient _api = TriageApiClient();
  int? _sessionId;
  String? _currentQuestionCode;
  bool _loading = false;
  bool _completed = false;
  Map<String, dynamic>? _finalOutput;
  Map<String, dynamic>? _preview;
  final List<Map<String, dynamic>> _history = [];

  static const Map<String, String> questionLabels = {
    'fievre': 'Le patient a-t-il de la fièvre ? ',
    'temperature': 'Quelle est la température (°C) ?',
    'duree_fievre_jours': 'Durée de la fièvre (jours)',
    'frissons': 'Frissons présents ?',
    'convulsions': 'Convulsions ?',
    'prostration': 'Prostration ?',
    'incapacite_a_manger': "Incapacité à manger/boire ?",
    'toux': 'Toux ?',
    'diarrhee': 'Diarrhée ?',
    'vomissements': 'Vomissements ?',
    'paludisme_recent': 'Paludisme récent ?',
  };

  static const Map<String, String> questionTypes = {
    'fievre': 'bool',
    'frissons': 'bool',
    'temperature': 'number',
    'duree_fievre_jours': 'number',
    'convulsions': 'bool',
    'prostration': 'bool',
    'incapacite_a_manger': 'bool',
    'toux': 'bool',
    'diarrhee': 'bool',
    'vomissements': 'bool',
    'paludisme_recent': 'bool',
  };

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() => _loading = true);
    try {
      final data = await _api.start();
      setState(() {
        _sessionId = data['session_id'] as int;
        _currentQuestionCode = data['question'] as String?;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendAnswer(dynamic value) async {
    if (_sessionId == null || _currentQuestionCode == null) return;
    setState(() => _loading = true);
    try {
      final res = await _api.answer(
        sessionId: _sessionId!,
        question: _currentQuestionCode!,
        value: value,
      );

      // push history item
      _history.add({
        'question': _currentQuestionCode!,
        'answer': value,
      });

      if (res['completed'] == true) {
        setState(() {
          _completed = true;
          _finalOutput = (res['final_output'] as Map<String, dynamic>?);
        });
      } else {
        setState(() {
          _currentQuestionCode = res['next_question'] as String?;
          _preview = res;
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _sessionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consultation (Serveur Palu)')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_completed && _finalOutput != null) {
      return _buildFinalView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation (Serveur Palu)'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  ..._history.map(_buildHistoryItem),
                  if (_currentQuestionCode != null) _buildQuestionCard(_currentQuestionCode!),
                  if (_preview != null) _buildPreview(_preview!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> h) {
    final code = h['question'] as String;
    final label = questionLabels[code] ?? code;
    final ans = h['answer'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text('$ans'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String code) {
    final label = questionLabels[code] ?? code;
    final type = questionTypes[code] ?? 'bool';
    if (type == 'bool') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendAnswer(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Oui'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendAnswer(false),
                      icon: const Icon(Icons.close),
                      label: const Text('Non'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      final controller = TextEditingController();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Entrez la valeur'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(controller.text.replaceAll(',', '.'));
                  if (v != null) _sendAnswer(v);
                },
                child: const Text('Continuer'),
              )
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPreview(Map<String, dynamic> res) {
    final hypotheses = (res['preview_hypotheses'] as List?)?.cast<Map>() ?? const [];
    final danger = (res['danger_signs'] as List?)?.cast() ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Aperçu', style: TextStyle(fontWeight: FontWeight.bold)),
        if (hypotheses.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hypothèses'),
                  const SizedBox(height: 6),
                  ...hypotheses.map((h) => Text('- ${h['label']} (${h['score']})')),
                ],
              ),
            ),
          ),
        if (danger.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text('Signes de danger: ${danger.join(', ')}')),
            ]),
          )
      ],
    );
  }

  Widget _buildFinalView() {
    final out = _finalOutput!;
    final hypotheses = (out['hypotheses'] as List?)?.cast<Map>() ?? const [];
    final danger = (out['danger_signs'] as List?)?.cast() ?? const [];
    final recommendation = out['recommendation'] as String?;
    final dosage = (out['dosage'] as Map?)?.cast<String, Object?>();

    return Scaffold(
      appBar: AppBar(title: const Text('Résultat (Serveur)'), backgroundColor: Colors.green.shade700),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (hypotheses.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Hypothèses', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...hypotheses.map((h) => Text('- ${h['label']} (${h['score']})')),
                ]),
              ),
            ),
          if (danger.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
              child: Row(children: [const Icon(Icons.warning, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text('Signes de danger: ${danger.join(', ')}'))]),
            ),
          const SizedBox(height: 12),
          if (recommendation != null) ...[
            const Text('Recommandation', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(recommendation),
          ],
          const SizedBox(height: 12),
          if (dosage != null) ...[
            const Text('Posologie (ACT)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Schéma: ${dosage['regimen']}'),
            Text('Comprimés/prise: ${dosage['tablets_per_dose']}'),
            Text('Prises/jour: ${dosage['doses_per_day']}'),
            Text('Durée (jours): ${dosage['days']}'),
            Text('Total comprimés: ${dosage['total_tablets']}'),
          ],
          const Spacer(),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('Terminer'),
          )
        ]),
      ),
    );
  }
}
