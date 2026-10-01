import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/anime.dart';
import 'storage_adapter.dart';

class StorageService {
  final StorageAdapter? _adapter;

  const StorageService({StorageAdapter? adapter}) : _adapter = adapter;

  StorageAdapter get _effectiveAdapter =>
      _adapter ?? getPlatformStorageAdapter();

  static const String _watchHistoryKey = 'watch_history';
  static const String _savedAnimeKey = 'saved_anime';

  Future<List<Anime>> loadWatchHistory() async {
    try {
      final raw = await _effectiveAdapter.readString(_watchHistoryKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Anime.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading watch history: $e');
    }
    return [];
  }

  Future<void> saveWatchHistory(List<Anime> history) async {
    try {
      final raw = jsonEncode(history.map((a) => a.toJson()).toList());
      await _effectiveAdapter.writeString(_watchHistoryKey, raw);
    } catch (e) {
      debugPrint('Error saving watch history: $e');
    }
  }

  Future<List<Anime>> loadSavedAnime() async {
    try {
      final raw = await _effectiveAdapter.readString(_savedAnimeKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Anime.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading saved anime: $e');
    }
    return [];
  }

  Future<void> saveSavedAnime(List<Anime> savedList) async {
    try {
      final raw = jsonEncode(savedList.map((a) => a.toJson()).toList());
      await _effectiveAdapter.writeString(_savedAnimeKey, raw);
    } catch (e) {
      debugPrint('Error saving saved anime: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _effectiveAdapter.writeString(_watchHistoryKey, '[]');
      await _effectiveAdapter.writeString(_savedAnimeKey, '[]');
    } catch (e) {
      debugPrint('Error clearing local data: $e');
    }
  }
}
