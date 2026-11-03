// Üzüm listesi — kaynak: ÜZÜM LİSTESİ.xlsx (otomatik üretildi)

enum GrapeOrigin { world, turkey }

class Grape {
  final String name;
  final bool isRed;
  final String regions;
  final GrapeOrigin origin;
  const Grape(this.name, this.isRed, this.regions, this.origin);
}

const List<Grape> worldGrapes = [
  Grape('Cabernet Sauvignon', true, 'Fransa, Şili, ABD, Çin, Avustralya', GrapeOrigin.world),
  Grape('Merlot', true, 'Fransa (Bordeaux), İtalya, ABD', GrapeOrigin.world),
  Grape('Tempranillo (Tinta Roriz)', true, 'İspanya, Portekiz', GrapeOrigin.world),
  Grape('Airén', false, 'İspanya (La Mancha)', GrapeOrigin.world),
  Grape('Chardonnay', false, 'Fransa, ABD, Avustralya', GrapeOrigin.world),
  Grape('Syrah / Shiraz', true, 'Fransa (Rhône), Avustralya', GrapeOrigin.world),
  Grape('Grenache / Garnacha', true, 'İspanya, Fransa', GrapeOrigin.world),
  Grape('Sauvignon Blanc', false, 'Fransa, Yeni Zelanda, Şili', GrapeOrigin.world),
  Grape('Pinot Noir', true, 'Fransa (Burgonya, Şampanya), ABD', GrapeOrigin.world),
  Grape('Trebbiano Toscano / Ugni Blanc', false, 'İtalya, Fransa (Cognac)', GrapeOrigin.world),
  Grape('Rkatsiteli', false, 'Gürcistan, Ukrayna, Moldova', GrapeOrigin.world),
  Grape('Bobal', true, 'İspanya', GrapeOrigin.world),
  Grape('Monastrell / Mourvèdre', true, 'İspanya, Fransa', GrapeOrigin.world),
  Grape('Carignan / Cariñena', true, 'Fransa, İspanya', GrapeOrigin.world),
  Grape('Cabernet Franc', true, 'Fransa (Loire, Bordeaux)', GrapeOrigin.world),
  Grape('Sangiovese', true, 'İtalya (Toskana)', GrapeOrigin.world),
  Grape('Riesling', false, 'Almanya, Alsas, Avusturya', GrapeOrigin.world),
  Grape('Muscat of Alexandria', false, 'İspanya, Şili, Güney Afrika', GrapeOrigin.world),
  Grape('Pinot Gris / Pinot Grigio', false, 'İtalya, Fransa, ABD', GrapeOrigin.world),
  Grape('Macabeo / Viura', false, 'İspanya (Cava, Rioja)', GrapeOrigin.world),
  Grape('Malbec', true, 'Arjantin, Fransa (Cahors)', GrapeOrigin.world),
  Grape('Zinfandel / Primitivo', true, 'ABD, İtalya (Puglia)', GrapeOrigin.world),
  Grape('Chenin Blanc', false, 'Güney Afrika, Fransa (Loire)', GrapeOrigin.world),
  Grape('Montepulciano', true, 'İtalya', GrapeOrigin.world),
  Grape('Gamay', true, 'Fransa (Beaujolais)', GrapeOrigin.world),
  Grape('Muscat Blanc à Petits Grains', false, 'Fransa, İtalya (Moscato)', GrapeOrigin.world),
  Grape('Glera', false, 'İtalya (Prosecco)', GrapeOrigin.world),
  Grape('Alicante Bouschet (Garnacha Tintorera)', true, 'İspanya, Portekiz', GrapeOrigin.world),
  Grape('Colombard', false, 'Fransa, Güney Afrika, ABD', GrapeOrigin.world),
  Grape('Cayetana Blanca', false, 'İspanya', GrapeOrigin.world),
  Grape('Pedro Ximénez', false, 'İspanya (Jerez, Montilla)', GrapeOrigin.world),
  Grape('Sémillon', false, 'Fransa (Sauternes), Avustralya', GrapeOrigin.world),
  Grape('Barbera', true, 'İtalya (Piemonte)', GrapeOrigin.world),
  Grape('Grüner Veltliner', false, 'Avusturya', GrapeOrigin.world),
  Grape('Cinsault', true, 'Fransa, Güney Afrika, Lübnan', GrapeOrigin.world),
  Grape('Catarratto', false, 'İtalya (Sicilya)', GrapeOrigin.world),
  Grape('Aligoté', false, 'Fransa, Doğu Avrupa', GrapeOrigin.world),
  Grape('Isabella', true, 'Brezilya, Moldova, Gürcistan', GrapeOrigin.world),
  Grape('Carmenère', true, 'Şili', GrapeOrigin.world),
  Grape('Pinot Blanc', false, 'Almanya, Avusturya, İtalya', GrapeOrigin.world),
  Grape('Touriga Franca', true, 'Portekiz (Douro)', GrapeOrigin.world),
  Grape('Palomino Fino', false, 'İspanya (Sherry)', GrapeOrigin.world),
  Grape('Müller-Thurgau', false, 'Almanya', GrapeOrigin.world),
  Grape('Nero d\'Avola', true, 'İtalya (Sicilya)', GrapeOrigin.world),
  Grape('Negroamaro', true, 'İtalya (Puglia)', GrapeOrigin.world),
  Grape('Petit Verdot', true, 'Fransa, İspanya, Avustralya', GrapeOrigin.world),
  Grape('Viognier', false, 'Fransa (Rhône), ABD', GrapeOrigin.world),
  Grape('Verdejo', false, 'İspanya (Rueda)', GrapeOrigin.world),
  Grape('Saperavi', true, 'Gürcistan', GrapeOrigin.world),
  Grape('Fetească Regală', false, 'Romanya, Moldova', GrapeOrigin.world),
];

const List<Grape> turkishGrapes = [
  Grape('Öküzgözü', true, 'Elazığ, Doğu Anadolu', GrapeOrigin.turkey),
  Grape('Boğazkere', true, 'Diyarbakır, Güneydoğu Anadolu', GrapeOrigin.turkey),
  Grape('Kalecik Karası', true, 'Ankara (Kalecik)', GrapeOrigin.turkey),
  Grape('Narince', false, 'Tokat', GrapeOrigin.turkey),
  Grape('Emir', false, 'Kapadokya (Nevşehir)', GrapeOrigin.turkey),
  Grape('Bornova Misketi', false, 'İzmir, Ege', GrapeOrigin.turkey),
  Grape('Sultaniye', false, 'Manisa, Denizli, Ege', GrapeOrigin.turkey),
  Grape('Papazkarası', true, 'Kırklareli, Trakya', GrapeOrigin.turkey),
  Grape('Karalahna', true, 'Bozcaada', GrapeOrigin.turkey),
  Grape('Çavuş', false, 'Bozcaada, Trakya', GrapeOrigin.turkey),
  Grape('Vasilaki', false, 'Bozcaada', GrapeOrigin.turkey),
  Grape('Kuntra (Karasakız)', true, 'Bozcaada, Çanakkale', GrapeOrigin.turkey),
  Grape('Adakarası', true, 'Avşa ve Marmara Adası', GrapeOrigin.turkey),
  Grape('Çalkarası', true, 'Denizli (Çal)', GrapeOrigin.turkey),
  Grape('Foça Karası', true, 'İzmir (Foça)', GrapeOrigin.turkey),
  Grape('Hasandede', false, 'Ankara (Kalecik)', GrapeOrigin.turkey),
  Grape('Yapıncak', false, 'Tekirdağ (Şarköy)', GrapeOrigin.turkey),
  Grape('Acıkara', true, 'Denizli (Çal)', GrapeOrigin.turkey),
  Grape('Kara Dimrit', true, 'Kapadokya, İç Anadolu', GrapeOrigin.turkey),
  Grape('Merzifon Karası', true, 'Amasya (Merzifon)', GrapeOrigin.turkey),
];

const List<Grape> allGrapes = [...turkishGrapes, ...worldGrapes];

Grape? findGrape(String name) {
  for (final g in allGrapes) {
    if (g.name == name) return g;
  }
  return null;
}
