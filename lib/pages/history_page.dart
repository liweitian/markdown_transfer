import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../util.dart' show generatePdfBytes;
import '../utils/word_utils.dart';
import '../utils/pptx_utils.dart';
import '../utils/xlsx_utils.dart';
import '../utils/text_utils.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _historyItems = [];
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await _historyService.getHistory();
    setState(() {
      _historyItems = items;
    });
  }

  Future<void> _previewFile(HistoryItem item) async {
    if (item.type == 'Image') {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Image.file(
                    File(item.localPath),
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(item.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareFile(item),
                ),
              ],
            ),
            body: _buildPreviewWidget(item.type, item.rawData, item.localPath),
          ),
        ),
      );
    }
  }

  Widget _buildPreviewWidget(String type, String content, String filePath) {
    switch (type) {
      case 'Image':
        return Image.file(File(filePath));
      default:
        return Markdown(
          data: content,
          selectable: true,
          padding: const EdgeInsets.all(16),
        );
    }
  }

  Future<File> _generateImageFile(String filePath) async {
    return File(filePath);
  }

  Future<void> _deleteHistoryItem(HistoryItem item) async {
    await _historyService.deleteHistoryItem(item.id);
    await _loadHistory();
  }

  Future<void> _shareFile(HistoryItem item) async {
    try {
      final file = File(item.localPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: item.title,
        );
      } else {
        await _generateAndShareFile(item);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Future<void> _generateAndShareFile(HistoryItem item) async {
    try {
      File? generatedFile;
      switch (item.type) {
        case 'PDF':
          final pdfBytes = await generatePdfBytes(item.rawData);
          final directory = await getApplicationDocumentsDirectory();
          generatedFile = File(
              '${directory.path}/preview_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await generatedFile.writeAsBytes(pdfBytes);
          break;
        case 'Word':
          generatedFile =
              await WordUtils.generateWordFromMarkdown(item.rawData);
          break;
        case 'Slides':
          generatedFile =
              await PPTXUtils.generatePPTXFromMarkdown(item.rawData);
          break;
        case 'Sheet':
          generatedFile =
              await XlsxUtils.generateXlsxFromMarkdown(item.rawData);
          break;
        case 'Image':
          generatedFile = await _generateImageFile(item.rawData);
          break;
        case 'Text':
          generatedFile = await TextUtils.generateTextFromContent(item.rawData);
          break;
        default:
          throw Exception('Not Supported: ${item.type}');
      }

      if (generatedFile != null && await generatedFile.exists()) {
        await Share.shareXFiles(
          [XFile(generatedFile.path)],
          text: item.title,
        );
      } else {
        throw Exception('文件生成失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成文件失败: $e')),
        );
      }
    }
  }

  Widget _buildHistoryItem(BuildContext context, HistoryItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(
          item.type == 'PDF'
              ? Icons.picture_as_pdf_outlined
              : item.type == 'Word'
                  ? Icons.description_outlined
                  : item.type == 'Slides'
                      ? Icons.slideshow_outlined
                      : item.type == 'Sheet'
                          ? Icons.table_chart_outlined
                          : item.type == 'Image'
                              ? Icons.image_outlined
                              : Icons.text_fields_outlined,
          color: Colors.blue,
        ),
        title: Text(item.title),
        subtitle: Text('${item.date} · ${item.size}'),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: item.type == 'Image' ? 'save' : 'share',
              child: Row(
                children: [
                  Icon(
                      item.type == 'Image'
                          ? Icons.save_alt_outlined
                          : Icons.share_outlined,
                      color: Colors.blue,
                      size: 20),
                  const SizedBox(width: 12),
                  Text(item.type == 'Image' ? '保存' : '分享'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'share') {
              await _shareFile(item);
            } else if (value == 'save') {
              try {
                // 根据平台检查不同的权限
                bool hasPermission = false;
                if (Platform.isAndroid) {
                  // Android 需要存储权限
                  var status = await Permission.manageExternalStorage.status;
                  if (!status.isGranted) {
                    status = await Permission.manageExternalStorage.request();
                    hasPermission = status.isGranted;
                  } else {
                    hasPermission = true;
                  }
                } else if (Platform.isIOS) {
                  // iOS 需要照片权限
                  var status = await Permission.photos.status;
                  if (!status.isGranted) {
                    status = await Permission.photos.request();
                    hasPermission = status.isGranted;
                  } else {
                    hasPermission = true;
                  }
                }

                if (!hasPermission) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('需要相册权限才能保存图片')),
                    );
                  }
                  return;
                }

                final file = File(item.localPath);
                if (await file.exists()) {
                  final bytes = await file.readAsBytes();
                  final result = await ImageGallerySaver.saveImage(bytes,
                      quality: 100, name: item.title);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('图片已保存到相册')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('保存失败: $e')),
                  );
                }
              }
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('确定要删除这条记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteHistoryItem(item);
                      },
                      child:
                          const Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        onTap: () => _previewFile(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: HistorySearchDelegate(_historyItems),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'All'),
                  _buildFilterChip('PDF', 'PDF'),
                  _buildFilterChip('Word', 'Word'),
                  _buildFilterChip('Slides', 'Slides'),
                  _buildFilterChip('Sheet', 'Sheet'),
                  _buildFilterChip('Image', 'Image'),
                  _buildFilterChip('Text', 'Text'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _historyItems.length,
              itemBuilder: (context, index) {
                final item = _historyItems[index];
                if (_selectedType != 'All' && item.type != _selectedType) {
                  return const SizedBox.shrink();
                }
                return _buildHistoryItem(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedType == value,
        onSelected: (selected) {
          setState(() {
            _selectedType = selected ? value : 'All';
          });
        },
      ),
    );
  }
}

class HistorySearchDelegate extends SearchDelegate<String> {
  final List<HistoryItem> _historyItems;

  HistorySearchDelegate(this._historyItems);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = _historyItems.where((item) {
      return item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.type.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: Icon(
            item.type == 'PDF'
                ? Icons.picture_as_pdf_outlined
                : item.type == 'Word'
                    ? Icons.description_outlined
                    : item.type == 'Slides'
                        ? Icons.slideshow_outlined
                        : item.type == 'Sheet'
                            ? Icons.table_chart_outlined
                            : item.type == 'Image'
                                ? Icons.image_outlined
                                : Icons.text_fields_outlined,
            color: Colors.blue,
          ),
          title: Text(item.title),
          subtitle: Text('${item.date} · ${item.size}'),
          onTap: () {
            close(context, item.id);
          },
        );
      },
    );
  }
}
