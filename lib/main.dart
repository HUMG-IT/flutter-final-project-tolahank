import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home/home_scaffold.dart';
import 'data/db/app_database.dart'
    if (dart.library.html) 'data/db/app_database_stub.dart';
import 'package:flutter/foundation.dart';
import 'data/repositories/settings_repository_selected.dart';
import 'data/migration/migration_service.dart'
    if (dart.library.html) 'data/migration/migration_service_stub.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.open().then((_) {
    debugPrint('DB opened ok');
    runApp(const ProviderScope(child: MainApp()));
  }).catchError((error, stackTrace) {
    debugPrint('Error opening database: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeKey = 'themeMode';
  static const String _quietKey = 'quietMode';
  bool _quietMode = false;
  final SettingsRepository _settings = SettingsRepository();

  void _toggleThemeMode() async {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
    await _settings.setValue(_themeKey, _themeMode.name);
    await _settings.setValue(_quietKey, _quietMode.toString());
  }

  void _toggleQuietMode() async {
    setState(() {
      _quietMode = !_quietMode;
    });
    await _settings.setValue(_quietKey, _quietMode.toString());
    await _settings.setValue(_themeKey, _themeMode.name);
  }

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Run migration once, then seed demo if needed.
      MigrationService().run().then((_) => _seedDemoIfEmpty()).catchError((error, stackTrace) {
        debugPrint('Error during migration: $error');
        debugPrint('Stack trace: $stackTrace');
      });
    });
  }

  Future<void> _loadThemeMode() async {
    try {
      await AppDatabase.open();
      final name = _settings.getValue(_themeKey);
      final quietStr = _settings.getValue(_quietKey);
      if (name != null) {
        setState(() {
          _themeMode = ThemeMode.values.firstWhere(
            (m) => m.name == name,
            orElse: () => ThemeMode.system,
          );
        });
      }
      if (quietStr != null) {
        setState(() {
          _quietMode = quietStr == 'true';
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error loading theme mode: $error');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
      useMaterial3: true,
    );

    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: Builder(
        builder: (context) {
          final actions = [
            IconButton(
              tooltip: _themeMode == ThemeMode.dark ? 'Chế độ sáng' : 'Chế độ tối',
              icon: Icon(_themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleThemeMode,
            ),
            IconButton(
              tooltip: _quietMode ? 'Tắt chế độ yên lặng' : 'Bật chế độ yên lặng',
              icon: Icon(_quietMode ? Icons.notifications_off : Icons.notifications),
              onPressed: _toggleQuietMode,
            ),
          ];
          return HomeScaffold(itemsActions: actions, notesActions: actions, quietMode: _quietMode);
        },
      ),
    );
  }

  Future<void> _seedDemoIfEmpty() async {
    // Skip demo seeding during tests/debug to keep test suite stable
    if (kDebugMode) return;
    final alreadyStr = _settings.getValue('demoSeeded');
    final already = alreadyStr == 'true';
    if (already) return;

    // For now, seed if SQLite tables are empty flags
    final itemsExisting = _settings.getValue('__items_seeded') == 'true';
    final notesExisting = _settings.getValue('__notes_seeded') == 'true';
    final needItems = !itemsExisting;
    final needNotes = !notesExisting;
    if (!needItems && !needNotes) {
      // Mark seeded to avoid future checks.
      await _settings.setValue('demoSeeded', 'true');
      return;
    }
    await _settings.setValue('demoSeeded', 'true');
  }
}
