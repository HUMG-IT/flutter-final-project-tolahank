import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqlite3/sqlite3.dart' as sqlite;

// Minimal cross-platform database bootstrap using sqlite3.
class AppDatabase {
  static sqlite.Database? _db;

  static sqlite.Database get instance {
    final db = _db;
    if (db == null) {
      throw StateError('AppDatabase not initialized. Call AppDatabase.open().');
    }
    return db;
  }

  static Future<void> open() async {
    if (_db != null) return;

    if (kIsWeb) {
      // On web, use in-memory DB - persistent storage requires additional setup
      _db = sqlite.sqlite3.open(':memory:');
    } else {
      // Mobile/Desktop using native sqlite3 via sqlite3_flutter_libs
      // Use persistent file-based database for both debug and release modes
      final path = _defaultPath('app.db');
      _db = sqlite.sqlite3.open(path);
    }
    _onCreate();
  }

  static void _onCreate() {
    final db = instance;
    // Create tables if not exist: notes, items, settings
    db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        tag TEXT NOT NULL DEFAULT '' ,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 1,
        category TEXT,
        due_at INTEGER
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
  }

  static String _defaultPath(String filename) {
    // Use a simple relative file for now; Flutter path_provider could be added later.
    // On Windows, this will sit next to the executable during dev.
    return filename;
  }

  static void close() {
    _db?.dispose();
    _db = null;
  }
}