class Patient {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? sex; // 'M' or 'F'
  final int? yearOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.sex,
    this.yearOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'sex': sex,
        'year_of_birth': yearOfBirth,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static Patient fromMap(Map<String, Object?> map) => Patient(
        id: map['id'] as String,
        firstName: map['first_name'] as String?,
        lastName: map['last_name'] as String?,
        phone: map['phone'] as String?,
        sex: map['sex'] as String?,
        yearOfBirth: map['year_of_birth'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
