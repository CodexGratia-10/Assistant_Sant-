class Vaccination {
  final String id;
  final String patientId;
  final String vaccineCode; // 'BCG', 'PENTA_1', 'POLIO_0', etc.
  final String vaccineName; // 'BCG', 'Pentavalent 1', 'Polio 0', etc.
  final DateTime dueDate;
  DateTime? administeredDate;
  String status; // 'scheduled', 'administered', 'missed'

  Vaccination({
    required this.id,
    required this.patientId,
    required this.vaccineCode,
    required this.vaccineName,
    required this.dueDate,
    this.administeredDate,
    this.status = 'scheduled',
  });

  bool get isOverdue {
    if (status == 'administered') return false;
    return DateTime.now().isAfter(dueDate.add(const Duration(days: 7)));
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'patient_id': patientId,
        'vaccine_code': vaccineCode,
        'vaccine_name': vaccineName,
        'due_date': dueDate.millisecondsSinceEpoch,
        'administered_date': administeredDate?.millisecondsSinceEpoch,
        'status': status,
      };

  static Vaccination fromMap(Map<String, Object?> map) => Vaccination(
        id: map['id'] as String,
        patientId: map['patient_id'] as String,
        vaccineCode: map['vaccine_code'] as String,
        vaccineName: map['vaccine_name'] as String? ?? map['vaccine_code'] as String,
        dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
        administeredDate: map['administered_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['administered_date'] as int)
            : null,
        status: map['status'] as String? ?? 'scheduled',
      );
}
