import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Basic structures to load and navigate the decision tree.
class DecisionTree {
  final Map<String, dynamic> raw;
  DecisionTree(this.raw);

  String get root => raw['root'];

  Map<String, dynamic> get nodes => raw['nodes'];
  Map<String, dynamic> get outcomes => raw['outcomes'];

  static Future<DecisionTree> loadAsset(String assetPath) async {
    final content = await rootBundle.loadString(assetPath);
    final data = jsonDecode(content) as Map<String, dynamic>;
    return DecisionTree(data);
  }
}

/// Simple evaluator context collects answers and calculates score.
class EvaluationContext {
  final Map<String, dynamic> answers = {};
  final Set<String> flags = {};
  int computedScore = 0;
}

class DecisionEngine {
  final DecisionTree tree;
  DecisionEngine(this.tree);

  void applyScoring(EvaluationContext ctx) {
    final scoring = tree.raw['scoring'] as Map<String, dynamic>?;
    if (scoring == null) return;
    final weights = scoring['weights'] as Map<String, dynamic>?;
    if (weights == null) return;
    int score = scoring['base'] as int? ?? 0;
    // Temperature
    final temp = ctx.answers['temperature_value'];
    if (temp is num) {
      final tempWeights = weights['temperature_value'] as Map<String, dynamic>?;
      if (tempWeights != null) {
        tempWeights.forEach((k, v) {
          if (k.startsWith('>=')) {
            final threshold = double.tryParse(k.substring(2));
            if (threshold != null && temp >= threshold) score = v as int; // take highest override
          }
        });
      }
    }
    // Duration
    final duration = ctx.answers['duration_fever'];
    if (duration is num) {
      final durWeights = weights['duration_fever'] as Map<String, dynamic>?;
      if (durWeights != null) {
        durWeights.forEach((k, v) {
          if (k.startsWith('>=')) {
            final threshold = double.tryParse(k.substring(2));
            if (threshold != null && duration >= threshold) score += v as int;
          }
        });
      }
    }
    // Symptoms
    final symptomWeights = weights['symptom'] as Map<String, dynamic>?;
    final symptoms = ctx.answers['other_symptoms'];
    if (symptomWeights != null && symptoms is List) {
      for (final s in symptoms) {
        if (symptomWeights.containsKey(s)) score += symptomWeights[s] as int;
      }
    }
    ctx.computedScore = score;
  }

  Map<String, dynamic> evaluate(EvaluationContext ctx) {
    applyScoring(ctx);
    // Determine outcome
    final finalNode = tree.nodes['final_decision'] as Map<String, dynamic>;
    final branches = finalNode['branches'] as List<dynamic>;
    for (final b in branches) {
      final branch = b as Map<String, dynamic>;
      if (branch.containsKey('when_flag')) {
        if (ctx.flags.contains(branch['when_flag'])) {
          return tree.outcomes[branch['outcome']] as Map<String, dynamic>;
        }
      } else if (branch.containsKey('when')) {
        final cond = branch['when'] as Map<String, dynamic>;
        if (cond.containsKey('rdt_result')) {
          if (ctx.answers['rdt_result'] == cond['rdt_result']) {
            return tree.outcomes[branch['outcome']] as Map<String, dynamic>;
          }
        } else if (cond.containsKey('computed_score')) {
          final expr = cond['computed_score'] as String;
          if (expr.startsWith('>=')) {
            final thr = int.parse(expr.substring(2));
            if (ctx.computedScore >= thr) {
              return tree.outcomes[branch['outcome']] as Map<String, dynamic>;
            }
          }
        }
      } else if (branch['default'] == true) {
        return tree.outcomes[branch['outcome']] as Map<String, dynamic>;
      }
    }
    return {'label': 'Indéterminé', 'urgency': 'unknown', 'action': 'Revoir les données'};
  }
}
