// Skeleton for SettingsRepository; will implement after Notes.
import 'package:sqlite3/sqlite3.dart' as sqlite;
import '../db/app_database.dart';

class SettingsRepository {
  sqlite.Database get _db => AppDatabase.instance;

  Future<void> setValue(String key, String? value) async {
    _db.execute('INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value', [key, value]);
  }

  String? getValue(String key) {
    final rows = _db.select('SELECT value FROM settings WHERE key = ?', [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }
}