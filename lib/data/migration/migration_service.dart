import '../repositories/settings_repository_selected.dart';
import '../db/app_database.dart';

class MigrationService {
  final SettingsRepository _settings;
  // Localstore removed; migration from Localstore disabled.

  MigrationService({
    SettingsRepository? settings,
  })  : _settings = settings ?? SettingsRepository(),
        super();

  Future<void> run() async {
    await AppDatabase.open();
    final flag = _settings.getValue('isMigratedToSqlite');
    if (flag == 'true') return;

    // Localstore removed; no-op migration.

    await _settings.setValue('isMigratedToSqlite', 'true');
  }
}