import 'package:flutter_test/flutter_test.dart';
import 'package:tadim_notlarim/models/tasting.dart';
import 'package:tadim_notlarim/services/label_parser.dart';
import 'package:tadim_notlarim/services/similarity.dart';
import 'package:tadim_notlarim/utils/format.dart';

void main() {
  group('Etiket okuma', () {
    test('en büyük yazıyı ad, en yeni yılı rekolte olarak seçer', () {
      final guess = LabelParser.parse(const [
        OcrLine('KAYRA', 100, 180, 50, 400),
        OcrLine('BUZBAĞ', 190, 260, 60, 390),
        OcrLine('Reserve 2017', 300, 330, 100, 300),
        OcrLine('Since 1985', 400, 420, 100, 300),
        OcrLine('750 ml  %14 vol', 500, 515, 100, 300),
      ], currentYear: 2026);
      expect(guess.name, 'Kayra Buzbağ');
      expect(guess.vintage, '2017');
      expect(guess.candidates, contains('Reserve 2017'));
      expect(guess.candidates, isNot(contains('750 ml %14 vol')));
    });

    test('gelecekteki yılları rekolte saymaz', () {
      final guess = LabelParser.parse(const [
        OcrLine('Chateau Test', 0, 50, 0, 300),
        OcrLine('2019 · best before 2030', 60, 70, 0, 300),
      ], currentYear: 2026);
      expect(guess.vintage, '2019');
    });

    test('boş girdi', () {
      final guess = LabelParser.parse(const []);
      expect(guess.isEmpty, isTrue);
    });
  });

  group('Benzerlik', () {
    Tasting make(String name, List<String> grapes) => Tasting(
          id: name + grapes.join(),
          name: name,
          grapes: grapes.map((g) => GrapePortion(g)).toList(),
        );

    test('aynı şarabı yazım farkına rağmen bulur', () {
      expect(isSameWine(make('Kayra Buzbağ', []), make('KAYRA BUZBAG', [])), isTrue);
      expect(isSameWine(make('Kayra Buzbağ', []), make('Buzbağ Rezerv', [])), isFalse);
    });

    test('üzüm benzerliği', () {
      final a = make('A', ['Cabernet Sauvignon', 'Merlot']);
      final b = make('B', ['Merlot', 'Cabernet Sauvignon', 'Cabernet Franc']);
      final c = make('C', ['Öküzgözü']);
      expect(grapeSimilarity(a, b), closeTo(2 / 3, 0.001));
      expect(grapeSimilarity(a, c), 0);
      final m = findSimilar(a, [a, b, c]);
      expect(m.sameWine, isEmpty);
      expect(m.similarGrapes.map((t) => t.name).toList(), ['B']);
    });
  });

  group('Biçimlendirme', () {
    test('fiyat okuma ve yazma', () {
      expect(parsePrice('1.250,50'), 1250.5);
      expect(parsePrice('1.250'), 1250);
      expect(parsePrice('12.5'), 12.5);
      expect(parsePrice(''), isNull);
      expect(formatNumber(1250.5), '1.250,50');
      expect(formatNumber(1250), '1.250');
    });

    test('kayıt JSON gidiş-dönüş', () {
      final t = Tasting(
        id: 'x1',
        name: 'Deneme',
        vintage: '2020',
        grapes: [GrapePortion('Merlot', 60), GrapePortion('Cabernet Franc', 40)],
        sat: {
          'colour': ['red:ruby'],
          'aroma': ['black cherry', 'vanilla']
        },
        score: 91,
      );
      final back = Tasting.fromJson(t.toJson());
      expect(back.name, 'Deneme');
      expect(back.grapes.first.percent, 60);
      expect(back.values('aroma'), ['black cherry', 'vanilla']);
      expect(back.score, 91);
      expect(back.mainGrape, 'Merlot');
    });
  });
}
