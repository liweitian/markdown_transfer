import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'common_utils.dart';

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
    name: 'Clear Sky',
    backgroundColors: [
      Color(0xFFE3F2FD),
      Color(0xFFBBDEFB),
    ],
    textColor: Color(0xFF1565C0),
    shadowOpacity: 0.15,
  ),
  ImageThemeStyle(
    name: 'Warm Sun',
    backgroundColors: [
      Color(0xFFFFF3E0),
      Color(0xFFFFE0B2),
    ],
    textColor: Color(0xFFE65100),
    shadowOpacity: 0.12,
  ),
  ImageThemeStyle(
    name: 'Cherry Blossom',
    backgroundColors: [
      Color(0xFFFCE4EC),
      Color(0xFFF8BBD0),
    ],
    textColor: Color(0xFFC2185B),
    shadowOpacity: 0.1,
  ),
  ImageThemeStyle(
    name: 'Morning Dew',
    backgroundColors: [
      Color(0xFFE0F7FA),
      Color(0xFFB2EBF2),
    ],
    textColor: Color(0xFF00838F),
    shadowOpacity: 0.1,
  ),
  ImageThemeStyle(
    name: 'Forest',
    backgroundColors: [
      Color(0xFFE8F5E9),
      Color(0xFFC8E6C9),
    ],
    textColor: Color(0xFF2E7D32),
    shadowOpacity: 0.1,
  ),
  ImageThemeStyle(
    name: 'Dusk',
    backgroundColors: [
      Color(0xFFEDE7F6),
      Color(0xFFD1C4E9),
    ],
    textColor: Color(0xFF4527A0),
    shadowOpacity: 0.15,
  ),
  ImageThemeStyle(
    name: 'Aurora',
    backgroundColors: [
      Color(0xFFE0F2F1),
      Color(0xFFB2DFDB),
    ],
    textColor: Color(0xFF00695C),
    shadowOpacity: 0.1,
  ),
  ImageThemeStyle(
    name: 'Coral',
    backgroundColors: [
      Color(0xFFFFEBEE),
      Color(0xFFFFCDD2),
    ],
    textColor: Color(0xFFC62828),
    shadowOpacity: 0.12,
  ),
];

class ImageUtils {
  static List<TextSpan> _parseMarkdownToTextSpans(
      String markdownText, Color textColor,
      [double? fontSize, String? fontFamily]) {
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
    final spans = <TextSpan>[];

    void processNode(md.Node node) {
      if (node is md.Text) {
        spans.add(TextSpan(
          text: node.text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize ?? 32,
            fontFamily: fontFamily,
          ),
        ));
      } else if (node is md.Element) {
        switch (node.tag) {
          case 'strong':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize ?? 32,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
              ),
            ));
            break;
          case 'em':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize ?? 32,
                fontStyle: FontStyle.italic,
                fontFamily: fontFamily,
              ),
            ));
            break;
          case 'h1':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize ?? 40,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
              ),
            ));
            spans.add(const TextSpan(text: '\n\n'));
            break;
          case 'h2':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize ?? 36,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
              ),
            ));
            spans.add(const TextSpan(text: '\n\n'));
            break;
          case 'h3':
            spans.add(TextSpan(
              text: node.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize ?? 34,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
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
                        fontSize: fontSize ?? 32,
                        fontFamily: fontFamily,
                      ),
                    ));
                  } else if (text.startsWith('[x]')) {
                    spans.add(TextSpan(
                      text: '☑ ${text.substring(3).trim()}\n',
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize ?? 32,
                        fontFamily: fontFamily,
                      ),
                    ));
                  } else {
                    spans.add(TextSpan(
                      text: '• ${text}\n',
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize ?? 32,
                        fontFamily: fontFamily,
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
                fontSize: fontSize ?? 32,
                fontFamily: 'Courier',
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

  static Future<ui.Image> previewImageFromText(
      String text, ImageThemeStyle theme,
      {double fontSize = 32.0, String? fontFamily}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double width = 800;
    const double padding = 40.0;
    const double cardPadding = 20.0;

    final textSpans =
        _parseMarkdownToTextSpans(text, theme.textColor, fontSize, fontFamily);
    final textPainter = TextPainter(
      text: TextSpan(children: textSpans),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    textPainter.layout(maxWidth: width - padding - cardPadding * 2);
    final height = textPainter.height + padding + cardPadding * 2;

    // 创建外层渐变背景
    final outerRect = Rect.fromLTWH(0, 0, width, height);
    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: theme.backgroundColors,
      ).createShader(outerRect);

    // 绘制外层圆角矩形背景
    final outerRRect = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(theme.borderRadius),
    );
    canvas.drawRRect(outerRRect, outerPaint);

    // 添加外层阴影效果
    final outerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(theme.shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRRect(outerRRect, outerShadowPaint);

    // 创建内层背景（白色半透明）
    final innerRect = Rect.fromLTWH(
      cardPadding,
      cardPadding,
      width - cardPadding * 2,
      height - cardPadding * 2,
    );
    final innerPaint = Paint()..color = Colors.white.withOpacity(0.9);

    // 绘制内层圆角矩形背景
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(theme.borderRadius - 4),
    );
    canvas.drawRRect(innerRRect, innerPaint);

    // 添加内层阴影效果
    final innerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(innerRRect, innerShadowPaint);

    // 绘制文本（考虑内层padding）
    textPainter.paint(canvas, const Offset(cardPadding * 2, cardPadding * 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    return img;
  }
}
