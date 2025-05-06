import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import 'package:dio/dio.dart';
import '../common/oss.dart';

class WordUtils {
  static final HistoryService _historyService = HistoryService();
  static final Dio _dio = Dio();

  /// 从Markdown内容生成Word文档
  static Future<File> generateWordFromMarkdown(String markdownContent) async {
    try {
      // 1. 创建临时文件并上传到OSS
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempMdFile = File('${directory.path}/temp_$timestamp.md');
      await tempMdFile.writeAsString(markdownContent);

      // 2. 上传到OSS
      final ossObject = await Oss.uploadToOss(tempMdFile);
      if (ossObject == null) {
        throw Exception('上传OSS失败');
      }

      // 3. 调用转换接口
      final response = await _dio.post(
        'http://192.168.18.197:9088/api/v1/nexy/file/convert',
        data: {
          'file_url': ossObject.url,
          'target_format': 'docx',
        },
      );

      // 4. 删除临时Markdown文件
      await tempMdFile.delete();

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['data'] != null) {
          // 5. 下载转换后的文件
          final convertedFileUrl = result['data'];
          final docxResponse = await _dio.get(
            convertedFileUrl,
            options: Options(responseType: ResponseType.bytes),
          );

          // 6. 保存为本地文件
          final docxFile = File('${directory.path}/converted_$timestamp.docx');
          await docxFile.writeAsBytes(docxResponse.data);

          // 7. 添加到历史记录
          final now = DateTime.now();
          final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          
          final historyItem = HistoryItem(
            id: timestamp.toString(),
            title: '文档转换_$timestamp',
            date: date,
            size: _formatFileSize(docxFile.lengthSync()),
            type: 'Word',
            localPath: docxFile.path,
          );

          await _historyService.addHistoryItem(historyItem);
          
          return docxFile;
        }
      }
      throw Exception('文件转换失败: ${response.statusCode} - ${response.data}');
    } catch (e) {
      print('生成Word文档失败: $e');
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
