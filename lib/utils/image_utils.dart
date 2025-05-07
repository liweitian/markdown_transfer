import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:markdown/markdown.dart' as md;

class ImageThemeStyle {
  final List<Color> backgroundColors;
  final Color textColor;
  final String name;
  final double shadowOpacity;
  final double borderRadius;

  const ImageThemeStyle({
    required this.backgroundColors,
    required this.textColor,
    required this.name,
    this.shadowOpacity = 0.1,
    this.borderRadius = 16.0,
  });
}

const List<ImageThemeStyle> kImageThemes = [
  ImageThemeStyle(
    name: '晴空',
    backgroundColors: [
      Color(0xFFE3F2FD),
      Color(0xFFBBDEFB),
    ],
    textColor: Color(0xFF1565C0),
    shadowOpacity: 0.15,
  ),
  ImageThemeStyle(
    name: '暖阳',
    backgroundColors: [
      Color(0xFFFFF3E0),
      Color(0xFFFFE0B2),
    ],
    textColor: Color(0xFFE65100),
    shadowOpacity: 0.12,
  ),
  ImageThemeStyle(
    name: '樱色',
    backgroundColors: [
      Color(0xFFFCE4EC),
      Color(0xFFF8BBD0),
    ],
    textColor: Color(0xFFC2185B),
    shadowOpacity: 0.1,
  ),
  ImageThemeStyle(
    name: '晨露',
    backgroundColors: [
      Color(0xFFE0F7FA),
      Color(0xFFB2EBF2),
    ],
    textColor: Color(0xFF00838F),
    shadowOpacity: 0.1,
  ),
  ImageThemeStyle(
    name: '森林',
    backgroundColors: [
      Color(0xFFE8F5E9),
      Color(0xFFC8E6C9),
    ],
    textColor: Color(0xFF2E7D32),
    shadowOpacity: 0.1,
  ),
  ImageThemeStyle(
    name: '暮色',
    backgroundColors: [
      Color(0xFFEDE7F6),
      Color(0xFFD1C4E9),
    ],
    textColor: Color(0xFF4527A0),
    shadowOpacity: 0.15,
  ),
  ImageThemeStyle(
    name: '极光',
    backgroundColors: [
      Color(0xFFE0F2F1),
      Color(0xFFB2DFDB),
    ],
    textColor: Color(0xFF00695C),
    shadowOpacity: 0.1,
  ),
  ImageThemeStyle(
    name: '珊瑚',
    backgroundColors: [
      Color(0xFFFFEBEE),
      Color(0xFFFFCDD2),
    ],
    textColor: Color(0xFFC62828),
    shadowOpacity: 0.12,
  ),
];

class ImageUtils {
  static List<TextSpan> _parseMarkdownToTextSpans(String markdownText, Color textColor) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
    );

    // 预处理文本，确保换行符统一
    final processedText = markdownText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

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
    final spans = <TextSpan>[];

    void processNode(md.Node node) {
      if (node is md.Text) {
        spans.add(TextSpan(
          text: node.text,
          style: TextStyle(
            color: textColor,
            fontSize: 32,
          ),
        ));
      } else if (node is md.Element) {
        switch (node.tag) {
          case 'strong':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ));
            break;
          case 'em':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontStyle: FontStyle.italic,
              ),
            ));
            break;
          case 'h1':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ));
            spans.add(const TextSpan(text: '\n\n'));
            break;
          case 'h2':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ));
            spans.add(const TextSpan(text: '\n\n'));
            break;
          case 'h3':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ));
            spans.add(const TextSpan(text: '\n\n'));
            break;
          case 'p':
            if (node.children != null) {
              for (var child in node.children!) {
                processNode(child);
              }
              spans.add(const TextSpan(text: '\n\n'));
            }
            break;
          case 'br':
            spans.add(const TextSpan(text: '\n'));
            break;
          case 'ul':
          case 'ol':
            if (node.children != null) {
              for (var child in node.children!) {
                if (child is md.Element && child.tag == 'li') {
                  final text = child.textContent;
                  if (text.startsWith('[ ]')) {
                    spans.add(TextSpan(
                      text: '☐ ${text.substring(3).trim()}\n',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                      ),
                    ));
                  } else if (text.startsWith('[x]')) {
                    spans.add(TextSpan(
                      text: '☑ ${text.substring(3).trim()}\n',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                      ),
                    ));
                  } else {
                    spans.add(TextSpan(
                      text: '• ${text}\n',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                      ),
                    ));
                  }
                }
              }
              spans.add(const TextSpan(text: '\n'));
            }
            break;
          case 'blockquote':
            if (node.children != null) {
              spans.add(const TextSpan(text: '> '));
              for (var child in node.children!) {
                processNode(child);
              }
              spans.add(const TextSpan(text: '\n\n'));
            }
            break;
          case 'code':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontFamily: 'monospace',
                backgroundColor: Colors.grey.withOpacity(0.2),
              ),
            ));
            break;
          case 'pre':
            if (node.children != null) {
              spans.add(const TextSpan(text: '\n'));
              for (var child in node.children!) {
                processNode(child);
              }
              spans.add(const TextSpan(text: '\n\n'));
            }
            break;
          default:
            if (node.children != null) {
              for (var child in node.children!) {
                processNode(child);
              }
            }
        }
      }
    }

    for (var node in nodes) {
      processNode(node);
    }

    return spans;
  }

  static Future<File> generateImageFromText(String text, ImageThemeStyle theme) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double width = 800;
    const double padding = 40.0;
    
    final textSpans = _parseMarkdownToTextSpans(text, theme.textColor);
    final textPainter = TextPainter(
      text: TextSpan(children: textSpans),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    
    textPainter.layout(maxWidth: width - padding);
    final height = textPainter.height + padding;
    
    // 创建渐变背景
    final rect = Rect.fromLTWH(0, 0, width, height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: theme.backgroundColors,
      ).createShader(rect);

    // 绘制圆角矩形背景
    final rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(theme.borderRadius),
    );
    canvas.drawRRect(rRect, paint);

    // 添加阴影效果
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(theme.shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRRect(rRect, shadowPaint);

    // 绘制文本
    textPainter.paint(canvas, const Offset(20, 20));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/generated_image.png');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  static Future<ui.Image> previewImageFromText(String text, ImageThemeStyle theme) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double width = 800;
    const double padding = 40.0;
    
    final textSpans = _parseMarkdownToTextSpans(text, theme.textColor);
    final textPainter = TextPainter(
      text: TextSpan(children: textSpans),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    
    textPainter.layout(maxWidth: width - padding);
    final height = textPainter.height + padding;
    
    // 创建渐变背景
    final rect = Rect.fromLTWH(0, 0, width, height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: theme.backgroundColors,
      ).createShader(rect);

    // 绘制圆角矩形背景
    final rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(theme.borderRadius),
    );
    canvas.drawRRect(rRect, paint);

    // 添加阴影效果
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(theme.shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRRect(rRect, shadowPaint);

    // 绘制文本
    textPainter.paint(canvas, const Offset(20, 20));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    return img;
  }
} 