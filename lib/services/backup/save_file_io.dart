import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveBytes(String name, Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json', name: name)],
    subject: 'Tadım Notlarım yedeği',
    // iPad'de paylaşım penceresinin konumu için zorunlu.
    sharePositionOrigin: const Rect.fromLTWH(0, 0, 10, 10),
  );
}
