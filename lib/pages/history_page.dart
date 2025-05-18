import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    child: Markdown(
                      data: item.rawData,
                      selectable: true,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _saveFile(item);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.save_rounded, size: 20),
                              label: const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () => _shareFile(item),
                              icon: const Icon(Icons.share_rounded, size: 20),
                              label: const Text(
                                'Share',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
        await Share.shareXFiles([XFile(file.path)]);
      } else {
        await _generateAndShareFile(item);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Failed to share file: $e');
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
          // text: item.title,
        );
      } else {
        throw Exception('Failed to generate file');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Failed to generate file: $e');
      }
    }
  }

  Future<void> _saveFile(HistoryItem item) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      File? savedFile;

      // 如果本地文件已存在，直接复制
      final existingFile = File(item.localPath);
      if (await existingFile.exists()) {
        final newPath =
            '${directory.path}/saved_${DateTime.now().millisecondsSinceEpoch}_${item.title}';
        savedFile = await existingFile.copy(newPath);
      } else {
        // 如果本地文件不存在，重新生成
        switch (item.type) {
          case 'PDF':
            final pdfBytes = await generatePdfBytes(item.rawData);
            savedFile = File(
                '${directory.path}/saved_${DateTime.now().millisecondsSinceEpoch}.pdf');
            await savedFile.writeAsBytes(pdfBytes);
            break;
          case 'Word':
            savedFile = await WordUtils.generateWordFromMarkdown(item.rawData);
            break;
          case 'Slides':
            savedFile = await PPTXUtils.generatePPTXFromMarkdown(item.rawData);
            break;
          case 'Sheet':
            savedFile = await XlsxUtils.generateXlsxFromMarkdown(item.rawData);
            break;
          case 'Image':
            final bytes = await File(item.localPath).readAsBytes();
            final result = await ImageGallerySaver.saveImage(bytes,
                quality: 100, name: item.title);
            if (result['isSuccess']) {
              Fluttertoast.showToast(msg: 'Image saved to gallery');
            } else {
              Fluttertoast.showToast(
                msg: 'Please grant permission to save image',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
              );
              openAppSettings();
            }
            return;
          case 'Text':
            savedFile = await TextUtils.generateTextFromContent(item.rawData);
            break;
          default:
            throw Exception('Unsupported file type: ${item.type}');
        }
      }

      if (savedFile != null && await savedFile.exists()) {
        if (mounted) {
          Fluttertoast.showToast(msg: 'File saved to: ${savedFile.path}');
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Failed to save file: $e');
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
                  Text(item.type == 'Image' ? 'Save' : 'Share'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'share') {
              await _shareFile(item);
            } else if (value == 'save') {
              final file = File(item.localPath);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                final result = await ImageGallerySaver.saveImage(bytes,
                    quality: 100, name: item.title);
                if (mounted) {
                  Fluttertoast.showToast(msg: 'Image saved to gallery');
                }
              }
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm delete'),
                  content: const Text('Confirm to delete this record?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteHistoryItem(item);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
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
        title: const Text('History Record'),
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
                  // _buildFilterChip('Slides', 'Slides'),
                  _buildFilterChip('Sheet', 'Sheet'),
                  _buildFilterChip('Image', 'Image'),
                  _buildFilterChip('Text', 'Text'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _historyItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_outlined,
                            size: 80,
                            color: Colors.blue[300],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No History Records',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _historyItems.length,
                    itemBuilder: (context, index) {
                      final item = _historyItems[index];
                      if (_selectedType != 'All' &&
                          item.type != _selectedType) {
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
