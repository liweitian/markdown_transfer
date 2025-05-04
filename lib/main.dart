import 'package:ai_transfer/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'dart:typed_data';

// 从 util.dart 导入 getTheme 函数
import 'package:ai_transfer/util.dart' show generatePdfBytes, getTheme;

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
      final pdf = pw.Document();
      final theme = await getTheme();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // 只使用基础字体
                pw.Text(
                  'Hello World (basic font)',
                  style: const pw.TextStyle(
                    fontSize: 25,
                  ),
                ),
                pw.SizedBox(height: 20),
                // emoji 测试
                pw.Text(
                  '🐒 💁 👌 🎍 😍 🦊 👨 (pure emoji)',
                  style: const pw.TextStyle(
                    fontSize: 25,
                  ),
                ),
                pw.SizedBox(height: 20),
                // 混合文本测试
                pw.Text(
                  'Hello 🐒 World (mixed)',
                  style: const pw.TextStyle(
                    fontSize: 25,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/document.pdf');
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'AI Transfer生成的PDF文档',
        );
      }
    } catch (e) {
      print('PDF生成错误: ${e.toString()}');
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
                child: _controller.text.isEmpty
                    ? const Center(
                        child: Text('在此粘贴ChatGPT的Markdown文本...'),
                      )
                    : FutureBuilder<Uint8List>(
                        future: generatePdfBytes(_controller.text),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('生成PDF预览失败: ${snapshot.error}'),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: Text('没有PDF数据'),
                            );
                          }
                          return SfPdfViewer.memory(
                            snapshot.data!,
                            enableTextSelection: true,
                          );
                        },
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
