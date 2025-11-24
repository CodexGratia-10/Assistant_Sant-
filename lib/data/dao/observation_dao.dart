import 'package:sqflite/sqflite.dart';
import '../models/symptom_observation.dart';
import '../models/vital_sign.dart';
import '../models/malaria_rdt.dart';
import '../db/database_service.dart';

class ObservationDao {
  final DatabaseService _dbService = DatabaseService.instance;

  // Symptom Observations
  Future<void> insertSymptom(SymptomObservation symptom) async {
    final db = await _dbService.database;
    await db.insert('symptom_observation', symptom.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SymptomObservation>> getSymptomsByVisitId(String visitId) async {
    final db = await _dbService.database;
    final maps = await db.query('symptom_observation',
        where: 'visit_id = ?', whereArgs: [visitId]);
    return maps.map((m) => SymptomObservation.fromMap(m)).toList();
  }

  // Vital Signs
  Future<void> insertVitalSign(VitalSign vital) async {
    final db = await _dbService.database;
    await db.insert('vital_sign', vital.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<VitalSign>> getVitalSignsByVisitId(String visitId) async {
    final db = await _dbService.database;
    final maps = await db.query('vital_sign',
        where: 'visit_id = ?', whereArgs: [visitId]);
    return maps.map((m) => VitalSign.fromMap(m)).toList();
  }

  // Malaria RDT
  Future<void> insertMalariaRDT(MalariaRDT rdt) async {
    final db = await _dbService.database;
    await db.insert('malaria_rdt', rdt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<MalariaRDT?> getMalariaRDTByVisitId(String visitId) async {
    final db = await _dbService.database;
    final maps = await db.query('malaria_rdt',
        where: 'visit_id = ?', whereArgs: [visitId]);
    if (maps.isEmpty) return null;
    return MalariaRDT.fromMap(maps.first);
  }
}
