import 'package:sqflite/sqflite.dart';
import '../data/db/database_service.dart';

class SyncService {
  final DatabaseService _dbService = DatabaseService.instance;
  
  // Configuration serveur (à adapter)
  static const String serverUrl = 'https://api.sante-benin.org';
  static const int batchSize = 50;

  Future<List<Map<String, dynamic>>> getPendingSyncEvents() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'sync_event',
      where: 'status IN (?, ?)',
      whereArgs: ['queued', 'error'],
      orderBy: 'created_at ASC',
      limit: batchSize,
    );
    return maps;
  }

  Future<void> queueForSync(String entity, String entityId, String operation) async {
    final db = await _dbService.database;
    await db.insert('sync_event', {
      'id': '${entity}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      'entity': entity,
      'entity_id': entityId,
      'op': operation,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'status': 'queued',
    });
  }

  Future<Map<String, dynamic>> preparePayload() async {
    final db = await _dbService.database;
    
    // Récupérer données à synchroniser
    final visits = await db.query(
      'visit',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    // Anonymiser données sensibles
    final anonymizedVisits = visits.map((v) {
      return {
        'visit_id': v['id'],
        'patient_pseudo_id': _hashPatientId(v['patient_id'] as String),
        'started_at': v['started_at'],
        'outcome': v['outcome'],
        'referral_flag': v['referral_flag'],
      };
    }).toList();

    return {
      'source': 'assistant_sante_mobile',
      'timestamp': DateTime.now().toIso8601String(),
      'visits': anonymizedVisits,
    };
  }

  String _hashPatientId(String patientId) {
    // Simple hash pour pseudo-anonymisation
    return patientId.hashCode.toRadixString(36);
  }

  Future<bool> syncToServer() async {
    try {
      final events = await getPendingSyncEvents();
      if (events.isEmpty) return true;

      await preparePayload();
      
      // TODO: Implémenter appel HTTP réel
      // final response = await http.post(
      //   Uri.parse('$serverUrl/sync'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode(payload),
      // );

      // Simuler succès pour l'instant
      await _markEventsSynced(events.map((e) => e['id'] as String).toList());
      
      return true;
    } catch (e) {
      print('Sync error: $e');
      return false;
    }
  }

  Future<void> _markEventsSynced(List<String> eventIds) async {
    final db = await _dbService.database;
    final batch = db.batch();
    
    for (final id in eventIds) {
      batch.update(
        'sync_event',
        {
          'status': 'done',
          'processed_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<Map<String, int>> getSyncStats() async {
    final db = await _dbService.database;
    
    final queued = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_event WHERE status = ?', ['queued']),
    ) ?? 0;
    
    final done = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_event WHERE status = ?', ['done']),
    ) ?? 0;
    
    final error = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_event WHERE status = ?', ['error']),
    ) ?? 0;

    return {
      'queued': queued,
      'done': done,
      'error': error,
    };
  }
}
