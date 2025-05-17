import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:math';
import 'dart:ui' as ui;

import '../util.dart' show generatePdfBytes;
import 'word_utils.dart';
import 'xlsx_utils.dart';
import 'pptx_utils.dart';
import 'text_utils.dart';
import 'image_utils.dart';
import 'history_utils.dart';

class FileGenerator {
  /// 生成并分享PDF文件
  static Future<File?> generatePDF(String content, BuildContext context) async {
    if (content.isEmpty) {
      _showToast('Please enter content');
      return null;
    }

    try {
      final pdfBytes = await generatePdfBytes(content);
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await HistoryUtils.addFileToHistory(
        file: file,
        title: "PDF_${content.substring(0, min(content.length, 20))}",
        rawData: content,
        type: 'PDF',
      );

      return file;
    } catch (e) {
      _showToast('Failed to generate PDF: $e');
      return null;
    }
  }

  /// 生成并分享Word文件
  static Future<File?> generateWord(
      String content, BuildContext context) async {
    if (content.isEmpty) {
      _showToast('Please enter content');
      return null;
    }

    try {
      final file = await WordUtils.generateWordFromMarkdown(content);
      await HistoryUtils.addFileToHistory(
        file: file,
        title: "Word_${content.substring(0, min(content.length, 20))}",
        rawData: content,
        type: 'Word',
      );
      return file;
    } catch (e) {
      _showToast('Failed to generate Word document: $e');
      return null;
    }
  }

  /// 生成并分享Excel文件
  static Future<File?> generateExcel(
      String content, BuildContext context) async {
    if (content.isEmpty) {
      _showToast('Please enter content');
      return null;
    }

    try {
      final file = await XlsxUtils.generateXlsxFromMarkdown(content);
      await HistoryUtils.addFileToHistory(
        file: file,
        title: "Sheet_${content.substring(0, min(content.length, 20))}",
        rawData: content,
        type: 'Sheet',
      );

      return file;
    } catch (e) {
      print('Failed to generate Excel document: $e');
      _showToast('Failed to generate Excel document: $e');
      return null;
    }
  }

  /// 生成并分享PowerPoint文件
  static Future<File?> generatePowerPoint(
      String content, BuildContext context) async {
    if (content.isEmpty) {
      _showToast('Please enter content');
      return null;
    }

    try {
      final file = await PPTXUtils.generatePPTXFromMarkdown(content);
      await HistoryUtils.addFileToHistory(
        file: file,
        title: "Slides_${content.substring(0, min(content.length, 20))}",
        rawData: content,
        type: 'Slides',
      );

      return file;
    } catch (e) {
      _showToast('Failed to generate PowerPoint document: $e');
    }
    return null;
  }

  /// 生成并分享文本文件
  static Future<File?> generateText(
      String content, BuildContext context) async {
    if (content.isEmpty) {
      _showToast('Please enter content');
      return null;
    }

    try {
      final file = await TextUtils.generateTextFromContent(content);
      await HistoryUtils.addFileToHistory(
        file: file,
        title: "Text_${content.substring(0, min(content.length, 20))}",
        rawData: content,
        type: 'Text',
      );

      return file;
    } catch (e) {
      _showToast('Failed to generate Text document: $e');
    }
    return null;
  }

  /// 生成并保存图片
  static Future<void> generateAndSaveImage(
    String content,
    int themeIndex,
    double fontSize,
    String fontFamily,
    BuildContext context,
    Function(bool) onLoadingChanged,
  ) async {
    if (content.isEmpty) {
      _showToast('Please enter content');
      return;
    }

    try {
      onLoadingChanged(true);
      final image = await ImageUtils.previewImageFromText(
        content,
        kImageThemes[themeIndex],
        fontSize: fontSize,
        fontFamily: fontFamily,
      );

      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = bytes!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: "transforma_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess']) {
        _showToast('Image saved to gallery');
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            "transforma_${DateTime.now().millisecondsSinceEpoch}.png";
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        await HistoryUtils.addFileToHistory(
          file: file,
          title: 'Image_${DateTime.now().millisecondsSinceEpoch}',
          rawData: content,
          type: 'Image',
        );
      } else {
        _showToast('Save failed');
      }
    } catch (e) {
      print('Failed to generate image: $e');
      _showToast('Failed to generate image: $e');
    } finally {
      onLoadingChanged(false);
    }
  }

  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
