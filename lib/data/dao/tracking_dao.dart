import 'package:sqflite/sqflite.dart';
import '../models/pregnancy.dart';
import '../models/vaccination.dart';
import '../models/alert.dart';
import '../db/database_service.dart';

class PregnancyDao {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<void> insert(Pregnancy pregnancy) async {
    final db = await _dbService.database;
    await db.insert('pregnancy', pregnancy.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Pregnancy>> getByPatientId(String patientId) async {
    final db = await _dbService.database;
    final maps = await db.query('pregnancy',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'created_at DESC');
    return maps.map((m) => Pregnancy.fromMap(m)).toList();
  }

  Future<Pregnancy?> getCurrentPregnancy(String patientId) async {
    final db = await _dbService.database;
    final maps = await db.query('pregnancy',
        where: 'patient_id = ? AND status = ?',
        whereArgs: [patientId, 'active'],
        orderBy: 'created_at DESC',
        limit: 1);
    if (maps.isEmpty) return null;
    return Pregnancy.fromMap(maps.first);
  }

  Future<List<Pregnancy>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query('pregnancy', orderBy: 'created_at DESC');
    return maps.map((m) => Pregnancy.fromMap(m)).toList();
  }

  Future<void> update(Pregnancy pregnancy) async {
    final db = await _dbService.database;
    await db.update('pregnancy', pregnancy.toMap(),
        where: 'id = ?', whereArgs: [pregnancy.id]);
  }
}

class VaccinationDao {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<void> insert(Vaccination vaccination) async {
    final db = await _dbService.database;
    await db.insert('vaccination', vaccination.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Vaccination>> getByPatientId(String patientId) async {
    final db = await _dbService.database;
    final maps = await db.query('vaccination',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'due_date ASC');
    return maps.map((m) => Vaccination.fromMap(m)).toList();
  }

  Future<List<Vaccination>> getScheduled() async {
    final db = await _dbService.database;
    final maps = await db.query('vaccination',
        where: 'status = ?', whereArgs: ['scheduled'], orderBy: 'due_date ASC');
    return maps.map((m) => Vaccination.fromMap(m)).toList();
  }

  Future<void> update(Vaccination vaccination) async {
    final db = await _dbService.database;
    await db.update('vaccination', vaccination.toMap(),
        where: 'id = ?', whereArgs: [vaccination.id]);
  }
}

class AlertDao {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<void> insert(Alert alert) async {
    final db = await _dbService.database;
    await db.insert('alert', alert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Alert>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query('alert',
        where: 'status = ?', whereArgs: ['open'], orderBy: 'target_date ASC');
    return maps.map((m) => Alert.fromMap(m)).toList();
  }

  Future<List<Alert>> getByPatientId(String patientId) async {
    final db = await _dbService.database;
    final maps = await db.query('alert',
        where: 'patient_id = ? AND status = ?',
        whereArgs: [patientId, 'open'],
        orderBy: 'target_date ASC');
    return maps.map((m) => Alert.fromMap(m)).toList();
  }

  Future<void> update(Alert alert) async {
    final db = await _dbService.database;
    await db.update('alert', alert.toMap(),
        where: 'id = ?', whereArgs: [alert.id]);
  }

  Future<void> markAcknowledged(String alertId) async {
    final db = await _dbService.database;
    await db.update('alert', {'status': 'ack'},
        where: 'id = ?', whereArgs: [alertId]);
  }

  Future<List<Alert>> getPendingAlerts(String patientId) async {
    final db = await _dbService.database;
    final maps = await db.query('alert',
        where: 'patient_id = ? AND status = ?',
        whereArgs: [patientId, 'pending'],
        orderBy: 'target_date ASC');
    return maps.map((m) => Alert.fromMap(m)).toList();
  }

  Future<List<Alert>> getUpcomingAlerts(String patientId, String type) async {
    final db = await _dbService.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query('alert',
        where: 'patient_id = ? AND category = ? AND target_date >= ? AND status = ?',
        whereArgs: [patientId, type, now, 'pending'],
        orderBy: 'target_date ASC');
    return maps.map((m) => Alert.fromMap(m)).toList();
  }

  Future<int> getAllPendingCount() async {
    final db = await _dbService.database;
    final maps = await db.rawQuery(
        "SELECT COUNT(*) as c FROM alert WHERE status = ?",
        ['pending']);
    if (maps.isEmpty) return 0;
    return (maps.first['c'] as int?) ?? 0;
  }

  Future<List<Alert>> getAllPending() async {
    final db = await _dbService.database;
    final maps = await db.query('alert',
        where: 'status = ?', whereArgs: ['pending'], orderBy: 'target_date ASC');
    return maps.map((m) => Alert.fromMap(m)).toList();
  }
}
