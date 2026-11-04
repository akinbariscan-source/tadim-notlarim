import 'package:file_selector/file_selector.dart';

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
    const jsonGroup = XTypeGroup(
      label: 'Tadım Notlarım yedeği',
      extensions: ['json'],
      mimeTypes: ['application/json', 'text/plain', 'application/octet-stream'],
      uniformTypeIdentifiers: ['public.json', 'public.text', 'public.data'],
    );
    final file = await openFile(acceptedTypeGroups: const [jsonGroup]);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return TastingRepository.instance.importBackup(bytes);
  }
}
