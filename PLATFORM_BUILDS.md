# Building for Different Platforms

This project uses SQLite for desktop/mobile platforms, which is incompatible with web builds (FFI not supported). To build for different platforms:

## Desktop/Mobile (Windows, Linux, macOS, Android, iOS)

**Default configuration - no changes needed.**

```powershell
flutter pub get
flutter run -d windows  # or linux, macos, android, ios
```

SQLite works out of the box on these platforms.

## Web (Chrome, Edge, etc.)

Web builds require temporarily commenting out SQLite dependencies:

### Option 1: Manual (Recommended)

1. Open `pubspec.yaml`
2. Comment out sqlite3 lines:
   ```yaml
   # sqlite3: ^2.4.0
   # sqlite3_flutter_libs: ^0.5.0
   ```
3. Run:
   ```powershell
   flutter pub get
   flutter run -d chrome
   ```
4. **Important**: Uncomment the lines after web build to restore desktop functionality

### Option 2: PowerShell Script

```powershell
# Build for web
(Get-Content pubspec.yaml) -replace '^  sqlite3:', '  # sqlite3:' -replace '^  sqlite3_flutter_libs:', '  # sqlite3_flutter_libs:' | Set-Content pubspec.yaml
flutter pub get
flutter run -d chrome

# Restore for desktop (run after web build)
(Get-Content pubspec.yaml) -replace '^  # sqlite3:', '  sqlite3:' -replace '^  # sqlite3_flutter_libs:', '  sqlite3_flutter_libs:' | Set-Content pubspec.yaml
flutter pub get
```

## Why This Is Necessary

- **Desktop/Mobile**: Use SQLite via FFI (Foreign Function Interface) for persistent storage
- **Web**: FFI not supported in browsers; app uses in-memory storage for demo purposes
- Flutter's dependency system doesn't support platform-specific dependencies in `pubspec.yaml`
- The conditional imports (`if (dart.library.html)`) handle code-level separation, but dependencies must be managed manually

## Web Limitations

When running on web:
- Data is stored in-memory only (not persistent across sessions)
- Settings, items, and notes are lost on page refresh
- Fully functional for demonstration purposes
- For production web apps, consider using IndexedDB, Hive, or a backend API
