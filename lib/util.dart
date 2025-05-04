import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:markdown/markdown.dart' as md;
import 'dart:typed_data';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

Future<Uint8List> generatePdfBytes(String markdownText) async {
  final pdf = pw.Document();

  // 准备内容
  List<pw.Widget> pdfWidgets = [];

  try {
    // 尝试解析Markdown
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
    );

    // 预处理文本，确保换行符统一
    final processedText =
        markdownText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 预处理任务列表
    final processedLines = processedText.split('\n').map((line) {
      if (line.trim().startsWith('- [ ]')) {
        return line.replaceFirst('- [ ]', '* [ ]');
      } else if (line.trim().startsWith('- [x]') ||
          line.trim().startsWith('- [X]')) {
        return line.replaceFirst(RegExp(r'- \[[xX]\]'), '* [x]');
      }
      return line;
    }).join('\n');

    final nodes = document.parseLines(processedLines.split('\n'));

    for (var node in nodes) {
      if (node is md.Element) {
        switch (node.tag) {
          case 'h1':
            pdfWidgets.add(
              pw.Container(
                child: pw.Text(
                  node.textContent,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            break;
          case 'h2':
            pdfWidgets.add(
              pw.Container(
                child: pw.Text(
                  node.textContent,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            break;
          case 'h3':
            pdfWidgets.add(
              pw.Container(
                child: pw.Text(
                  node.textContent,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            break;
          case 'a':
            pdfWidgets.add(
              pw.UrlLink(
                destination: node.attributes['href'] ?? '',
                child: pw.Text(
                  node.textContent,
                  style: const pw.TextStyle(
                      color: PdfColors.blue,
                      decoration: pw.TextDecoration.underline),
                ),
              ),
            );
            break;
          case 'img':
            final imageUrl = node.attributes['src'];
            if (imageUrl != null) {
              try {
                final image = await networkImage(imageUrl);
                pdfWidgets.add(
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      child: pw.Image(
                        image,
                        width: 200,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                );
              } catch (e) {
                // 添加一个占位文本说明图片加载失败
                pdfWidgets.add(
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      border: pw.Border.all(color: PdfColors.grey),
                    ),
                    child: pw.Text(
                      'load Error: $imageUrl',
                      style: const pw.TextStyle(
                        color: PdfColors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }
            }
            break;
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
              List<String> headers = [];
              if (headerRow.children != null &&
                  headerRow.children!.isNotEmpty) {
                var headerCells = headerRow.children!.first;
                if (headerCells is md.Element && headerCells.children != null) {
                  headers = headerCells.children!
                      .whereType<md.Element>()
                      .map((cell) => cell.textContent.trim())
                      .toList();
                }
              }

              // 提取表格数据
              List<List<String>> data = [];
              if (bodyRows.children != null) {
                for (var row in bodyRows.children!) {
                  if (row is md.Element && row.children != null) {
                    var rowData = row.children!
                        .whereType<md.Element>()
                        .map((cell) => cell.textContent.trim())
                        .toList();
                    data.add(rowData);
                  }
                }
              }

              // 创建表格
              if (headers.isNotEmpty || data.isNotEmpty) {
                pdfWidgets.add(
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headers: headers,
                    data: data,
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellPadding: const pw.EdgeInsets.all(5),
                    cellAlignment: pw.Alignment.center,
                  ),
                );
              }
            }
            break;
          case 'hr':
            pdfWidgets.add(pw.Divider());
            break;
          case 'ul':
          case 'ol':
            pdfWidgets.add(_buildList(node));
            break;
          case 'blockquote':
            if (node.children != null) {
              pdfWidgets.add(
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.grey, width: 2)),
                    color: PdfColors.grey200,
                  ),
                  padding: const pw.EdgeInsets.all(8),
                  margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: node.children!
                        .whereType<md.Element>()
                        .map((e) => _buildList(e))
                        .toList(),
                  ),
                ),
              );
            }
            break;
          case 'footnote':
            // 需要自定义处理脚注的逻辑
            break;
          case 'emoji':
            // 需要自定义处理Emoji的逻辑
            break;
          case 'html':
            final document = html_parser.parse(node.textContent);
            // 解析HTML并转换为PDF组件
            break;
          case 'p':
            if (node.children != null) {
              final spans = <pw.TextSpan>[];
              bool hasImage = false;

              for (var child in node.children!) {
                if (child is md.Element) {
                  switch (child.tag) {
                    case 'a':
                      spans.add(
                        pw.TextSpan(
                          text: child.textContent,
                          style: const pw.TextStyle(
                            color: PdfColors.blue,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      );
                      break;
                    case 'img':
                      hasImage = true;
                      final imageUrl = child.attributes['src'];
                      if (imageUrl != null) {
                        try {
                          final image = await networkImage(imageUrl);
                          pdfWidgets.add(
                            pw.Center(
                              child: pw.Container(
                                padding:
                                    const pw.EdgeInsets.symmetric(vertical: 8),
                                child: pw.Image(
                                  image,
                                  width: 400,
                                  fit: pw.BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          pdfWidgets.add(
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                border: pw.Border.all(color: PdfColors.grey),
                              ),
                              child: pw.Text(
                                '图片加载失败: $imageUrl',
                                style: pw.TextStyle(
                                  color: PdfColors.red,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                      break;
                    case 'strong':
                      spans.add(
                        pw.TextSpan(
                          text: child.textContent,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      );
                      break;
                    case 'em':
                      spans.add(
                        pw.TextSpan(
                          text: child.textContent,
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                        ),
                      );
                      break;
                    case 'del':
                      spans.add(
                        pw.TextSpan(
                          text: child.textContent,
                          style: pw.TextStyle(
                              decoration: pw.TextDecoration.lineThrough),
                        ),
                      );
                      break;
                    case 'code':
                      spans.add(
                        pw.TextSpan(
                          text: child.textContent,
                          style: pw.TextStyle(
                            font: pw.Font.courier(),
                            background:
                                pw.BoxDecoration(color: PdfColors.grey200),
                          ),
                        ),
                      );
                      break;
                    default:
                      spans.add(
                        pw.TextSpan(
                          text: child.textContent,
                        ),
                      );
                  }
                } else if (child is md.Text) {
                  spans.add(
                    pw.TextSpan(
                      text: child.text,
                    ),
                  );
                }
              }

              // 只有当段落中没有图片时才添加文本内容
              if (!hasImage && spans.isNotEmpty) {
                pdfWidgets.add(
                  pw.Container(
                    child: pw.RichText(
                      text: pw.TextSpan(children: spans),
                    ),
                  ),
                );
              }
            }
            break;
          case 'pre':
            if (node.children != null && node.children!.isNotEmpty) {
              var codeNode = node.children!.first;
              if (codeNode is md.Element && codeNode.tag == 'code') {
                // 获取语言标识
                String? language =
                    codeNode.attributes['class']?.replaceFirst('language-', '');

                pdfWidgets.add(
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (language != null)
                          pw.Container(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              language,
                              style: pw.TextStyle(
                                color: PdfColors.grey700,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        pw.Text(
                          codeNode.textContent,
                          style: pw.TextStyle(
                            font: pw.Font.courier(),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                break;
              }
            }
            pdfWidgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  node.textContent,
                  style: pw.TextStyle(
                    font: pw.Font.courier(),
                    fontSize: 10,
                  ),
                ),
              ),
            );
            break;
          default:
            if (node.textContent.trim().isNotEmpty) {
              pdfWidgets.add(
                pw.Container(
                  child: pw.Text(
                    node.textContent,
                  ),
                ),
              );
            }
        }
        // 添加段落间距
        pdfWidgets.add(pw.SizedBox(height: 8));
      }
    }
  } catch (e) {
    pdfWidgets.add(
      pw.Container(
        child: pw.Text(
          markdownText,
        ),
      ),
    );
  }

  // 如果没有内容，添加原始文本
  if (pdfWidgets.isEmpty) {
    pdfWidgets.add(
      pw.Container(
        child: pw.Text(
          markdownText,
        ),
      ),
    );
  }

  // 创建PDF页面，使用MultiPage实现自动分页
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pdfWidgets,
    ),
  );

  final Uint8List pdfBytes = await pdf.save();

  return pdfBytes;
}

// 添加一个辅助函数来处理列表
pw.Widget _buildList(md.Element node, {int level = 0}) {
  if (node.children == null) {
    return pw.Container();
  }

  List<pw.Widget> items = [];
  int index = 1; // 用于有序列表的编号

  for (var child in node.children!) {
    if (child is md.Element && child.tag == 'li') {
      print('列表项属性: ${child.attributes}');
      print('列表项标签: ${child.tag}');
      print('列表项内容: ${child.children}');
      var bulletText = node.tag == 'ol' ? '${index++}.' : '-';
      var content = <pw.Widget>[];

      // 处理列表项的文本内容和嵌套列表
      var textContent = '';
      var nestedItems = <pw.Widget>[];
      bool isChecked = false;

      for (var grandChild in child.children!) {
        if (grandChild is md.Text) {
          textContent = grandChild.text.trim();
        } else if (grandChild is md.Element) {
          if (grandChild.tag == 'ul' || grandChild.tag == 'ol') {
            nestedItems.add(_buildList(grandChild, level: level + 1));
          } else if (grandChild.tag == 'input' &&
              grandChild.attributes['type'] == 'checkbox') {
            isChecked = grandChild.attributes['checked'] == 'true';
          } else {
            textContent += grandChild.textContent;
          }
        }
      }

      // 计算当前级别的缩进（每级4个空格）
      final indentWidth = level * 20.0;

      // 添加主要文本
      if (textContent.isNotEmpty) {
        content.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: indentWidth),
              // if (!isTaskItem)
              pw.Container(
                width: 20,
                child: pw.Text(bulletText),
              ),

              pw.Container(
                width: 20,
                child: pw.Text(
                  isChecked ? '[x]' : '[  ]',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  textContent.trim(),
                ),
              ),
            ],
          ),
        );
      }

      // 添加嵌套列表
      content.addAll(nestedItems);

      items.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: content,
        ),
      );
    }
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: items,
  );
}

// 修改 networkImage 函数
Future<pw.ImageProvider> networkImage(String url) async {
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception('图片数据为空');
      }
      return pw.MemoryImage(bytes);
    } else {
      throw Exception('图片下载失败: HTTP ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}
