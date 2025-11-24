import 'package:sqflite/sqflite.dart';
import '../models/patient.dart';
import '../db/database_service.dart';

class PatientDao {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<void> insert(Patient patient) async {
    final db = await _dbService.database;
    await db.insert('patient', patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Patient?> getById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query('patient', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<List<Patient>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query('patient', orderBy: 'created_at DESC');
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  Future<void> update(Patient patient) async {
    final db = await _dbService.database;
    await db.update('patient', patient.toMap(),
        where: 'id = ?', whereArgs: [patient.id]);
  }

  Future<void> delete(String id) async {
    final db = await _dbService.database;
    await db.delete('patient', where: 'id = ?', whereArgs: [id]);
  }
}
