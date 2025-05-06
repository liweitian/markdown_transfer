import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:markdown/markdown.dart' as md;
import '../models/history_item.dart';
import '../services/history_service.dart';

class XlsxUtils {
  static final HistoryService _historyService = HistoryService();

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
            case 'table':
              if (node.children != null && node.children!.isNotEmpty) {
                // 处理表头
                var headerRow = node.children!.firstWhere(
                  (child) => child is md.Element && child.tag == 'thead',
                  orElse: () => md.Element('thead', []),
                ) as md.Element;

                // 处理表格内容
                var bodyRows = node.children!.firstWhere(
                  (child) => child is md.Element && child.tag == 'tbody',
                  orElse: () => md.Element('tbody', []),
                ) as md.Element;

                // 提取表头数据
                if (headerRow.children != null && headerRow.children!.isNotEmpty) {
                  var headerCells = headerRow.children!.first;
                  if (headerCells is md.Element && headerCells.children != null) {
                    var headers = headerCells.children!
                        .whereType<md.Element>()
                        .map((cell) => cell.textContent.trim())
                        .toList();
                    
                    // 写入表头
                    for (var i = 0; i < headers.length; i++) {
                      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
                        ..value = headers[i]
                        ..cellStyle = CellStyle(
                          bold: true,
                          backgroundColorHex: '#E0E0E0',
                        );
                    }
                    currentRow++;
                  }
                }

                // 提取表格数据
                if (bodyRows.children != null) {
                  for (var row in bodyRows.children!) {
                    if (row is md.Element && row.children != null) {
                      var rowData = row.children!
                          .whereType<md.Element>()
                          .map((cell) => cell.textContent.trim())
                          .toList();
                      
                      // 写入行数据
                      for (var i = 0; i < rowData.length; i++) {
                        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
                          .value = rowData[i];
                      }
                      currentRow++;
                    }
                  }
                }
              }
              break;
            case 'h1':
            case 'h2':
            case 'h3':
              // 将标题作为单独的行
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
                ..value = node.textContent
                ..cellStyle = CellStyle(
                  bold: true,
                  fontSize: node.tag == 'h1' ? 16 : (node.tag == 'h2' ? 14 : 12),
                );
              currentRow++;
              break;
            case 'p':
              // 将段落作为单独的行
              if (node.textContent.trim().isNotEmpty) {
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
                  .value = node.textContent;
                currentRow++;
              }
              break;
            case 'ul':
            case 'ol':
              // 处理列表
              _processListItems(node, sheet, currentRow);
              currentRow += node.children?.length ?? 0;
              break;
          }
        }
      }

      // 保存Excel文件
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/converted_$timestamp.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      // 添加到历史记录
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final historyItem = HistoryItem(
        id: timestamp.toString(),
        title: '文档转换_$timestamp',
        date: date,
        size: _formatFileSize(file.lengthSync()),
        type: 'Sheet',
        localPath: file.path,
      );

      await _historyService.addHistoryItem(historyItem);
      
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

  /// 格式化文件大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 