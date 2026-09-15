import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/qr_record.dart';

class AppState extends ChangeNotifier {
  static const _historyKey = 'qrly_history_v1';
  static const _themeKey = 'qrly_dark_mode';

  List<QrRecord> _records = [];
  bool _darkMode = false;
  bool _loaded = false;

  List<QrRecord> get records => List.unmodifiable(_records);
  bool get darkMode => _darkMode;
  bool get loaded => _loaded;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _darkMode = preferences.getBool(_themeKey) ?? false;
    final rawHistory = preferences.getString(_historyKey);
    if (rawHistory != null) {
      try {
        _records = QrRecord.decodeAll(rawHistory);
      } catch (_) {
        _records = [];
      }
    }
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _darkMode = !_darkMode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themeKey, _darkMode);
  }

  Future<void> addRecord(QrRecord record) async {
    _records = [record, ..._records.where((item) => item.value != record.value)];
    if (_records.length > 100) _records = _records.take(100).toList();
    notifyListeners();
    await _saveHistory();
  }

  Future<void> removeRecord(String id) async {
    _records = _records.where((record) => record.id != id).toList();
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _records = [];
    notifyListeners();
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_historyKey, QrRecord.encodeAll(_records));
  }
}

