import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../util.dart' show generatePdfBytes;
import '../utils/pdf_utils.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _historyItems = [];
  String _searchQuery = '';
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
    if (!_historyService.isFileExists(item.localPath)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File does not exist')),
      );
      return;
    }

    final file = File(item.localPath);
    final content = await file.readAsString();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(item.title),
          ),
          body: _buildPreviewWidget(item.type, item.localPath, content),
        ),
      ),
    );
  }

  Widget _buildPreviewWidget(String type, String filePath, String content) {
    switch (type) {
      case 'PDF':
        return PDFView(filePath: filePath);
      case 'Word':
      case 'Text':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(content),
        );
      case 'Markdown':
        return Markdown(data: content);
      default:
        return Center(
          child: Text('Preview not supported for ${type} files'),
        );
    }
  }

  Future<void> _deleteHistoryItem(HistoryItem item) async {
    await _historyService.deleteHistoryItem(item.id);
    await _loadHistory();
  }

  Future<void> _regeneratePDF(HistoryItem item) async {
    try {
      // 显示加载提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Regenerating PDF file...')),
        );
      }

      // 重新生成PDF
      final pdfBytes = await generatePdfBytes(item.title);

      // 保存到原来的位置
      final file = File(item.localPath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file has been regenerated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate PDF: $e')),
        );
      }
    }
  }

  Future<void> _sharePDF(HistoryItem item) async {
    final file = File(item.localPath);
    if (!await file.exists()) {
      // 如果文件不存在，重新生成
      await _regeneratePDF(item);
      // 再次检查文件是否生成成功
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cannot share: File generation failed')),
          );
        }
        return;
      }
    }

    // 分享文件
    await Share.shareXFiles(
      [XFile(item.localPath)],
      text: item.title,
    );
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
            const PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_outlined, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Text('Share'),
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
              await _sharePDF(item);
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text(
                      'Are you sure you want to delete this record?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
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

  Widget _buildFilterChip(String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = isSelected ? 'All' : type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _historyItems.where((item) {
      final matchesSearch =
          item.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == 'All' || item.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  ...['Word', 'PDF', 'Slides', 'Sheet', 'Image', 'Text']
                      .map((type) => _buildFilterChip(type)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) =>
                  _buildHistoryItem(context, filteredItems[index]),
            ),
          ),
        ],
      ),
    );
  }
}
