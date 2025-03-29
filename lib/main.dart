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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDFMerge',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'PDFMerge : A simple utility'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: combinePDF,
              child: const Text('Combine PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Future combinePDF() async {
    // Let users select multiple PDF files.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      print('No files selected.');
      return;
    }

    // Create a new PDF document.
    PdfDocument newDocument = PdfDocument();
    PdfSection? section;

    for (PlatformFile file in result.files) {
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
    SaveFile.saveAndLaunchFile(bytes, 'output.pdf');
  }

  Future<List<int>> _readData(String name) async {
    final ByteData data = await rootBundle.load('assets/$name');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
