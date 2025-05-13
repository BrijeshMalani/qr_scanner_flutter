import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryService {
  final SharedPreferences _prefs;
  static const String _historyKey = 'qr_history';

  HistoryService(this._prefs);

  List<HistoryItem> getItems(String type) {
    final String? historyJson = _prefs.getString(_historyKey);
    if (historyJson == null) return [];

    final List<dynamic> historyList = json.decode(historyJson);
    return historyList
        .map((item) => HistoryItem.fromJson(item))
        .where((item) => item.type == type)
        .toList();
  }

  Future<void> addItem(HistoryItem item) async {
    final String? historyJson = _prefs.getString(_historyKey);
    final List<dynamic> historyList =
        historyJson != null ? json.decode(historyJson) : [];

    historyList.insert(0, item.toJson());
    await _prefs.setString(_historyKey, json.encode(historyList));
  }

  Future<void> deleteItem(HistoryItem itemToDelete) async {
    final String? historyJson = _prefs.getString(_historyKey);
    if (historyJson == null) return;

    final List<dynamic> historyList = json.decode(historyJson);
    historyList.removeWhere((item) {
      final historyItem = HistoryItem.fromJson(item);
      return historyItem.date == itemToDelete.date &&
          historyItem.title == itemToDelete.title;
    });

    await _prefs.setString(_historyKey, json.encode(historyList));
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }
}
