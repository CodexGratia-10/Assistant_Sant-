class MalariaRDT {
  final String id;
  final String visitId;
  final bool performed;
  final String? result; // 'positive','negative','invalid'
  final DateTime capturedAt;

  MalariaRDT({
    required this.id,
    required this.visitId,
    required this.performed,
    this.result,
    required this.capturedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'visit_id': visitId,
        'performed': performed ? 1 : 0,
        'result': result,
        'captured_at': capturedAt.millisecondsSinceEpoch,
      };

  static MalariaRDT fromMap(Map<String, Object?> map) => MalariaRDT(
        id: map['id'] as String,
        visitId: map['visit_id'] as String,
        performed: (map['performed'] as int) == 1,
        result: map['result'] as String?,
        capturedAt: DateTime.fromMillisecondsSinceEpoch(map['captured_at'] as int),
      );
}
