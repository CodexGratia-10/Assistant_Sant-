import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/triage_api.dart';
import '../data/dao/visit_dao.dart';
import '../data/dao/observation_dao.dart';
import '../data/models/visit.dart';
import '../data/models/symptom_observation.dart';
import '../data/decision_tree/decision_tree.dart';
import '../data/models/alert.dart';
import '../data/dao/tracking_dao.dart';

class BackendTriageScreen extends StatefulWidget {
  final String? patientId;

  const BackendTriageScreen({super.key, this.patientId});

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
  final VisitDao _visitDao = VisitDao();
  final ObservationDao _observationDao = ObservationDao();
  String? _visitId;
  final TextEditingController _freeTextController = TextEditingController();
  String _mode = 'server_palu'; // 'server_palu' | 'offline_local'
  String _localPathology = 'malaria';
  DecisionTree? _localTree;
  final EvaluationContext _offlineCtx = EvaluationContext();

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
    _prepareVisitAndStart();
  }

  Future<void> _prepareVisitAndStart() async {
    if (widget.patientId != null) {
      final visit = Visit(
        id: const Uuid().v4(),
        patientId: widget.patientId!,
        visitType: 'server_ai',
        startedAt: DateTime.now(),
      );
      await _visitDao.insert(visit);
      _visitId = visit.id;
    }
    await _startSession();
    await _loadLocalTree();
  }

  Future<void> _startSession() async {
    if (_mode == 'server_palu') {
      setState(() => _loading = true);
      try {
        final data = await _api.start();
        setState(() {
          _sessionId = data['session_id'] as int;
          _currentQuestionCode = data['question'] as String?;
        });
      } catch (e) {
        // bascule offline
        setState(() {
          _mode = 'offline_local';
        });
        await _loadLocalTree();
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadLocalTree() async {
    String assetPath;
    switch (_localPathology) {
      case 'respiratory':
        assetPath = 'assets/decision_trees/respiratory_tree.json';
        break;
      case 'diarrhea':
        assetPath = 'assets/decision_trees/diarrhea_tree.json';
        break;
      case 'malnutrition':
        assetPath = 'assets/decision_trees/malnutrition_tree.json';
        break;
      case 'malaria':
      default:
        assetPath = 'assets/decision_trees/malaria_tree.json';
        break;
    }
    try {
      final tree = await DecisionTree.loadAsset(assetPath);
      setState(() => _localTree = tree);
    } catch (_) {
      // ignore
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

      _history.add({'question': _currentQuestionCode!, 'answer': value});
      await _persistAnswer(_currentQuestionCode!, value);

      if (res['completed'] == true) {
        _completed = true;
        _finalOutput = (res['final_output'] as Map<String, dynamic>?);
        await _finalizeVisit();
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

  Future<void> _persistAnswer(String code, dynamic answer) async {
    if (_visitId == null) return;
    final now = DateTime.now();
    if (answer is bool) {
      await _observationDao.insertSymptom(SymptomObservation(
        id: const Uuid().v4(),
        visitId: _visitId!,
        code: code,
        value: answer ? 'yes' : 'no',
        numericValue: null,
        capturedAt: now,
      ));
    } else if (answer is num) {
      await _observationDao.insertSymptom(SymptomObservation(
        id: const Uuid().v4(),
        visitId: _visitId!,
        code: code,
        value: null,
        numericValue: answer.toDouble(),
        capturedAt: now,
      ));
    } else {
      await _observationDao.insertSymptom(SymptomObservation(
        id: const Uuid().v4(),
        visitId: _visitId!,
        code: code,
        value: answer.toString(),
        numericValue: null,
        capturedAt: now,
      ));
    }
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Text('Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Serveur Palu'),
            selected: _mode == 'server_palu',
            onSelected: (v) {
              if (!v) return;
              setState(() => _mode = 'server_palu');
              _startSession();
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Off'),
            selected: _mode == 'offline_local',
            onSelected: (v) {
              if (!v) return;
              setState(() => _mode = 'offline_local');
              _loadLocalTree();
            },
          ),
          const Spacer(),
          if (_mode == 'offline_local')
            TextButton.icon(
              onPressed: _showOfflineOptions,
              icon: const Icon(Icons.more_horiz),
              label: const Text('Plus'),
            ),
        ],
      ),
    );
  }

  void _showOfflineOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choisir la pathologie', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _localPathology,
                  decoration: const InputDecoration(labelText: 'Pathologie', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'malaria', child: Text('Fièvre / Palu')),
                    DropdownMenuItem(value: 'respiratory', child: Text('Respiratoire')),
                    DropdownMenuItem(value: 'diarrhea', child: Text('Diarrhée')),
                    DropdownMenuItem(value: 'malnutrition', child: Text('Malnutrition')),
                  ],
                  onChanged: (v) {
                    setState(() => _localPathology = v ?? 'malaria');
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _loadLocalTree();
                        _offlineReevaluate();
                      },
                      child: const Text('Valider'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfflineLocalHelper() {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mode offline (arbre local)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Pathologie: $_localPathology'),
                const SizedBox(height: 8),
                const Text('Saisissez des symptômes libres ou revenez au mode serveur.'),
              ],
            ),
          ),
        );
      }

  void _offlineReevaluate() {
    // rebuild context from history
    _offlineCtx.answers.clear();
    _offlineCtx.flags.clear();

    // Free-text symptoms
    final freeSymptoms = _history
        .where((h) => h['question'] == 'symptome_libre')
        .map((h) => (h['answer'] as String).toLowerCase())
        .toList();
    if (freeSymptoms.isNotEmpty) {
      _offlineCtx.answers['other_symptoms'] = freeSymptoms;
    }

    // Map guided answers to context
    bool? fever;
    double? temperature;
    int? feverDays;
    bool convulsions = false;
    bool prostration = false;
    bool unableToDrink = false;
    bool cough = false;
    bool diarrhea = false;
    bool vomiting = false;
    bool recentMalaria = false;

    for (final h in _history) {
      final q = h['question'] as String?;
      final a = h['answer'];
      switch (q) {
        case 'fievre':
          fever = a == true;
          break;
        case 'temperature':
          if (a is num) temperature = a.toDouble();
          break;
        case 'duree_fievre_jours':
          if (a is num) feverDays = a.toInt();
          break;
        case 'convulsions':
          if (a == true) convulsions = true;
          break;
        case 'prostration':
          if (a == true) prostration = true;
          break;
        case 'incapacite_a_manger':
          if (a == true) unableToDrink = true;
          break;
        case 'toux':
          if (a == true) cough = true;
          break;
        case 'diarrhee':
          if (a == true) diarrhea = true;
          break;
        case 'vomissements':
          if (a == true) vomiting = true;
          break;
        case 'paludisme_recent':
          if (a == true) recentMalaria = true;
          break;
      }
    }

    if (fever != null) _offlineCtx.answers['fever'] = fever;
    if (temperature != null) _offlineCtx.answers['temperature'] = temperature;
    if (feverDays != null) _offlineCtx.answers['fever_days'] = feverDays;
    _offlineCtx.answers['cough'] = cough;
    _offlineCtx.answers['diarrhea'] = diarrhea;
    _offlineCtx.answers['vomiting'] = vomiting;
    _offlineCtx.answers['unable_to_drink'] = unableToDrink;
    _offlineCtx.answers['recent_malaria'] = recentMalaria;

    // Danger sign flags from guided & free text
    if (convulsions) _offlineCtx.flags.add('danger_convulsions');
    if (prostration) _offlineCtx.flags.add('danger_prostration');
    if (unableToDrink) _offlineCtx.flags.add('danger_unable_to_drink');
    // high fever
    if (temperature != null && temperature >= 38.5) {
      _offlineCtx.flags.add('fever_high');
    }
    // prolonged fever
    if (feverDays != null && feverDays >= 2) {
      _offlineCtx.flags.add('fever_prolonged');
    }
    // dehydration risk
    if (diarrhea && vomiting) {
      _offlineCtx.flags.add('risk_dehydration');
    }
    // keyword-based additional danger
    if (freeSymptoms.any((s) => s.contains('convulsion'))) {
      _offlineCtx.flags.add('danger_convulsions');
    }
    if (freeSymptoms.any((s) => s.contains('prostration'))) {
      _offlineCtx.flags.add('danger_prostration');
    }
  }

  Widget _buildOfflinePreview() {
        if (_localTree == null) return const SizedBox.shrink();
        _offlineReevaluate();
        final engine = DecisionEngine(_localTree!);
        final out = engine.evaluate(_offlineCtx);
        final label = out['label'] as String? ?? 'Indéterminé';
        final action = out['action'] as String? ?? 'Collecter plus de symptômes';
        final urgency = out['urgency'] as String? ?? 'low';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hypothèse (offline)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(label),
              const SizedBox(height: 8),
              const Text('Recommandation', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(action),
              if (urgency == 'high')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 6),
                    const Expanded(child: Text('Signes de danger possibles — référer.')),
                  ]),
                ),
            ]),
          ),
        );
      }


  Future<void> _finalizeVisit() async {
    if (_visitId == null || _finalOutput == null) return;
    final out = _finalOutput!;
    final urgency = (out['urgency'] as String?) ?? 'low';
    final label = (out['hypotheses'] is List && (out['hypotheses'] as List).isNotEmpty)
        ? ((out['hypotheses'] as List).first as Map)['label'] as String?
        : (out['recommendation'] as String?);
    final existing = await _visitDao.getById(_visitId!);
    if (existing != null) {
      await _visitDao.update(Visit(
        id: existing.id,
        patientId: existing.patientId,
        visitType: existing.visitType,
        startedAt: existing.startedAt,
        completedAt: DateTime.now(),
        outcome: label ?? existing.outcome,
        referralFlag: urgency == 'high',
        syncStatus: existing.syncStatus,
      ));
    }
    // Create urgent alert if needed
    if (urgency == 'high') {
      try {
        final alertDao = AlertDao();
        await alertDao.insert(Alert(
          id: const Uuid().v4(),
          patientId: existing?.patientId,
          type: 'followup',
          code: 'URGENT_REFERRAL',
          targetDate: DateTime.now(),
          status: 'pending',
          createdAt: DateTime.now(),
          message: 'Cas urgent détecté: référer immédiatement',
        ));
      } catch (_) {}
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
                  _buildModeSelector(),
                  ..._history.map(_buildHistoryItem),
                  if (_mode == 'server_palu') ...[
                    if (_currentQuestionCode != null) _buildQuestionCard(_currentQuestionCode!),
                    if (_preview != null) _buildPreview(_preview!),
                  ] else ...[
                    _buildOfflineLocalHelper(),
                    _buildOfflinePreview(),
                  ],
                  const SizedBox(height: 12),
                  _buildFreeTextInput(),
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

  Widget _buildFreeTextInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajouter un symptôme libre', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _freeTextController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: maux de tête, douleurs, autre…',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = _freeTextController.text.trim();
                  if (text.isEmpty) return;
                  _history.add({'question': 'symptome_libre', 'answer': text});
                  _freeTextController.clear();
                  _persistAnswer('symptome_libre', text);
                  if (_mode == 'offline_local') {
                    setState(() {});
                  } else {
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ),
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
