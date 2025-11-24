class VitalSign {
  final String id;
  final String visitId;
  final String type; // 'temperature','resp_rate','heart_rate'
  final double value;
  final String unit;
  final DateTime capturedAt;

  VitalSign({
    required this.id,
    required this.visitId,
    required this.type,
    required this.value,
    required this.unit,
    required this.capturedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'visit_id': visitId,
        'type': type,
        'value': value,
        'unit': unit,
        'captured_at': capturedAt.millisecondsSinceEpoch,
      };

  static VitalSign fromMap(Map<String, Object?> map) => VitalSign(
        id: map['id'] as String,
        visitId: map['visit_id'] as String,
        type: map['type'] as String,
        value: (map['value'] as num).toDouble(),
        unit: map['unit'] as String,
        capturedAt: DateTime.fromMillisecondsSinceEpoch(map['captured_at'] as int),
      );
}
