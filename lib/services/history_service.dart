import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/history_item.dart';

class HistoryService {
  static const String _historyFileName = 'history.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_historyFileName');
  }

  Future<List<HistoryItem>> getHistory() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => HistoryItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addHistoryItem(HistoryItem item) async {
    final items = await getHistory();
    items.insert(0, item);
    await _saveHistory(items);
  }

  Future<void> deleteHistoryItem(String id) async {
    final items = await getHistory();
    items.removeWhere((item) => item.id == id);
    await _saveHistory(items);

    try {
      final item = items.firstWhere((item) => item.id == id);
    final file = File(item.localPath);
    if (await file.exists()) {
      await file.delete();
    }
    } catch (e) {
      // Item not found, ignore
    }
  }

  Future<void> _saveHistory(List<HistoryItem> items) async {
    final file = await _localFile;
    final jsonList = items.map((item) => item.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  bool isFileExists(String path) {
    return File(path).existsSync();
  }
}
