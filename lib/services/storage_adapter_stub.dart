import 'package:shared_preferences/shared_preferences.dart';
import 'storage_adapter.dart';

StorageAdapter createStorageAdapter([SharedPreferences? prefs]) =>
    throw UnsupportedError('Unsupported platform storage');
