import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/tasting_sheet.dart';
import '../models/tasting.dart';

/// Tüm tadımları cihazda (web'de tarayıcının IndexedDB'sinde) saklar.
class TastingRepository extends ChangeNotifier {
  TastingRepository._();
  static final TastingRepository instance = TastingRepository._();

  late Box<String> _box;
  late LazyBox<String> _photos;
  final Map<String, Tasting> _items = {};
  final Map<String, Uint8List> _photoCache = {};

  Future<void> init() async {
    await Hive.initFlutter('tadim_notlarim');
    _box = await Hive.openBox<String>('tastings');
    _photos = await Hive.openLazyBox<String>('photos');
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final t = Tasting.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _items[t.id] = t;
      } catch (e) {
        debugPrint('Kayıt okunamadı ($key): $e');
      }
    }
  }

  List<Tasting> get all => _items.values.toList();

  Tasting? byId(String id) => _items[id];

  Future<void> save(Tasting t, {Uint8List? photo, bool removePhoto = false}) async {
    t.updatedAt = DateTime.now();
    if (photo != null) {
      await _photos.put(t.id, base64Encode(photo));
      _cachePhoto(t.id, photo);
      t.hasPhoto = true;
    } else if (removePhoto) {
      await _photos.delete(t.id);
      _photoCache.remove(t.id);
      t.hasPhoto = false;
    }
    await _box.put(t.id, jsonEncode(t.toJson()));
    _items[t.id] = t;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await _photos.delete(id);
    _items.remove(id);
    _photoCache.remove(id);
    notifyListeners();
  }

  Uint8List? cachedPhoto(String id) => _photoCache[id];

  Future<Uint8List?> photo(String id) async {
    final cached = _photoCache[id];
    if (cached != null) return cached;
    final raw = await _photos.get(id);
    if (raw == null) return null;
    final bytes = base64Decode(raw);
    _cachePhoto(id, bytes);
    return bytes;
  }

  void _cachePhoto(String id, Uint8List bytes) {
    _photoCache.remove(id);
    _photoCache[id] = bytes;
    while (_photoCache.length > 60) {
      _photoCache.remove(_photoCache.keys.first);
    }
  }

  /// Daha önce elle eklenmiş aroma/lezzetler (listede olmayanlar).
  List<String> customDescriptors() {
    final set = <String>{};
    for (final t in _items.values) {
      for (final v in [...t.aromas, ...t.flavours]) {
        if (!knownDescriptors.contains(v)) set.add(v);
      }
    }
    return set.toList()..sort();
  }

  /// Daha önce elle eklenmiş "diğer gözlemler".
  List<String> customValues(String key, List<String> known) {
    final set = <String>{};
    for (final t in _items.values) {
      for (final v in t.values(key)) {
        if (!known.contains(v)) set.add(v);
      }
    }
    return set.toList()..sort();
  }

  /// Kayıtlarda geçen üzümler (filtre için).
  List<String> usedGrapes() {
    final set = <String>{};
    for (final t in _items.values) {
      for (final g in t.grapes) {
        set.add(g.name);
      }
    }
    return set.toList()..sort();
  }

  // ---------------------------------------------------------------- Yedek --

  Future<Uint8List> exportBackup() async {
    final list = <Map<String, dynamic>>[];
    for (final t in _items.values) {
      final json = t.toJson();
      if (t.hasPhoto) {
        final raw = await _photos.get(t.id);
        if (raw != null) json['photo'] = raw;
      }
      list.add(json);
    }
    final data = {
      'app': 'tadim_notlarim',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tastings': list,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  /// Yedeği içe aktarır; aynı kimlikli kayıtların üzerine yazar. Aktarılan sayıyı döndürür.
  Future<int> importBackup(Uint8List bytes) async {
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map || data['app'] != 'tadim_notlarim' || data['tastings'] is! List) {
      throw const FormatException('Bu dosya bir Tadım Notlarım yedeği değil.');
    }
    var count = 0;
    for (final raw in data['tastings'] as List) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw);
      final photo = json.remove('photo');
      final t = Tasting.fromJson(json);
      if (photo is String && photo.isNotEmpty) {
        await _photos.put(t.id, photo);
        _photoCache.remove(t.id);
        t.hasPhoto = true;
      }
      await _box.put(t.id, jsonEncode(t.toJson()));
      _items[t.id] = t;
      count++;
    }
    notifyListeners();
    return count;
  }
}
