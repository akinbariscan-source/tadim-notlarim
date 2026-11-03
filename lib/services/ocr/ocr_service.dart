import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../label_parser.dart';
import 'ocr_stub.dart'
    if (dart.library.io) 'ocr_mobile.dart'
    if (dart.library.js_interop) 'ocr_web.dart' as impl;

/// Etiket fotoğrafından şarap adını ve rekolteyi tahmin eder.
/// iOS/Android: Google ML Kit (cihaz üzerinde, internetsiz).
/// Web: Tesseract.js (tarayıcıda; ilk kullanımda dil dosyası indirilir).
class OcrService {
  static bool get isSupported => impl.ocrSupported;

  static Future<LabelGuess> readLabel(XFile file, Uint8List bytes) async {
    final lines = await impl.recognizeLines(file, bytes);
    return LabelParser.parse(lines);
  }
}
