import 'dart:io';
import '../models/history_item.dart';
import '../services/history_service.dart';
import 'common_utils.dart';

class HistoryUtils {
  static final HistoryService _historyService = HistoryService();

  /// 添加文件到历史记录
  static Future<void> addFileToHistory({
    required File file,
    required String title,
    required String rawData,
    required String type,
  }) async {
    try {
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final historyItem = HistoryItem(
        id: timestamp.toString(),
        title: title,
        date: date,
        size: CommonUtils.formatFileSize(file.lengthSync()),
        type: type,
        rawData: rawData,
        localPath: file.path,
      );

      await _historyService.addHistoryItem(historyItem);
    } catch (e) {
      print('添加历史记录失败: $e');
      rethrow;
    }
  }
} 