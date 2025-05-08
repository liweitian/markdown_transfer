import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:markdown/markdown.dart' as md;
import '../models/history_item.dart';
import '../services/history_service.dart';

class XlsxUtils {
  /// 从Markdown内容生成Excel文件
  static Future<File> generateXlsxFromMarkdown(String markdownContent) async {
    try {
      // 创建Excel实例
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // 解析Markdown内容
      final document = md.Document(
        extensionSet: md.ExtensionSet.gitHubWeb,
        encodeHtml: false,
      );

      final nodes = document.parse(markdownContent);
      int currentRow = 0;

      for (var node in nodes) {
        if (node is md.Element) {
          switch (node.tag) {
            case 'h1':
            case 'h2':
            case 'h3':
            case 'h4':
            case 'h5':
            case 'h6':
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
                .value = node.textContent;
              currentRow++;
              break;
            case 'p':
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
                .value = node.textContent;
              currentRow++;
              break;
            case 'ul':
            case 'ol':
              _processListItems(node, sheet, currentRow);
              currentRow += node.children?.length ?? 0;
              break;
            case 'table':
              _processTable(node, sheet, currentRow);
              currentRow += (node.children?.length ?? 0) + 1;
              break;
          }
        }
      }

      // 保存文件
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/converted_$timestamp.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      return file;
    } catch (e) {
      print('生成Excel文件失败: $e');
      rethrow;
    }
  }

  /// 处理列表项
  static void _processListItems(md.Element node, Sheet sheet, int startRow) {
    int currentRow = startRow;
    if (node.children == null) return;

    for (var child in node.children!) {
      if (child is md.Element && child.tag == 'li') {
        // 添加列表标记
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = '• ${child.textContent}';
        currentRow++;
      }
    }
  }

  /// 处理表格
  static void _processTable(md.Element node, Sheet sheet, int startRow) {
    if (node.children == null) return;
    int currentRow = startRow;

    for (var child in node.children!) {
      if (child is md.Element && child.tag == 'tr') {
        int currentCol = 0;
        for (var cell in child.children ?? []) {
          if (cell is md.Element && (cell.tag == 'td' || cell.tag == 'th')) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: currentCol, rowIndex: currentRow))
              .value = cell.textContent;
            currentCol++;
          }
        }
        currentRow++;
      }
    }
  }
} 