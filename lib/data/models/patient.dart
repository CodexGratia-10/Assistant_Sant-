class Patient {
  final String id;
  final String? sex; // 'M' or 'F'
  final int? yearOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    this.sex,
    this.yearOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'sex': sex,
        'year_of_birth': yearOfBirth,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static Patient fromMap(Map<String, Object?> map) => Patient(
        id: map['id'] as String,
        sex: map['sex'] as String?,
        yearOfBirth: map['year_of_birth'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
