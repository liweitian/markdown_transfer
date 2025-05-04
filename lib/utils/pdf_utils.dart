import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';

class PDFUtils {
  static final HistoryService _historyService = HistoryService();

  /// 保存PDF文件并添加到历史记录
  static Future<void> savePDFAndAddToHistory({
    required File pdfFile,
    required String title,
    String type = 'PDF',
  }) async {
    try {
      // 获取文件大小
      final fileSize = await pdfFile.length();
      final formattedSize = _formatFileSize(fileSize);

      // 获取当前日期
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 创建唯一ID
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      // 创建历史记录项
      final historyItem = HistoryItem(
        id: id,
        title: title,
        date: date,
        size: formattedSize,
        type: type,
        localPath: pdfFile.path,
      );

      // 保存到历史记录
      await _historyService.addHistoryItem(historyItem);
    } catch (e) {
      print('保存历史记录失败: $e');
      rethrow;
    }
  }

  /// 格式化文件大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 