import '../models/tasting.dart';

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// 1250.5 → "1.250,50"
String formatNumber(double v) {
  final fixed = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  final res = '${negative ? '-' : ''}$buf';
  return parts.length > 1 ? '$res,${parts[1]}' : res;
}

String formatPrice(double price, String currency) {
  final sym = currencies[currency] ?? currency;
  return currency == 'TRY' ? '${formatNumber(price)} $sym' : '$sym${formatNumber(price)}';
}

String formatPercent(double p) =>
    p == p.roundToDouble() ? '%${p.toInt()}' : '%${p.toStringAsFixed(1)}';

/// "1.250,50", "1250.5", "1 250" gibi girdileri sayıya çevirir.
double? parsePrice(String input) {
  var s = input.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
  if (s.isEmpty) return null;
  final hasDot = s.contains('.');
  final hasComma = s.contains(',');
  if (hasDot && hasComma) {
    if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (hasComma) {
    s = s.replaceAll(',', '.');
  } else if (hasDot && RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
    s = s.replaceAll('.', '');
  }
  return double.tryParse(s);
}

String grapesSummary(Tasting t) {
  if (t.grapes.isEmpty) return '';
  return t.grapes
      .map((g) => g.percent == null ? g.name : '${g.name} ${formatPercent(g.percent!)}')
      .join(' · ');
}

/// Karşılaştırma için metni sadeleştirir: küçük harf, aksansız, tek boşluk.
String normalizeText(String s) {
  const map = {
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
    'â': 'a', 'à': 'a', 'á': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ñ': 'n',
  };
  final lower = s.replaceAll('İ', 'i').replaceAll('I', 'i').toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    if (ch == '̇') continue;
    buf.write(map[ch] ?? ch);
  }
  return buf
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
