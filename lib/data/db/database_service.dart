import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'assistant_sante.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Load and execute schema
    final schema = await rootBundle.loadString('lib/data/db/schema.sql');
    final statements = schema.split(';').where((s) => s.trim().isNotEmpty);
    
    for (final statement in statements) {
      await db.execute(statement.trim());
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add patient demographic fields if missing
      await _addColumnIfMissing(db, 'patient', 'first_name', 'TEXT');
      await _addColumnIfMissing(db, 'patient', 'last_name', 'TEXT');
      await _addColumnIfMissing(db, 'patient', 'phone', 'TEXT');
    }
  }

  Future<void> _addColumnIfMissing(Database db, String table, String column, String type) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => (row['name'] as String?) == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> resetDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'assistant_sante.db');
    await deleteDatabase(path);
    _database = null;
  }
}
