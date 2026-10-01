import 'package:shared_preferences/shared_preferences.dart';
import 'storage_adapter.dart';

class IoStorageAdapter implements StorageAdapter {
  final SharedPreferences? _prefs;

  const IoStorageAdapter([this._prefs]);

  @override
  Future<String?> readString(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}

StorageAdapter createStorageAdapter([SharedPreferences? prefs]) =>
    IoStorageAdapter(prefs);
