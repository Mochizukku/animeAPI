import 'package:shared_preferences/shared_preferences.dart';
import 'storage_adapter_stub.dart'
    if (dart.library.html) 'storage_adapter_web.dart'
    if (dart.library.io) 'storage_adapter_io.dart';

abstract class StorageAdapter {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
}

StorageAdapter getPlatformStorageAdapter([SharedPreferences? prefs]) =>
    createStorageAdapter(prefs);
