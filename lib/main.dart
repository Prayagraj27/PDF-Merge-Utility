import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'save_file_mobile_and_desktop.dart'
    if (dart.library.html) 'save_file_web.dart';

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
      ),
      home: const MyHomePage(title: 'Remix : Merge PDFs effortlessly'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<PlatformFile> selectedFiles = [];
  bool isLoading = false;
  String outputFileName = 'new_pdf';

  // Colors for the document icons
  final List<Color> docColors = [Colors.blue, Colors.red, Colors.green];

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
                  const Text('Merge multiple PDF files into one locally.'),
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
                // Document icons row when no files are selected
                if (selectedFiles.isEmpty)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated document icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < docColors.length; i++)
                              AnimatedContainer(
                                duration: Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: GestureDetector(
                                  onTap: _pickFiles,
                                  child: _buildDocumentIcon(docColors[i], 80),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 40),
                        Text(
                          'Tap to select PDF files',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
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
                                    });
                                  },
                                ),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          );
                        },
                        onReorder: (int oldIndex, int newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = selectedFiles.removeAt(oldIndex);
                            selectedFiles.insert(newIndex, item);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Output filename - removed the purple document icon from prefixIcon
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Output Filename',
                      hintText: 'Enter a name for your merged PDF',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.edit_document,
                      ), // Changed to a standard icon
                      suffixText: '.pdf',
                    ),
                    controller: TextEditingController(text: 'merged_document'),
                    onChanged: (value) {
                      outputFileName = value;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Merge button
                ElevatedButton.icon(
                  onPressed: selectedFiles.isNotEmpty ? combinePDF : _pickFiles,
                  icon: Icon(
                    selectedFiles.isNotEmpty ? Icons.merge_type : Icons.add,
                  ),
                  label: Text(
                    selectedFiles.isNotEmpty
                        ? 'Combine PDFs'
                        : 'Select PDF Files',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDocumentIcon(Colors.blue, 24),
                        Icon(Icons.add, color: Colors.white),
                        _buildDocumentIcon(Colors.red, 24),
                        Icon(Icons.arrow_forward, color: Colors.white),
                        _buildDocumentIcon(Colors.green, 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Merging PDFs...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Custom widget to build document icons like in your images
  Widget _buildDocumentIcon(Color color, double size) {
    return CustomPaint(
      size: Size(size, size * 1.3),
      painter: DocumentIconPainter(color),
    );
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFiles = result.files;
      });
    }
  }

  Future<void> combinePDF() async {
    if (selectedFiles.isEmpty) return;

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

      // Save the combined document.
      List<int> bytes = await newDocument.save();
      newDocument.dispose();

      // Save and launch/download the combined PDF file.
      SaveFile.saveAndLaunchFile(bytes, '$outputFileName.pdf');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDFs successfully merged as $outputFileName.pdf'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to merge PDFs: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
