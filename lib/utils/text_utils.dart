import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';

class TextUtils {
  static final _historyService = HistoryService();

  static Future<File> generateTextFromContent(String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fileName =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content, encoding: Encoding.getByName('utf-8')!);
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final date = DateTime.now().toIso8601String();
    
    final historyItem = HistoryItem(
      id: timestamp.toString(),
      title: 'text_$timestamp',
      date: date,
      size: _formatFileSize(file.lengthSync()),
      type: 'Text',
      localPath: file.path,  
      rawData: content
    );

    await _historyService.addHistoryItem(historyItem);
    
    return file;
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
