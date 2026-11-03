import '../data/grapes.dart';

/// Şarap tipi (isteğe bağlı).
const Map<String, String> wineTypes = {
  'red': 'Kırmızı',
  'white': 'Beyaz',
  'rose': 'Roze',
  'sparkling': 'Köpüklü',
  'fortified': 'Tatlı / Güçlendirilmiş',
};

const Map<String, String> currencies = {
  'TRY': '₺',
  'EUR': '€',
  'USD': r'$',
  'GBP': '£',
};

class GrapePortion {
  String name;
  double? percent;

  GrapePortion(this.name, [this.percent]);

  Map<String, dynamic> toJson() => {
        'name': name,
        if (percent != null) 'percent': percent,
      };

  factory GrapePortion.fromJson(Map<String, dynamic> j) =>
      GrapePortion(j['name'] as String, (j['percent'] as num?)?.toDouble());
}

class Tasting {
  String id;
  String name;
  String? vintage;
  String? wineType;
  List<GrapePortion> grapes;
  String? place;
  DateTime? date;
  double? price;
  String currency;

  /// Tadım sistematiği: alan anahtarı → seçilen değerler (aroma/flavour dahil).
  Map<String, List<String>> sat;

  int? score;
  bool? wouldBuyAgain;
  String? food;
  String? notes;
  bool hasPhoto;
  DateTime createdAt;
  DateTime updatedAt;

  Tasting({
    required this.id,
    this.name = '',
    this.vintage,
    this.wineType,
    List<GrapePortion>? grapes,
    this.place,
    this.date,
    this.price,
    this.currency = 'TRY',
    Map<String, List<String>>? sat,
    this.score,
    this.wouldBuyAgain,
    this.food,
    this.notes,
    this.hasPhoto = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : grapes = grapes ?? [],
        sat = sat ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Tasting.empty() => Tasting(id: newId(), date: DateTime.now());

  static String newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(36)}${(now % 9973).toRadixString(36)}';
  }

  List<String> values(String key) => sat[key] ?? const [];

  void setValues(String key, List<String> v) {
    if (v.isEmpty) {
      sat.remove(key);
    } else {
      sat[key] = v;
    }
  }

  List<String> get aromas => values('aroma');
  List<String> get flavours => values('flavour');

  /// Yüzdesi en yüksek (yoksa ilk) üzüm.
  String? get mainGrape {
    if (grapes.isEmpty) return null;
    final sorted = [...grapes]
      ..sort((a, b) => (b.percent ?? -1).compareTo(a.percent ?? -1));
    return sorted.first.name;
  }

  /// Üzümlere bakarak tip tahmini (hepsi kırmızı → kırmızı, hepsi beyaz → beyaz).
  String? guessTypeFromGrapes() {
    if (grapes.isEmpty) return null;
    final known = grapes.map((g) => findGrape(g.name)).whereType<Grape>().toList();
    if (known.length != grapes.length) return null;
    if (known.every((g) => g.isRed)) return 'red';
    if (known.every((g) => !g.isRed)) return 'white';
    return null;
  }

  String get title => vintage == null || vintage!.isEmpty ? name : '$name $vintage';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (vintage != null) 'vintage': vintage,
        if (wineType != null) 'wineType': wineType,
        'grapes': grapes.map((g) => g.toJson()).toList(),
        if (place != null) 'place': place,
        if (date != null) 'date': date!.toIso8601String(),
        if (price != null) 'price': price,
        'currency': currency,
        'sat': sat,
        if (score != null) 'score': score,
        if (wouldBuyAgain != null) 'wouldBuyAgain': wouldBuyAgain,
        if (food != null) 'food': food,
        if (notes != null) 'notes': notes,
        'hasPhoto': hasPhoto,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Tasting.fromJson(Map<String, dynamic> j) {
    final satRaw = (j['sat'] as Map?) ?? const {};
    return Tasting(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? '',
      vintage: j['vintage'] as String?,
      wineType: j['wineType'] as String?,
      grapes: ((j['grapes'] as List?) ?? const [])
          .map((e) => GrapePortion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      place: j['place'] as String?,
      date: j['date'] == null ? null : DateTime.tryParse(j['date'] as String),
      price: (j['price'] as num?)?.toDouble(),
      currency: (j['currency'] as String?) ?? 'TRY',
      sat: {
        for (final e in satRaw.entries)
          e.key.toString(): (e.value as List).map((v) => v.toString()).toList(),
      },
      score: (j['score'] as num?)?.toInt(),
      wouldBuyAgain: j['wouldBuyAgain'] as bool?,
      food: j['food'] as String?,
      notes: j['notes'] as String?,
      hasPhoto: (j['hasPhoto'] as bool?) ?? false,
      createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse((j['updatedAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  Tasting copy() => Tasting.fromJson(toJson());
}
