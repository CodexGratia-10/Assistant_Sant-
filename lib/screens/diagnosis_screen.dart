import 'package:flutter/material.dart';
import '../data/decision_tree/decision_tree.dart';

class DiagnosisScreen extends StatefulWidget {
  final String patientId;
  final String visitId;

  const DiagnosisScreen({
    super.key,
    required this.patientId,
    required this.visitId,
  });

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  String _selectedPathology = 'malaria';
  DecisionTree? _tree;
  final EvaluationContext _context = EvaluationContext();
  String _currentNodeId = '';
  final List<Map<String, dynamic>> _conversationHistory = [];
  bool _isComplete = false;
  Map<String, dynamic>? _finalOutcome;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    String assetPath;
    switch (_selectedPathology) {
      case 'diarrhea':
        assetPath = 'assets/decision_trees/diarrhea_tree.json';
        break;
      case 'respiratory':
        assetPath = 'assets/decision_trees/respiratory_tree.json';
        break;
      case 'malnutrition':
        assetPath = 'assets/decision_trees/malnutrition_tree.json';
        break;
      case 'malaria':
      default:
        assetPath = 'assets/decision_trees/malaria_tree.json';
        break;
    }

    final tree = await DecisionTree.loadAsset(assetPath);
    setState(() {
      _tree = tree;
      _currentNodeId = tree.root;
      _conversationHistory.clear();
      _isComplete = false;
      _finalOutcome = null;
      _context.answers.clear();
      _context.flags.clear();
    });
  }

  void _processAnswer(dynamic answer, String questionId) {
    _context.answers[questionId] = answer;
    _conversationHistory.add({
      'nodeId': _currentNodeId,
      'question': _getCurrentNode()['text'],
      'answer': answer,
    });
    _moveToNext();
  }

  void _moveToNext() {
    if (_tree == null) return;
    
    final currentNode = _getCurrentNode();
    final nodeType = currentNode['type'];

    if (nodeType == 'outcome') {
      _completeEvaluation(currentNode['outcome']);
      return;
    }

    String? nextNodeId;

    if (nodeType == 'question') {
      final next = currentNode['next'];
      if (next is String) {
        nextNodeId = next;
      } else if (next is Map) {
        final answer = _context.answers[_currentNodeId];
        nextNodeId = next[answer.toString()];
      }
    } else if (nodeType == 'action') {
      nextNodeId = currentNode['next'];
    } else if (nodeType == 'multi_select') {
      nextNodeId = currentNode['next'];
    } else if (nodeType == 'logic') {
      _applyLogicRules(currentNode);
      nextNodeId = currentNode['next'];
    } else if (nodeType == 'decision') {
      // Final decision handled by engine
      _completeEvaluation(null);
      return;
    }

    if (nextNodeId != null) {
      setState(() => _currentNodeId = nextNodeId!);
      
      // Auto-advance for action and logic nodes
      if (_getCurrentNode()['type'] == 'action') {
        Future.delayed(const Duration(milliseconds: 500), _moveToNext);
      } else if (_getCurrentNode()['type'] == 'logic') {
        _moveToNext();
      }
    }
  }

  void _applyLogicRules(Map<String, dynamic> node) {
    final rules = node['rules'] as List<dynamic>?;
    if (rules == null) return;

    for (final rule in rules) {
      final r = rule as Map<String, dynamic>;
      
      if (r.containsKey('if_any_symptom')) {
        final symptoms = r['if_any_symptom'] as List<dynamic>;
        final selectedSymptoms = _context.answers['other_symptoms'] as List<dynamic>? ?? [];
        if (symptoms.any((s) => selectedSymptoms.contains(s))) {
          final flag = r['set_flag'] as String;
          _context.flags.add(flag);
        }
      }
    }
  }

  void _completeEvaluation(String? outcomeKey) {
    final engine = DecisionEngine(_tree!);
    final outcome = engine.evaluate(_context);
    
    setState(() {
      _isComplete = true;
      _finalOutcome = outcome;
    });
  }

  Map<String, dynamic> _getCurrentNode() {
    return _tree!.nodes[_currentNodeId] as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    if (_tree == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagnostic')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isComplete && _finalOutcome != null) {
      return _buildOutcomeScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic guidé'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildPathologySelector(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ..._conversationHistory.map((h) => _buildHistoryItem(h)),
                  _buildCurrentQuestion(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathologySelector() {
    return Container
      (
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPathologyChip(
              code: 'malaria',
              label: 'Fièvre / Palu',
              icon: Icons.bug_report,
              color: Colors.green,
            ),
            _buildPathologyChip(
              code: 'respiratory',
              label: 'Toux / Resp.',
              icon: Icons.air,
              color: Colors.blue,
            ),
            _buildPathologyChip(
              code: 'diarrhea',
              label: 'Diarrhée',
              icon: Icons.water_drop,
              color: Colors.orange,
            ),
            _buildPathologyChip(
              code: 'malnutrition',
              label: 'Malnutrition',
              icon: Icons.restaurant,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathologyChip({
    required String code,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPathology == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) {
          if (!val || _selectedPathology == code) return;
          setState(() {
            _selectedPathology = code;
          });
          _loadTree();
        },
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> historyItem) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              historyItem['question'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_formatAnswer(historyItem['answer'])),
          ),
        ],
      ),
    );
  }

  String _formatAnswer(dynamic answer) {
    if (answer is bool) return answer ? 'Oui' : 'Non';
    if (answer is List) return answer.join(', ');
    return answer.toString();
  }

  Widget _buildCurrentQuestion() {
    final node = _getCurrentNode();
    final nodeType = node['type'];

    if (nodeType == 'action') {
      return Card(
        color: Colors.amber.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(child: Text(node['text'], style: const TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
        ),
      );
    }

    if (nodeType == 'question') {
      final inputType = (node['input'] as Map<String, dynamic>)['type'];
      
      if (inputType == 'boolean') {
        return _buildBooleanQuestion(node);
      } else if (inputType == 'numeric') {
        return _buildNumericQuestion(node);
      } else if (inputType == 'single_select') {
        return _buildSingleSelectQuestion(node);
      }
    }

    if (nodeType == 'multi_select') {
      return _buildMultiSelectQuestion(node);
    }

    return const SizedBox.shrink();
  }

  Widget _buildBooleanQuestion(Map<String, dynamic> node) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node['text'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processAnswer(true, _currentNodeId),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Oui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processAnswer(false, _currentNodeId),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Non'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericQuestion(Map<String, dynamic> node) {
    final controller = TextEditingController();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node['text'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Entrer la valeur',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  _processAnswer(value, _currentNodeId);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSelectQuestion(Map<String, dynamic> node) {
    final options = (node['input'] as Map<String, dynamic>)['options'] as List<dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node['text'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () => _processAnswer(opt, _currentNodeId),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(opt.toString()),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectQuestion(Map<String, dynamic> node) {
    final options = node['options'] as List<dynamic>;
    final selected = <String>{};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(node['text'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final option = opt as Map<String, dynamic>;
                final code = option['code'] as String;
                return CheckboxListTile(
                  title: Text(option['label']),
                  value: selected.contains(code),
                  onChanged: (val) {
                    setModalState(() {
                      if (val == true) {
                        selected.add(code);
                      } else {
                        selected.remove(code);
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _processAnswer(selected.toList(), _currentNodeId),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutcomeScreen() {
    final urgency = _finalOutcome!['urgency'];
    Color urgencyColor = Colors.green;
    IconData urgencyIcon = Icons.check_circle;

    if (urgency == 'high') {
      urgencyColor = Colors.red;
      urgencyIcon = Icons.warning;
    } else if (urgency == 'medium') {
      urgencyColor = Colors.orange;
      urgencyIcon = Icons.info;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat'),
        backgroundColor: urgencyColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: urgencyColor.withAlpha(25),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(urgencyIcon, size: 64, color: urgencyColor),
                    const SizedBox(height: 16),
                    Text(
                      _finalOutcome!['label'],
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: urgencyColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Action recommandée:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_finalOutcome!['action'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            if (urgency == 'high')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⚠️ URGENCE - Référer immédiatement au centre de santé',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Terminer la consultation'),
            ),
          ],
        ),
      ),
    );
  }
}
