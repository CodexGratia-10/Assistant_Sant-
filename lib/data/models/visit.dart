class Visit {
  final String id;
  final String patientId;
  final String? visitType;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? outcome;
  final bool referralFlag;
  final String syncStatus;

  Visit({
    required this.id,
    required this.patientId,
    this.visitType,
    required this.startedAt,
    this.completedAt,
    this.outcome,
    this.referralFlag = false,
    this.syncStatus = 'pending',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'patient_id': patientId,
        'visit_type': visitType,
        'started_at': startedAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'outcome': outcome,
        'referral_flag': referralFlag ? 1 : 0,
        'sync_status': syncStatus,
      };

  static Visit fromMap(Map<String, Object?> map) => Visit(
        id: map['id'] as String,
        patientId: map['patient_id'] as String,
        visitType: map['visit_type'] as String?,
        startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
        completedAt: map['completed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
            : null,
        outcome: map['outcome'] as String?,
        referralFlag: (map['referral_flag'] as int) == 1,
        syncStatus: map['sync_status'] as String? ?? 'pending',
      );
}
