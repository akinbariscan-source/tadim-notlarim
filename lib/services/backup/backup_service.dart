import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../repository.dart';
import 'save_file_stub.dart'
    if (dart.library.io) 'save_file_io.dart'
    if (dart.library.js_interop) 'save_file_web.dart' as impl;

class BackupService {
  /// Tüm tadımları (fotoğraflar dahil) tek bir .json dosyasına yazar.
  /// Web'de dosya indirilir; telefonda paylaşım menüsü açılır.
  static Future<void> exportFile() async {
    final bytes = await TastingRepository.instance.exportBackup();
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final name = 'tadim-notlarim-yedek-${now.year}${two(now.month)}${two(now.day)}.json';
    await impl.saveBytes(name, bytes);
  }

  /// Kullanıcının seçtiği yedek dosyasını içe aktarır. İptal edilirse null döner.
  static Future<int?> importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final Uint8List? bytes = result.files.single.bytes;
    if (bytes == null) {
      throw const FormatException('Dosya okunamadı.');
    }
    return TastingRepository.instance.importBackup(bytes);
  }
}
