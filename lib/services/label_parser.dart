/// Etiket fotoğrafından okunan bir satır (konum piksel cinsinden).
class OcrLine {
  final String text;
  final double top;
  final double bottom;
  final double left;
  final double right;

  const OcrLine(this.text, this.top, this.bottom, this.left, this.right);

  double get height => (bottom - top).abs();
}

class LabelGuess {
  final String? name;
  final String? vintage;

  /// Ad olarak kullanılabilecek diğer büyük satırlar.
  final List<String> candidates;

  const LabelGuess({this.name, this.vintage, this.candidates = const []});

  bool get isEmpty => name == null && vintage == null;
}

class LabelParser {
  static final _year = RegExp(r'(^|[^0-9])((?:19[5-9]|20[0-9])[0-9])(?![0-9])');
  static final _letter = RegExp(r'[A-Za-zÀ-ÿĞğİıŞşÇçÖöÜü]');
  static final _onlyYear = RegExp(r'^[^A-Za-zÀ-ÿĞğİıŞşÇçÖöÜü]*$');

  /// Kuruluş yılını rekolteden ayırmak için yılın hemen önündeki ifadeler.
  static final _foundedBefore = RegExp(
    r'\b(since|est\.?|established|founded|kurulu[sş]|depuis|seit|desde|dal|fondat[ao])\s*[:.]?\s*$',
  );

  /// Ad olamayacak (yasal/teknik) satırları eler.
  static const _noisePhrases = [
    'product of', 'produce of', 'produced', 'bottled', 'contains', 'sulfit',
    'sülfit', 'sulphite', 'www.', '.com', 'appellation', 'mis en bouteille',
    'imported', 'üretici', 'uretici', 'ithalatçı', 'şişelenmiştir',
    'kırmızı şarap', 'beyaz şarap', 'roze şarap', 'red wine', 'white wine',
    'rosé wine', 'rose wine', 'vin rouge', 'vin blanc', 'tüketim', 'alkollü',
    'hamile', 'pregnant',
  ];
  static final _noisePattern = RegExp(
    r'(\d\s*(ml|cl|lt)\b)|(%\s*\d)|(\d\s*%)|(\bvol\b)|(\balc\b)',
  );

  static LabelGuess parse(List<OcrLine> lines, {int? currentYear}) {
    final year = currentYear ?? DateTime.now().year;
    final fullText = lines.map((l) => l.text).join('\n');
    final vintage = _findVintage(fullText, year);

    final valid = <OcrLine>[];
    for (final l in lines) {
      final text = _clean(l.text);
      if (text.isEmpty) continue;
      if (_letter.allMatches(text).length < 3) continue;
      if (_onlyYear.hasMatch(text)) continue;
      final lower = text.toLowerCase();
      if (_noisePhrases.any(lower.contains) || _noisePattern.hasMatch(lower)) continue;
      valid.add(OcrLine(text, l.top, l.bottom, l.left, l.right));
    }
    if (valid.isEmpty) {
      return LabelGuess(vintage: vintage);
    }

    final byHeight = [...valid]..sort((a, b) => b.height.compareTo(a.height));
    final top = byHeight.first;
    final group = <OcrLine>[top];

    // Aynı büyüklükte, hemen üstünde/altında duran satırları ada ekle (en fazla 3 satır).
    var changed = true;
    while (changed && group.length < 3) {
      changed = false;
      for (final l in byHeight.skip(1)) {
        if (group.contains(l)) continue;
        if (l.height < top.height * 0.75) continue;
        final gTop = group.map((g) => g.top).reduce((a, b) => a < b ? a : b);
        final gBottom = group.map((g) => g.bottom).reduce((a, b) => a > b ? a : b);
        final gap = l.top > gBottom ? l.top - gBottom : (gTop > l.bottom ? gTop - l.bottom : 0);
        final overlapsHorizontally = l.left < top.right && l.right > top.left;
        if (gap <= top.height * 1.2 && overlapsHorizontally) {
          group.add(l);
          changed = true;
          break;
        }
      }
    }
    group.sort((a, b) => a.top.compareTo(b.top));
    final name = _titleCase(group.map((g) => g.text).join(' '));

    final candidates = <String>[];
    for (final l in byHeight) {
      if (group.contains(l)) continue;
      final c = _titleCase(l.text);
      if (!candidates.contains(c) && c != name) candidates.add(c);
      if (candidates.length >= 6) break;
    }
    return LabelGuess(name: name, vintage: vintage, candidates: candidates);
  }

  static String? _findVintage(String text, int currentYear) {
    final lower = text.toLowerCase();
    final all = <int>[];
    final preferred = <int>[];
    for (final m in _year.allMatches(lower)) {
      final y = int.parse(m.group(2)!);
      if (y > currentYear) continue;
      all.add(y);
      final start = m.start + m.group(1)!.length;
      final before = lower.substring(start < 15 ? 0 : start - 15, start);
      if (!_foundedBefore.hasMatch(before)) preferred.add(y);
    }
    final pool = preferred.isNotEmpty ? preferred : all;
    if (pool.isEmpty) return null;
    pool.sort();
    return pool.last.toString();
  }

  static String _clean(String s) => s
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[^A-Za-z0-9À-ÿĞğİıŞşÇçÖöÜü]+'), '')
      .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿĞğİıŞşÇçÖöÜü.)]+$'), '')
      .trim();

  /// "KAYRA BUZBAĞ" → "Kayra Buzbağ". Karışık yazılmış metne dokunmaz.
  static String _titleCase(String s) {
    final hasLower = s.contains(RegExp(r'[a-zà-ÿğışçöü]'));
    if (hasLower) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      // Türkçe harf içeren kelimede I → ı, diğerlerinde (PINOT) I → i.
      final turkish = w.contains(RegExp('[ĞŞÇÖÜİ]'));
      final lower =
          w.replaceAll('İ', 'i').replaceAll('I', turkish ? 'ı' : 'i').toLowerCase();
      final first = w.substring(0, 1);
      return first + lower.substring(1);
    }).join(' ');
  }
}
