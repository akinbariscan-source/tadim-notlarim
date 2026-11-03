import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../label_parser.dart';

/// web/ocr.js içinde tanımlı (Tesseract.js'i ilk çağrıda yükler).
@JS('tadimOcr')
external JSPromise<JSString> _tadimOcr(JSUint8Array bytes);

bool get ocrSupported => true;

Future<List<OcrLine>> recognizeLines(XFile file, Uint8List bytes) async {
  final result = await _tadimOcr(bytes.toJS).toDart;
  final data = jsonDecode(result.toDart) as Map<String, dynamic>;
  final lines = (data['lines'] as List?) ?? const [];
  return [
    for (final raw in lines)
      if (raw is Map)
        OcrLine(
          (raw['text'] ?? '').toString(),
          (raw['y0'] as num? ?? 0).toDouble(),
          (raw['y1'] as num? ?? 0).toDouble(),
          (raw['x0'] as num? ?? 0).toDouble(),
          (raw['x1'] as num? ?? 0).toDouble(),
        ),
  ];
}
