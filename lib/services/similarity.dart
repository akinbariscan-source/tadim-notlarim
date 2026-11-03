import '../models/tasting.dart';
import '../utils/format.dart';

class SimilarMatches {
  /// Aynı ad (aynı ya da farklı rekolte).
  final List<Tasting> sameWine;

  /// Üzüm bileşimi aynı ya da çok benzer olanlar.
  final List<Tasting> similarGrapes;

  const SimilarMatches(this.sameWine, this.similarGrapes);

  bool get isEmpty => sameWine.isEmpty && similarGrapes.isEmpty;
}

bool isSameWine(Tasting a, Tasting b) {
  final na = normalizeText(a.name);
  final nb = normalizeText(b.name);
  if (na.isEmpty || nb.isEmpty) return false;
  if (na == nb) return true;
  final shorter = na.length < nb.length ? na : nb;
  final longer = na.length < nb.length ? nb : na;
  // OCR ya da yazım farklarına tolerans: "Buzbag" ⊂ "Kayra Buzbag"
  return shorter.length >= 6 && longer.contains(shorter);
}

Set<String> grapeSet(Tasting t) =>
    t.grapes.map((g) => normalizeText(g.name)).where((s) => s.isNotEmpty).toSet();

/// 0..1 arası benzerlik (Jaccard). 1 = aynı üzümler.
double grapeSimilarity(Tasting a, Tasting b) {
  final sa = grapeSet(a);
  final sb = grapeSet(b);
  if (sa.isEmpty || sb.isEmpty) return 0;
  final inter = sa.intersection(sb).length;
  final union = sa.union(sb).length;
  return inter / union;
}

SimilarMatches findSimilar(Tasting t, List<Tasting> all, {double threshold = 0.5}) {
  final others = all.where((o) => o.id != t.id).toList()
    ..sort((a, b) => (b.date ?? b.createdAt).compareTo(a.date ?? a.createdAt));
  final same = others.where((o) => isSameWine(t, o)).toList();
  final similar = others
      .where((o) => !same.contains(o) && grapeSimilarity(t, o) >= threshold)
      .toList()
    ..sort((a, b) => grapeSimilarity(t, b).compareTo(grapeSimilarity(t, a)));
  return SimilarMatches(same, similar);
}

List<String> commonGrapes(Tasting a, Tasting b) {
  final sb = grapeSet(b);
  return a.grapes.where((g) => sb.contains(normalizeText(g.name))).map((g) => g.name).toList();
}
