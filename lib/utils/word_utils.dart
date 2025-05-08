import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../common/oss.dart';
import 'common_utils.dart';

class WordUtils {
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
        throw Exception('Upload failed');
      }

      // 3. 调用转换接口
      final response = await _dio.post(
        'http://test.nexy-ai.com:9088/api/v1/nexy/file/convert',
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

          return docxFile;
        }
      }
      throw Exception(
          'transfer failed: ${response.statusCode} - ${response.data}');
    } catch (e) {
      rethrow;
    }
  }
}
