import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDFMerge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MyHomePage(title: 'Remix : Document Tools'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<PlatformFile> selectedFiles = [];
  bool isLoading = false;
  String outputFileName = 'new_document';
  String currentAction =
      'idle'; // To track current action: 'merge', 'docx_to_pdf'
  late TextEditingController _outputController;

  // New variables for encryption
  bool enableEncryption = false;
  String pdfPassword = '';
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  // Colors for the document icons
  final List<Color> docColors = [Colors.blue, Colors.red, Colors.green];

  @override
  void initState() {
    super.initState();
    _outputController = TextEditingController(text: outputFileName);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _outputController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Remix',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.picture_as_pdf, size: 48),
                children: [
                  const Text(
                    'Document tools for merging PDFs and converting DOCX to PDF.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Document icons and action buttons when no files are selected
                if (selectedFiles.isEmpty)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // First row - PDF Merge (blue, red, green)
                        _buildActionButton(
                          icons: [Colors.blue, Colors.red, Colors.green],
                          label: 'Select PDF files for merging',
                          onPressed: () => _pickFiles('pdf', 'merge'),
                        ),
                        const SizedBox(height: 40),
                        // Second row - DOCX to PDF (blue, red)
                        _buildActionButton(
                          icons: [Colors.blue, Colors.red],
                          label: 'Convert DOCX to PDF',
                          onPressed: () => _pickFiles('docx', 'docx_to_pdf'),
                        ),
                      ],
                    ),
                  ),

                // File list with colored document icons
                if (selectedFiles.isNotEmpty) ...[
                  Text(
                    'Selected Files (${selectedFiles.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ReorderableListView.builder(
                        itemCount: selectedFiles.length,
                        itemBuilder: (context, index) {
                          // Use the colored document icons
                          return ListTile(
                            key: Key('$index'),
                            leading: _buildDocumentIcon(
                              docColors[index % docColors.length],
                              40,
                            ),
                            title: Text(selectedFiles[index].name),
                            subtitle: Text(
                              '${(selectedFiles[index].size / 1024).toStringAsFixed(2)} KB',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      selectedFiles.removeAt(index);
                                      if (selectedFiles.isEmpty) {
                                        currentAction = 'idle';
                                      }
                                    });
                                  },
                                ),
                                if (currentAction == 'merge')
                                  const Icon(Icons.drag_handle),
                              ],
                            ),
                          );
                        },
                        onReorder: (int oldIndex, int newIndex) {
                          if (currentAction == 'merge') {
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = selectedFiles.removeAt(oldIndex);
                              selectedFiles.insert(newIndex, item);
                            });
                          }
                          // If not in 'merge' mode, do nothing
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Output filename
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Output Filename',
                      hintText: 'Enter a name for your document',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.edit_document),
                      suffixText: '.pdf',
                    ),
                    controller: _outputController,
                    onChanged: (value) {
                      outputFileName = value;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Encryption options (new addition)
                  if (currentAction == 'merge') ...[
                    Row(
                      children: [
                        Checkbox(
                          value: enableEncryption,
                          onChanged: (value) {
                            setState(() {
                              enableEncryption = value ?? false;
                              if (!enableEncryption) {
                                _passwordController.clear();
                              }
                            });
                          },
                        ),
                        const Text('Encrypt PDF with password'),
                      ],
                    ),

                    if (enableEncryption) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter password for encryption',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        onChanged: (value) {
                          pdfPassword = value;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: This password will be required to open the PDF',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ],

                // Action button
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      switch (currentAction) {
                        case 'merge':
                          combinePDF();
                          break;
                        case 'docx_to_pdf':
                          convertDocxToPdf();
                          break;
                      }
                    },
                    icon: Icon(_getActionIcon()),
                    label: Text(_getActionButtonText()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Clear selection button when files are selected
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedFiles = [];
                        currentAction = 'idle';
                        enableEncryption = false;
                        _passwordController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear selection'),
                  ),
                ],
              ],
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    _buildLoadingAnimation(),
                    const SizedBox(height: 8),
                    Text(
                      _getLoadingText(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to build action buttons with document icons
  Widget _buildActionButton({
    required List<Color> icons,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < icons.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: GestureDetector(
                  onTap: onPressed,
                  child: _buildDocumentIcon(icons[i], 80),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  // Helper method to get the appropriate loading animation based on current action
  Widget _buildLoadingAnimation() {
    switch (currentAction) {
      case 'merge':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDocumentIcon(Colors.blue, 24),
            const Icon(Icons.add, color: Colors.white),
            _buildDocumentIcon(Colors.red, 24),
            const Icon(Icons.arrow_forward, color: Colors.white),
            _buildDocumentIcon(Colors.green, 24),
          ],
        );
      case 'docx_to_pdf':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDocumentIcon(Colors.blue, 24),
            const Icon(Icons.arrow_forward, color: Colors.white),
            _buildDocumentIcon(Colors.red, 24),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  // Helper method to get loading text based on current action
  String _getLoadingText() {
    switch (currentAction) {
      case 'merge':
        return enableEncryption
            ? 'Merging and encrypting PDFs...'
            : 'Merging PDFs...';
      case 'docx_to_pdf':
        return 'Converting DOCX to PDF...';
      default:
        return 'Processing...';
    }
  }

  // Helper method to get action button text based on current action
  String _getActionButtonText() {
    switch (currentAction) {
      case 'merge':
        return enableEncryption ? 'Combine & Encrypt PDFs' : 'Combine PDFs';
      case 'docx_to_pdf':
        return 'Convert to PDF';
      default:
        return 'Process Files';
    }
  }

  // Helper method to get action icon based on current action
  IconData _getActionIcon() {
    switch (currentAction) {
      case 'merge':
        return enableEncryption ? Icons.enhanced_encryption : Icons.merge_type;
      case 'docx_to_pdf':
        return Icons.swap_horiz;
      default:
        return Icons.arrow_forward;
    }
  }

  // Custom widget to build document icons like in your images
  Widget _buildDocumentIcon(Color color, double size) {
    return CustomPaint(
      size: Size(size, size * 1.3),
      painter: DocumentIconPainter(color),
    );
  }

  Future<void> _pickFiles(String fileType, String action) async {
    List<String> allowedExtensions;
    if (fileType == 'pdf') {
      allowedExtensions = ['pdf'];
    } else if (fileType == 'docx') {
      allowedExtensions = ['doc', 'docx'];
    } else {
      allowedExtensions = ['pdf', 'doc', 'docx'];
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: action == 'merge',
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFiles = result.files;
        currentAction = action;
        // Set default output filename based on action
        if (action == 'docx_to_pdf') {
          String originalName = result.files.first.name;
          outputFileName = originalName.substring(
            0,
            originalName.lastIndexOf('.'),
          );
          _outputController.text = outputFileName;
        } else {
          outputFileName = 'merged_document';
          _outputController.text = outputFileName;
        }
      });
    }
  }

  Future<void> combinePDF() async {
    if (selectedFiles.isEmpty) return;

    // Validate password if encryption is enabled
    if (enableEncryption && pdfPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password for encryption'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create a new PDF document.
      PdfDocument newDocument = PdfDocument();
      PdfSection? section;

      for (PlatformFile file in selectedFiles) {
        if (file.path == null) continue;

        // Load the PDF document from the selected file path.
        PdfDocument loadedDocument = PdfDocument(
          inputBytes: File(file.path!).readAsBytesSync(),
        );

        // Export the pages to the new document.
        for (int index = 0; index < loadedDocument.pages.count; index++) {
          PdfTemplate template = loadedDocument.pages[index].createTemplate();

          if (section == null || section.pageSettings.size != template.size) {
            section = newDocument.sections!.add();
            section.pageSettings.size = template.size;
            section.pageSettings.margins.all = 0;
          }

          section.pages.add().graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
          );
        }

        loadedDocument.dispose();
      }

      // Apply encryption if enabled
      if (enableEncryption && pdfPassword.isNotEmpty) {
        // Set the security options
        PdfSecurity security = newDocument.security;

        // Use AES 128-bit encryption (more secure than RC4)
        security.algorithm = PdfEncryptionAlgorithm.aesx128Bit;

        // Set the user password (required to open the document)
        security.userPassword = pdfPassword;
      }

      // Save the combined document.
      List<int> bytes = await newDocument.save();
      newDocument.dispose();

      // Save and launch the combined PDF file.
      await _saveAndOpenPdf(bytes, '$outputFileName.pdf');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enableEncryption
                ? 'PDFs successfully merged and encrypted as $outputFileName.pdf'
                : 'PDFs successfully merged as $outputFileName.pdf',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to merge PDFs: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> convertDocxToPdf() async {
    if (selectedFiles.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final file = selectedFiles.first;
      if (file.path == null) {
        throw Exception('File path is null');
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();
      // Add a page to the document
      final PdfPage page = document.pages.add();
      // Create PDF text formatting objects
      final PdfFont titleFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        16,
        style: PdfFontStyle.bold,
      );
      final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final PdfBrush brush = PdfSolidBrush(PdfColor(0, 0, 0));

      // Extract text from DOCX using a safer method
      String extractedText = await _extractTextFromDocxSafely(file.path!);

      // Add a title with the document name
      final String docName = file.name.split('.').first;
      final PdfLayoutResult titleResult =
          PdfTextElement(
            text: 'Converted Document: $docName',
            font: titleFont,
            brush: brush,
          ).draw(
            page: page,
            bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 50),
          )!;

      // Add the extracted content
      PdfTextElement(text: extractedText, font: contentFont, brush: brush).draw(
        page: page,
        bounds: Rect.fromLTWH(
          0,
          titleResult.bounds.bottom + 20,
          page.getClientSize().width,
          page.getClientSize().height - titleResult.bounds.bottom - 20,
        ),
      );

      // Save the PDF document
      final List<int> pdfBytes = await document.save();
      document.dispose();

      // Save and open the converted file
      await _saveAndOpenPdf(pdfBytes, '$outputFileName.pdf');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DOCX converted to $outputFileName.pdf'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog('Conversion failed: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Extract text from DOCX file (safer approach for basic text documents)
  Future<String> _extractTextFromDocxSafely(String filePath) async {
    try {
      // Read the file as bytes
      final bytes = await File(filePath).readAsBytes();

      // For basic text extraction, we'll use a simple approach
      // This won't handle complex formatting but works for basic text
      String text = '';

      // Convert bytes to string and look for text content
      String content = String.fromCharCodes(bytes);

      // Extract text between tags (Word text tags)
      RegExp regExp = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
      final matches = regExp.allMatches(content);

      for (Match match in matches) {
        if (match.group(1) != null) {
          text += '${match.group(1)} ';
        }
      }

      // If we couldn't extract text, provide a fallback
      if (text.trim().isEmpty) {
        return 'Converted from: ${filePath.split('/').last}\n\n'
            'Note: This is a basic conversion for simple text documents.';
      }

      return text;
    } catch (e) {
      print('Error extracting text: $e');
      return 'Converted from: ${filePath.split('/').last}\n\n'
          'Note: This is a basic conversion. Text extraction failed.';
    }
  }

  // Save PDF file and open it
  Future<File> _saveAndOpenPdf(List<int> bytes, String fileName) async {
    // Get the downloads directory on Android
    final directory = await _getDownloadsDirectory();
    final filePath = '${directory.path}/$fileName';

    // Write the PDF file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Open the file
    OpenFile.open(filePath);
    return file;
  }

  // Get downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Use the Downloads folder on Android
      Directory? directory;
      try {
        directory = Directory('/storage/emulated/0/Download');
        // Create the directory if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      } catch (e) {
        // Fallback to application documents directory
        final appDir = await getApplicationDocumentsDirectory();
        return appDir;
      }
    } else {
      // Fallback for other platforms
      return await getApplicationDocumentsDirectory();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

// Custom painter to draw document icons like in your images
class DocumentIconPainter extends CustomPainter {
  final Color color;
  DocumentIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final double width = size.width;
    final double height = size.height;
    final double cornerSize = width * 0.2;

    final Path path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(width - cornerSize, 0)
          ..lineTo(width, cornerSize)
          ..lineTo(width, height)
          ..lineTo(0, height)
          ..close();

    // Draw the folded corner
    final Path cornerPath =
        Path()
          ..moveTo(width - cornerSize, 0)
          ..lineTo(width - cornerSize, cornerSize)
          ..lineTo(width, cornerSize)
          ..close();

    // Draw lines inside the document
    final Paint linePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
    canvas.drawPath(cornerPath, paint);

    // Draw the lines
    final double lineStartX = width * 0.2;
    final double lineEndX = width * 0.8;
    final double firstLineY = height * 0.3;
    final double lineSpacing = height * 0.1;

    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(lineStartX, firstLineY + (i * lineSpacing)),
        Offset(lineEndX, firstLineY + (i * lineSpacing)),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(DocumentIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
