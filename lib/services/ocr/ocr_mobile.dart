import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../label_parser.dart';

bool get ocrSupported => Platform.isAndroid || Platform.isIOS;

Future<List<OcrLine>> recognizeLines(XFile file, Uint8List bytes) async {
  if (!ocrSupported) return const [];
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(file.path));
    return [
      for (final block in result.blocks)
        for (final line in block.lines)
          OcrLine(
            line.text,
            line.boundingBox.top,
            line.boundingBox.bottom,
            line.boundingBox.left,
            line.boundingBox.right,
          ),
    ];
  } finally {
    await recognizer.close();
  }
}
