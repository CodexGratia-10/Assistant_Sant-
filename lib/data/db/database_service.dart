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
      version: 1,
      onCreate: _onCreate,
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
