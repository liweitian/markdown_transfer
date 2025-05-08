import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dart_pptx/dart_pptx.dart';
import 'common_utils.dart';

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
      pres.title = 'Slides';
      pres.author = 'AI Transfer';
      pres.company = 'AI Transfer';

      // 保存文件
      final bytes = await pres.save();
      if (bytes != null) {
        await pptxFile.writeAsBytes(bytes);
      } else {
        throw Exception('Generate PPTX failed');
      }

      return pptxFile;
    } catch (e) {
      rethrow;
    }
  }
}
