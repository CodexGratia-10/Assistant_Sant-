class Alert {
  final String id;
  final String? patientId;
  /// Type fonctionnel: 'vaccination', 'pregnancy', 'followup', ...
  String type;
  /// Code interne: 'PNC_VISIT_1', 'VACCINE_DUE_BCG', ...
  String code;
  final DateTime targetDate;
  /// Statut: 'pending', 'acknowledged', 'dismissed'
  String status;
  final DateTime createdAt;
  /// Message lisible affiché au relais
  String message;

  Alert({
    required this.id,
    this.patientId,
    required this.type,
    required this.code,
    required this.targetDate,
    this.status = 'pending',
    required this.createdAt,
    required this.message,
  });

  bool get isUrgent {
    final now = DateTime.now();
    return targetDate.isBefore(now) || 
           targetDate.difference(now).inDays <= 1;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'patient_id': patientId,
      'category': type,
        'code': code,
        'target_date': targetDate.millisecondsSinceEpoch,
        'status': status,
        'created_at': createdAt.millisecondsSinceEpoch,
      'message': message,
      };

  static Alert fromMap(Map<String, Object?> map) => Alert(
        id: map['id'] as String,
        patientId: map['patient_id'] as String?,
      type: map['category'] as String,
        code: map['code'] as String,
        targetDate: DateTime.fromMillisecondsSinceEpoch(map['target_date'] as int),
      status: map['status'] as String? ?? 'pending',
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      message: map['message'] as String? ?? '',
      );
}
