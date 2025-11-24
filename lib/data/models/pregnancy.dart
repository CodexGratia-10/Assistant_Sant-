class Pregnancy {
  final String id;
  final String patientId;
  /// Date des dernières règles (DDR / LMP)
  final DateTime? lastMenstrualPeriod;
  /// Niveau de risque global: 'normal', 'high'
  final String riskLevel;
  /// Statut de la grossesse: 'active', 'completed', 'terminated'
  final String status;
  /// Notes libres du relais ou du soignant
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pregnancy({
    required this.id,
    required this.patientId,
    this.lastMenstrualPeriod,
    this.riskLevel = 'normal',
    this.status = 'active',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime? get estimatedDueDate {
    if (lastMenstrualPeriod == null) return null;
    return lastMenstrualPeriod!.add(const Duration(days: 280)); // 40 semaines
  }

  int? get weeksPregnant {
    if (lastMenstrualPeriod == null) return null;
    final now = DateTime.now();
    final diff = now.difference(lastMenstrualPeriod!);
    return (diff.inDays / 7).floor();
  }

  int? get trimester {
    final weeks = weeksPregnant;
    if (weeks == null) return null;
    if (weeks <= 13) return 1;
    if (weeks <= 26) return 2;
    return 3;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'patient_id': patientId,
      'lmp_date': lastMenstrualPeriod?.millisecondsSinceEpoch,
        'risk_level': riskLevel,
      'status': status,
      'notes': notes,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static Pregnancy fromMap(Map<String, Object?> map) => Pregnancy(
        id: map['id'] as String,
        patientId: map['patient_id'] as String,
      lastMenstrualPeriod: map['lmp_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lmp_date'] as int)
            : null,
        riskLevel: map['risk_level'] as String? ?? 'normal',
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
