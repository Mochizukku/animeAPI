// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_adapter.dart';

class WebStorageAdapter implements StorageAdapter {
  const WebStorageAdapter();

  @override
  Future<String?> readString(String key) async {
    try {
      final direct = html.window.localStorage[key];
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }
      final prefKey = 'flutter.$key';
      final flutterPref = html.window.localStorage[prefKey];
      if (flutterPref != null && flutterPref.isNotEmpty) {
        return flutterPref;
      }
    } catch (e) {
      debugPrint('WebStorage read error: $e');
    }
    return null;
  }

  @override
  Future<void> writeString(String key, String value) async {
    try {
      html.window.localStorage[key] = value;
      html.window.localStorage['flutter.$key'] = value;
    } catch (e) {
      debugPrint('WebStorage write error: $e');
    }
  }
}

StorageAdapter createStorageAdapter([SharedPreferences? _]) =>
    const WebStorageAdapter();
