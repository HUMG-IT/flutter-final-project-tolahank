/// Web-compatible settings repository using browser localStorage
class SettingsRepository {
  // Use a simple in-memory store for web demo
  // In production, could use window.localStorage via dart:html
  static final Map<String, String> _store = {};

  String? getValue(String key) => _store[key];

  Future<void> setValue(String key, String value) async {
    _store[key] = value;
  }
}
