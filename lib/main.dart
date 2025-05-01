import 'package:ai_transfer/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:markdown/markdown.dart' as md;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Transfer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generatePDF() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入Markdown文本')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // 生成PDF字节
      final pdfBytes = await generatePdfBytes(_controller.text);

      // 保存到文件
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/document.pdf');
      await file.writeAsBytes(pdfBytes);
      print(await file.length());
      // 分享文件
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'AI Transfer生成的PDF文档',
        );
      }
    } catch (e) {
      print('生成PDF失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成PDF失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _test() async {
    try {
      setState(() {
        _isGenerating = true;
      });

      print('开始测试图片加载...');
      final pdf = pw.Document();

      print('开始加载网络图片...');
      final imageUrl =
          "https://nexy-sg.oss-ap-southeast-1.aliyuncs.com/img/2e4360b0-2642-11f0-83a5-e314b62e961a.png";
      try {
        final image = await networkImage(imageUrl);
        print('图片加载成功，开始生成PDF页面...');

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Center(
                child: pw.Image(image),
              );
            },
          ),
        );

        print('PDF页面生成完成');
      } catch (e) {
        print('图片处理失败: $e');
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border.all(color: PdfColors.grey),
                  ),
                  child: pw.Text(
                    '图片加载失败: $imageUrl\n错误: $e',
                    style: const pw.TextStyle(
                      color: PdfColors.red,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }

      print('保存PDF...');
      final Uint8List pdfBytes = await pdf.save();

      print('写入文件...');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/document.pdf');
      await file.writeAsBytes(pdfBytes);

      print('分享文件...');
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'AI Transfer生成的PDF文档',
        );
      }
      print('测试完成');
    } catch (e) {
      print('测试过程中出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('测试失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Transfer'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: '在此粘贴ChatGPT的Markdown文本...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Markdown(
                  data: _controller.text,
                  selectable: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isGenerating ? null : _generatePDF,
                    child: Text(_isGenerating ? '生成中...' : '生成PDF'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _controller.clear();
                    },
                    child: const Text('清空'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      ClipboardData? data =
                          await Clipboard.getData('text/plain');
                      if (data != null) {
                        _controller.text = data.text ?? '';
                      }
                      setState(() {});
                    },
                    child: const Text('粘贴'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      _test();
                    },
                    child: const Text('测试'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
