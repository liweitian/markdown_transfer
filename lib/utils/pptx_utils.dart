import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import 'package:dart_pptx/dart_pptx.dart';
import 'package:markdown/markdown.dart' as md;

class PPTXUtils {
  /// 从Markdown内容生成PPTX文档
  static Future<File> generatePPTXFromMarkdown(String markdownContent) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pptxFile = File('${directory.path}/converted_$timestamp.pptx');
      
      // 创建PowerPoint实例
      final pres = PowerPoint();
      
      // 添加幻灯片
      await pres.addSlidesFromMarkdown(markdownContent);
      
      // 设置元数据
      pres.title = '幻灯片演示';
      pres.author = 'AI Transfer';
      pres.company = 'AI Transfer';
      
      // 保存文件
      final bytes = await pres.save();
      if (bytes != null) {
        await pptxFile.writeAsBytes(bytes);
      } else {
        throw Exception('生成PPTX文件失败');
      }
      
      return pptxFile;
    } catch (e) {
      print('生成PPTX文档失败: $e');
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