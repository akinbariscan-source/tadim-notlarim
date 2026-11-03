// Tadım sistematiği — kaynak: TADIM NOTLARI.pdf (WSET Level 3 SAT).
// Kullanıcı isteği doğrultusunda her satırda birden fazla seçenek işaretlenebilir.

enum SatKind {
  /// Ölçek satırı (ör. light – medium – pronounced).
  scale,

  /// "e.g." satırı; hazır seçenekler + kullanıcı ekleyebilir.
  observations,

  /// Aroma / lezzet tanımlayıcıları (DESCRIBING AROMA AND FLAVOUR).
  descriptors,
}

class SatGroup {
  /// Grup anahtarı (ör. "white"). Seçenek değeri "anahtar:seçenek" olarak saklanır.
  final String? key;
  final String? label;
  final List<String> options;
  const SatGroup(this.options, {this.key, this.label});

  String valueOf(String option) => key == null ? option : '$key:$option';
}

class SatField {
  final String key;
  final String en;
  final String tr;
  final SatKind kind;
  final List<SatGroup> groups;
  const SatField(this.key, this.en, this.tr, this.kind, this.groups);
}

class SatSection {
  final String key;
  final String en;
  final String tr;
  final List<SatField> fields;
  const SatSection(this.key, this.en, this.tr, this.fields);
}

const _fiveLevel = ['low', 'medium(-)', 'medium', 'medium(+)', 'high'];
const _intensity = ['light', 'medium(-)', 'medium', 'medium(+)', 'pronounced'];

const List<SatSection> satSections = [
  SatSection('appearance', 'APPEARANCE', 'Görünüm', [
    SatField('clarity', 'Clarity', 'Berraklık', SatKind.scale, [
      SatGroup(['clear', 'hazy (faulty?)']),
    ]),
    SatField('appearance_intensity', 'Intensity', 'Renk yoğunluğu', SatKind.scale, [
      SatGroup(['pale', 'medium', 'deep']),
    ]),
    SatField('colour', 'Colour', 'Renk', SatKind.scale, [
      SatGroup(['lemon-green', 'lemon', 'gold', 'amber', 'brown'],
          key: 'white', label: 'white · beyaz'),
      SatGroup(['pink', 'salmon', 'orange'], key: 'rose', label: 'rosé · roze'),
      SatGroup(['purple', 'ruby', 'garnet', 'tawny', 'brown'],
          key: 'red', label: 'red · kırmızı'),
    ]),
    SatField('other_observations', 'Other observations', 'Diğer gözlemler',
        SatKind.observations, [
      SatGroup(['legs/tears', 'deposit', 'pétillance', 'bubbles']),
    ]),
  ]),
  SatSection('nose', 'NOSE', 'Koku', [
    SatField('nose_condition', 'Condition', 'Durum', SatKind.scale, [
      SatGroup(['clean', 'unclean (faulty?)']),
    ]),
    SatField('nose_intensity', 'Intensity', 'Yoğunluk', SatKind.scale, [
      SatGroup(_intensity),
    ]),
    SatField('aroma', 'Aroma characteristics', 'Aroma özellikleri',
        SatKind.descriptors, []),
    SatField('development', 'Development', 'Gelişim', SatKind.scale, [
      SatGroup(['youthful', 'developing', 'fully developed', 'tired/past its best']),
    ]),
  ]),
  SatSection('palate', 'PALATE', 'Damak', [
    SatField('sweetness', 'Sweetness', 'Tatlılık', SatKind.scale, [
      SatGroup(['dry', 'off-dry', 'medium-dry', 'medium-sweet', 'sweet', 'luscious']),
    ]),
    SatField('acidity', 'Acidity', 'Asidite', SatKind.scale, [SatGroup(_fiveLevel)]),
    SatField('tannin', 'Tannin', 'Tanen', SatKind.scale, [SatGroup(_fiveLevel)]),
    SatField('alcohol', 'Alcohol', 'Alkol', SatKind.scale, [
      SatGroup(['low', 'medium', 'high']),
      SatGroup(['low', 'medium', 'high'],
          key: 'fortified', label: 'fortified wines · güçlendirilmiş'),
    ]),
    SatField('body', 'Body', 'Gövde', SatKind.scale, [
      SatGroup(['light', 'medium(-)', 'medium', 'medium(+)', 'full']),
    ]),
    SatField('mousse', 'Mousse', 'Köpük (mousse)', SatKind.scale, [
      SatGroup(['delicate', 'creamy', 'aggressive']),
    ]),
    SatField('flavour_intensity', 'Flavour intensity', 'Lezzet yoğunluğu',
        SatKind.scale, [SatGroup(_intensity)]),
    SatField('flavour', 'Flavour characteristics', 'Lezzet özellikleri',
        SatKind.descriptors, []),
    SatField('finish', 'Finish', 'Bitiş (finish)', SatKind.scale, [
      SatGroup(['short', 'medium(-)', 'medium', 'medium(+)', 'long']),
    ]),
  ]),
  SatSection('conclusions', 'CONCLUSIONS', 'Sonuç', [
    SatField('quality', 'Quality level', 'Kalite seviyesi', SatKind.scale, [
      SatGroup(['faulty', 'poor', 'acceptable', 'good', 'very good', 'outstanding']),
    ]),
    SatField('readiness', 'Level of readiness / potential for ageing',
        'İçime hazırlık / yıllanma potansiyeli', SatKind.scale, [
      SatGroup([
        'too young',
        'can drink now, but has potential for ageing',
        'drink now: not suitable for ageing or further ageing',
        'too old',
      ]),
    ]),
  ]),
];

/// Saklanan değeri ekranda gösterilecek metne çevirir ("red:ruby" → "ruby (red)").
String satDisplay(String value) {
  final i = value.indexOf(':');
  if (i <= 0) return value;
  final group = value.substring(0, i);
  final option = value.substring(i + 1);
  const names = {'white': 'white', 'rose': 'rosé', 'red': 'red', 'fortified': 'fortified'};
  return '$option (${names[group] ?? group})';
}

SatField? satFieldByKey(String key) {
  for (final s in satSections) {
    for (final f in s.fields) {
      if (f.key == key) return f;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// DESCRIBING AROMA AND FLAVOUR
// ---------------------------------------------------------------------------

class DescriptorCluster {
  final String name;
  final List<String> items;
  const DescriptorCluster(this.name, this.items);
}

class DescriptorTier {
  final String key;
  final String en;
  final String tr;
  final String subtitle;
  final String keyQuestions;
  final List<DescriptorCluster> clusters;
  const DescriptorTier(
      this.key, this.en, this.tr, this.subtitle, this.keyQuestions, this.clusters);
}

const List<DescriptorTier> descriptorTiers = [
  DescriptorTier(
    'primary',
    'Primary',
    'Birincil',
    'Üzümden ve alkol fermantasyonundan gelen aroma ve lezzetler',
    'Delicate or intense? Simple or complex? Generic or well-defined? '
        'Fresh or cooked? Under-ripe, ripe or over-ripe?',
    [
      DescriptorCluster('Floral', [
        'acacia', 'honeysuckle', 'chamomile', 'elderflower', 'geranium',
        'blossom', 'rose', 'violet',
      ]),
      DescriptorCluster('Green fruit',
          ['apple', 'gooseberry', 'pear', 'pear drop', 'quince', 'grape']),
      DescriptorCluster('Citrus fruit', [
        'grapefruit', 'lemon', 'lime', 'lime juice', 'lime zest',
        'orange peel', 'lemon peel',
      ]),
      DescriptorCluster('Stone fruit', ['peach', 'apricot', 'nectarine']),
      DescriptorCluster('Tropical fruit',
          ['banana', 'lychee', 'mango', 'melon', 'passion fruit', 'pineapple']),
      DescriptorCluster('Red fruit', [
        'redcurrant', 'cranberry', 'raspberry', 'strawberry', 'red cherry',
        'red plum',
      ]),
      DescriptorCluster('Black fruit', [
        'blackcurrant', 'blackberry', 'bramble', 'blueberry', 'black cherry',
        'black plum',
      ]),
      DescriptorCluster('Dried/cooked fruit', [
        'fig', 'prune', 'raisin', 'sultana', 'kirsch', 'jamminess',
        'baked/stewed fruits', 'preserved fruits',
      ]),
      DescriptorCluster('Herbaceous', [
        'green bell pepper (capsicum)', 'grass', 'tomato leaf', 'asparagus',
        'blackcurrant leaf',
      ]),
      DescriptorCluster('Herbal',
          ['eucalyptus', 'mint', 'medicinal', 'lavender', 'fennel', 'dill']),
      DescriptorCluster('Pungent spice',
          ['black pepper', 'white pepper', 'liquorice']),
      DescriptorCluster('Other', ['flint', 'wet stones', 'wet wool']),
    ],
  ),
  DescriptorTier(
    'secondary',
    'Secondary',
    'İkincil',
    'Fermantasyon sonrası şarap yapımından gelen aroma ve lezzetler',
    'Are the flavours from yeast, MLF or oak?',
    [
      DescriptorCluster('Yeast (lees, autolysis)', [
        'biscuit', 'bread', 'toast', 'pastry', 'brioche', 'bread dough', 'cheese',
      ]),
      DescriptorCluster('MLF', ['butter', 'cheese', 'cream']),
      DescriptorCluster('Oak', [
        'vanilla', 'cloves', 'nutmeg', 'coconut', 'butterscotch', 'toast',
        'cedar', 'charred wood', 'smoke', 'chocolate', 'coffee', 'resinous',
      ]),
    ],
  ),
  DescriptorTier(
    'tertiary',
    'Tertiary',
    'Üçüncül',
    'Olgunlaşmadan (yıllanmadan) gelen aroma ve lezzetler',
    'Do the flavours show deliberate oxidation, fruit development or bottle age?',
    [
      DescriptorCluster('Deliberate oxidation', [
        'almond', 'marzipan', 'hazelnut', 'walnut', 'chocolate', 'coffee',
        'toffee', 'caramel',
      ]),
      DescriptorCluster('Fruit development (white)',
          ['dried apricot', 'marmalade', 'dried apple', 'dried banana']),
      DescriptorCluster('Fruit development (red)', [
        'fig', 'prune', 'tar', 'dried blackberry', 'dried cranberry',
        'cooked blackberry', 'cooked red plum',
      ]),
      DescriptorCluster('Bottle age (white)', [
        'petrol', 'kerosene', 'cinnamon', 'ginger', 'nutmeg', 'toast', 'nutty',
        'mushroom', 'hay', 'honey',
      ]),
      DescriptorCluster('Bottle age (red)', [
        'leather', 'forest floor', 'earth', 'mushroom', 'game', 'tobacco',
        'vegetal', 'wet leaves', 'savoury', 'meaty', 'farmyard',
      ]),
    ],
  ),
];

final Set<String> knownDescriptors = {
  for (final t in descriptorTiers)
    for (final c in t.clusters) ...c.items,
};

/// Bir tanımlayıcının ait olduğu ilk (katman, küme) çiftini döndürür.
(DescriptorTier, DescriptorCluster)? descriptorOrigin(String item) {
  for (final t in descriptorTiers) {
    for (final c in t.clusters) {
      if (c.items.contains(item)) return (t, c);
    }
  }
  return null;
}
