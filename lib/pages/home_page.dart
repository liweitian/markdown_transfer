import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../utils/image_utils.dart';
import '../utils/file_generator.dart';
import 'dart:ui' as ui;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _contentController = TextEditingController();
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
    _contentFocusNode.addListener(() {
      if (!_contentFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<bool> requestIOSPhotoLibraryPermission() async {
    print("requestIOSPhotoLibraryPermission");
    try {
      // 直接请求权限，这会触发系统弹窗
      var status = await Permission.photos.request();
      print("Permission status: $status");

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，需要引导用户到设置中开启
        if (mounted) {
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Photo Library Permission Required'),
                content: const Text('Please allow access to photo library in settings to save images'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('Settings'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          );

          if (openSettings == true) {
            await openAppSettings();
          }
        }
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Photo library permission required to save images',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
        }
      }
      return false;
    } catch (e) {
      print("Permission request error: $e");
      return false;
    }
  }

  Future<bool> requestAndroidPhotoLibraryPermission() async {
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // 权限被永久拒绝，需要引导用户到设置中开启
      openAppSettings();
    }
    return false;
  }

  Future<void> _generatePDF() async {
    await FileGenerator.generateAndSharePDF(_contentController.text, context);
    //add history item
  }

  Future<void> _generateWord() async {
    await FileGenerator.generateAndShareWord(_contentController.text, context);
     //add history item
  }

  Future<void> _generateXlsx() async {
    await FileGenerator.generateAndShareExcel(_contentController.text, context);
     //add history item
  }

  Future<void> _generatePPTX() async {
    await FileGenerator.generateAndSharePowerPoint(_contentController.text, context);
     //add history item
  }

  Future<void> _generateText() async {
    await FileGenerator.generateAndShareText(_contentController.text, context);
     //add history item
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
                            // 检查权限
                            bool isGranted = false;
                            if (Platform.isAndroid) {
                              isGranted =
                                  await requestAndroidPhotoLibraryPermission();
                            } else if (Platform.isIOS) {
                              isGranted =
                                  await requestIOSPhotoLibraryPermission();
                            }
                            if (!isGranted) {
                              return;
                            }

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
                            print('Save failed: $e');
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

  Widget _buildFormatButton(IconData icon, String label, VoidCallback onTap) {
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
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ));
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
                                _buildFormatButton(Icons.description_outlined,
                                    'Word', _generateWord),
                                _buildFormatButton(
                                    Icons.picture_as_pdf_outlined,
                                    'PDF',
                                    _generatePDF),
                                _buildFormatButton(Icons.slideshow_outlined,
                                    'Slides', _generatePPTX),
                                _buildFormatButton(Icons.table_chart_outlined,
                                    'Sheet', _generateXlsx),
                                _buildFormatButton(Icons.image_outlined,
                                    'Image', _showImagePreviewDrawer),
                                _buildFormatButton(Icons.text_fields_outlined,
                                    'Text', _generateText),
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
