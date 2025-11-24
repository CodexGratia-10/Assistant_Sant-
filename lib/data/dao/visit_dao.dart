import 'package:sqflite/sqflite.dart';
import '../models/visit.dart';
import '../db/database_service.dart';

class VisitDao {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<void> insert(Visit visit) async {
    final db = await _dbService.database;
    await db.insert('visit', visit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Visit?> getById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query('visit', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<List<Visit>> getByPatientId(String patientId) async {
    final db = await _dbService.database;
    final maps = await db.query('visit',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'started_at DESC');
    return maps.map((m) => Visit.fromMap(m)).toList();
  }

  Future<List<Visit>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query('visit', orderBy: 'started_at DESC');
    return maps.map((m) => Visit.fromMap(m)).toList();
  }

  Future<void> update(Visit visit) async {
    final db = await _dbService.database;
    await db.update('visit', visit.toMap(),
        where: 'id = ?', whereArgs: [visit.id]);
  }

  Future<void> delete(String id) async {
    final db = await _dbService.database;
    await db.delete('visit', where: 'id = ?', whereArgs: [id]);
  }
}
