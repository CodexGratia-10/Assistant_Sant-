class SymptomObservation {
  final String id;
  final String visitId;
  final String code;
  final String? value;
  final double? numericValue;
  final DateTime capturedAt;

  SymptomObservation({
    required this.id,
    required this.visitId,
    required this.code,
    this.value,
    this.numericValue,
    required this.capturedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'visit_id': visitId,
        'code': code,
        'value': value,
        'numeric_value': numericValue,
        'captured_at': capturedAt.millisecondsSinceEpoch,
      };

  static SymptomObservation fromMap(Map<String, Object?> map) => SymptomObservation(
        id: map['id'] as String,
        visitId: map['visit_id'] as String,
        code: map['code'] as String,
        value: map['value'] as String?,
        numericValue: map['numeric_value'] as double?,
        capturedAt: DateTime.fromMillisecondsSinceEpoch(map['captured_at'] as int),
      );
}
