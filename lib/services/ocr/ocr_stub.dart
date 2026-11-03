import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../label_parser.dart';

bool get ocrSupported => false;

Future<List<OcrLine>> recognizeLines(XFile file, Uint8List bytes) async => const [];
