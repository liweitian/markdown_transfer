import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:io';
import '../utils/image_utils.dart';
import '../utils/file_generator.dart';
import 'dart:ui' as ui;

class HomePage extends StatefulWidget {
  final TextEditingController contentController;
  const HomePage({super.key, required this.contentController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  int _selectedThemeIndex = 0;
  ui.Image? _previewImage;
  bool _isPreviewing = false;
  double _fontSize = 32.0;
  String _selectedFont = 'Roboto';

  final List<String> _availableFonts = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Georgia',
    'Verdana',
    'Helvetica',
    'Tahoma',
    'Trebuchet MS',
    'Impact',
  ];

  @override
  void initState() {
    super.initState();
    _contentController = widget.contentController;
    _contentFocusNode.addListener(() {
      if (!_contentFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveFile(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to save file: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
      }
    }
  }

  Future<void> _previewFile(String type) async {
    if (_contentController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please input content',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }
    if (type == 'Image') {
      _showImagePreviewDrawer();
      return;
    }
    File? file;

    EasyLoading.show(status: 'Generating...', dismissOnTap: true);
    switch (type) {
      case 'PDF':
        file =
            await FileGenerator.generatePDF(_contentController.text, context);
        break;
      case 'Word':
        file =
            await FileGenerator.generateWord(_contentController.text, context);
        break;
      case 'Slides':
        file = await FileGenerator.generatePowerPoint(
            _contentController.text, context);
        break;
      case 'Sheet':
        file =
            await FileGenerator.generateExcel(_contentController.text, context);
        break;
      case 'Text':
        file =
            await FileGenerator.generateText(_contentController.text, context);
        break;
      default:
    }
    EasyLoading.dismiss();

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
                      "Preview",
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
                    data: _contentController.text,
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
                              if (file != null) {
                                await _saveFile(file);
                                Navigator.pop(context);
                              }
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
                            onPressed: () => {
                              if (file != null)
                                {
                                  Share.shareXFiles(
                                    [XFile(file.path)],
                                    // text: '$type file generated by Transforma',
                                  )
                                }
                            },
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

  Future<void> _generatePreviewImage({int? themeIndex}) async {
    setState(() {
      _isPreviewing = true;
    });
    final img = await ImageUtils.previewImageFromText(
      _contentController.text,
      kImageThemes[themeIndex ?? _selectedThemeIndex],
      fontSize: _fontSize,
      fontFamily: _selectedFont,
    );
    setState(() {
      _previewImage = img;
      if (themeIndex != null) _selectedThemeIndex = themeIndex;
      _isPreviewing = false;
    });
  }

  void _showImagePreviewDrawer() async {
    if (_contentController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'input content',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }
    await _generatePreviewImage();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 2 / 3,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Image Preview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_isPreviewing)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_previewImage != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: RawImage(
                          image: _previewImage,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton(
                        icon: Icons.palette_outlined,
                        label: 'Theme',
                        onTap: () {
                          showModalBottomSheet(
                            barrierColor: Colors.transparent,
                            context: context,
                            builder: (context) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Select Theme',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 200,
                                      child: GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 2.5,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                        itemCount: kImageThemes.length,
                                        itemBuilder: (context, index) {
                                          final theme = kImageThemes[index];
                                          return GestureDetector(
                                            onTap: () async {
                                              setModalState(() {
                                                _isPreviewing = true;
                                              });
                                              final img = await ImageUtils
                                                  .previewImageFromText(
                                                _contentController.text,
                                                theme,
                                                fontSize: _fontSize,
                                              );
                                              setModalState(() {
                                                _previewImage = img;
                                                _selectedThemeIndex = index;
                                                _isPreviewing = false;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    theme.backgroundColors[0],
                                                border: Border.all(
                                                  color: Colors.transparent,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  theme.name,
                                                  style: TextStyle(
                                                      color: theme.textColor),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.format_size,
                        label: 'Font Size',
                        onTap: () {
                          _showFontSizeDrawer(setModalState);
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.font_download,
                        label: 'Font',
                        onTap: () {
                          _showFontDrawer(setModalState);
                        },
                      ),
                      _buildOptionButton(
                        icon: Icons.save_alt,
                        label: 'Save',
                        onTap: () async {
                          try {
                            await FileGenerator.generateAndSaveImage(
                              _contentController.text,
                              _selectedThemeIndex,
                              _fontSize,
                              _selectedFont,
                              context,
                              (isLoading) {
                                setModalState(() {
                                  _isPreviewing = isLoading;
                                });
                              },
                            );
                          } catch (e) {
                            Fluttertoast.showToast(
                              msg: 'Save failed: $e',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFontSizeDrawer(StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Adjust Font Size',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          if (_fontSize > 16) {
                            setModalState(() {
                              _isPreviewing = true;
                            });
                            final img = await ImageUtils.previewImageFromText(
                              _contentController.text,
                              kImageThemes[_selectedThemeIndex],
                              fontSize: _fontSize - 2,
                            );
                            setModalState(() {
                              _previewImage = img;
                              _isPreviewing = false;
                            });
                            setState(() {
                              _fontSize -= 2;
                            });
                          }
                        },
                      ),
                      Text(
                        '${_fontSize.toInt()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          if (_fontSize < 40) {
                            setModalState(() {
                              _isPreviewing = true;
                            });
                            final img = await ImageUtils.previewImageFromText(
                              _contentController.text,
                              kImageThemes[_selectedThemeIndex],
                              fontSize: _fontSize + 2,
                            );
                            setModalState(() {
                              _previewImage = img;
                              _isPreviewing = false;
                            });
                            setState(() {
                              _fontSize += 2;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _fontSize,
                    min: 16,
                    max: 48,
                    divisions: 16,
                    label: _fontSize.toInt().toString(),
                    onChanged: (value) async {
                      setModalState(() {
                        _isPreviewing = true;
                      });
                      final img = await ImageUtils.previewImageFromText(
                        _contentController.text,
                        kImageThemes[_selectedThemeIndex],
                        fontSize: value,
                      );
                      setModalState(() {
                        _previewImage = img;
                        _isPreviewing = false;
                      });
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFontDrawer(StateSetter setModalState) {
    showModalBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Font',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableFonts.length,
                      itemBuilder: (context, index) {
                        final font = _availableFonts[index];
                        return ListTile(
                          title: Text(
                            'Hello, world!',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(font),
                          selected: font == _selectedFont,
                          onTap: () async {
                            setModalState(() {
                              _isPreviewing = true;
                            });
                            final img = await ImageUtils.previewImageFromText(
                              _contentController.text,
                              kImageThemes[_selectedThemeIndex],
                              fontSize: _fontSize,
                              fontFamily: font,
                            );
                            setModalState(() {
                              _previewImage = img;
                              _isPreviewing = false;
                            });
                            setState(() {
                              _selectedFont = font;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue[700]),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildPasteButton(TextEditingController controller) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            controller.clear();
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear, size: 16, color: Colors.red[700]),
                const SizedBox(width: 4),
                Text('Clear', style: TextStyle(color: Colors.red[700])),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            ClipboardData? data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
              controller.text = data.text!;
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text('Paste', style: TextStyle(color: Colors.blue[700])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              _buildPasteButton(controller),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: controller,
            focusNode: _contentFocusNode,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Enter main content',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatButton(IconData icon, String type) {
    return GestureDetector(
      onTap: () => _previewFile(type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue[700]),
          ),
          const SizedBox(height: 4),
          Text(type, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Transforma'),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildInputSection(
                            'Main Content', _contentController),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Format',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Click icon to convert',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildFormatButton(
                                    Icons.description_outlined, 'Word'),
                                _buildFormatButton(
                                    Icons.picture_as_pdf_outlined, 'PDF'),
                                // _buildFormatButton(
                                //     Icons.slideshow_outlined, 'Slides'),
                                _buildFormatButton(
                                    Icons.table_chart_outlined, 'Sheet'),
                                _buildFormatButton(
                                    Icons.image_outlined, 'Image'),
                                _buildFormatButton(
                                    Icons.text_fields_outlined, 'Text'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
