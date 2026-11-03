import 'package:flutter/material.dart';

import '../models/tasting.dart';
import '../services/backup/backup_service.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'tasting_detail_page.dart';

enum SortMode { newest, oldest, scoreDesc, scoreAsc, priceDesc, priceAsc, grape, name }

const Map<SortMode, String> sortLabels = {
  SortMode.newest: 'Tarih (yeniden eskiye)',
  SortMode.oldest: 'Tarih (eskiden yeniye)',
  SortMode.scoreDesc: 'Puan (yüksekten düşüğe)',
  SortMode.scoreAsc: 'Puan (düşükten yükseğe)',
  SortMode.priceDesc: 'Fiyat (yüksekten düşüğe)',
  SortMode.priceAsc: 'Fiyat (düşükten yükseğe)',
  SortMode.grape: 'Üzüm türüne göre (A→Z)',
  SortMode.name: 'Şarap adına göre (A→Z)',
};

class SavedListPage extends StatefulWidget {
  const SavedListPage({super.key});

  @override
  State<SavedListPage> createState() => _SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage> {
  SortMode _sort = SortMode.newest;
  String _query = '';
  String? _grape;

  DateTime _when(Tasting t) => t.date ?? t.createdAt;

  /// null değerler her zaman sona.
  int _cmpNum(num? a, num? b, {bool desc = false}) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return desc ? b.compareTo(a) : a.compareTo(b);
  }

  List<Tasting> _filtered(List<Tasting> all) {
    final q = normalizeText(_query);
    return all.where((t) {
      if (_grape != null && !t.grapes.any((g) => g.name == _grape)) return false;
      if (q.isEmpty) return true;
      final hay = normalizeText([
        t.name,
        t.vintage ?? '',
        t.place ?? '',
        grapesSummary(t),
        t.notes ?? '',
        t.food ?? '',
      ].join(' '));
      return hay.contains(q);
    }).toList();
  }

  void _sortList(List<Tasting> list) {
    switch (_sort) {
      case SortMode.newest:
        list.sort((a, b) => _when(b).compareTo(_when(a)));
        break;
      case SortMode.oldest:
        list.sort((a, b) => _when(a).compareTo(_when(b)));
        break;
      case SortMode.scoreDesc:
        list.sort((a, b) => _cmpNum(a.score, b.score, desc: true));
        break;
      case SortMode.scoreAsc:
        list.sort((a, b) => _cmpNum(a.score, b.score));
        break;
      case SortMode.priceDesc:
        list.sort((a, b) => _cmpNum(a.price, b.price, desc: true));
        break;
      case SortMode.priceAsc:
        list.sort((a, b) => _cmpNum(a.price, b.price));
        break;
      case SortMode.grape:
      case SortMode.name:
        list.sort((a, b) => normalizeText(a.name).compareTo(normalizeText(b.name)));
        break;
    }
  }

  Future<void> _menu(String action) async {
    try {
      if (action == 'export') {
        if (TastingRepository.instance.all.isEmpty) {
          showSnack(context, 'Yedeklenecek kayıt yok.');
          return;
        }
        await BackupService.exportFile();
      } else if (action == 'import') {
        final n = await BackupService.importFile();
        if (n != null && mounted) showSnack(context, '$n tadım yedekten yüklendi.');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'İşlem tamamlanamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = TastingRepository.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıtlı Şaraplar'),
        actions: [
          PopupMenuButton<SortMode>(
            tooltip: 'Sırala',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (m) => setState(() => _sort = m),
            itemBuilder: (_) => [
              for (final e in sortLabels.entries)
                CheckedPopupMenuItem(value: e.key, checked: e.key == _sort, child: Text(e.value)),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'Diğer',
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Yedeği dışa aktar'),
                  subtitle: Text('Fotoğraflar dahil tek dosya'),
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Yedekten geri yükle'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final all = repo.all;
          if (all.isEmpty) return const _EmptyState();
          final grapes = repo.usedGrapes();
          if (_grape != null && !grapes.contains(_grape)) _grape = null;
          final items = _filtered(all);
          _sortList(items);

          return MaxWidth(
            width: 900,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(context, all, grapes)),
                if (items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Aramana uyan kayıt yok.')),
                    ),
                  )
                else if (_sort == SortMode.grape)
                  ..._groupedByGrape(items)
                else
                  SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => _TastingCard(tasting: items[i]),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _groupedByGrape(List<Tasting> items) {
    const none = 'Üzüm belirtilmemiş';
    final groups = <String, List<Tasting>>{};
    for (final t in items) {
      groups.putIfAbsent(t.mainGrape ?? none, () => []).add(t);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == none) return 1;
        if (b == none) return -1;
        return normalizeText(a).compareTo(normalizeText(b));
      });
    final slivers = <Widget>[];
    for (final k in keys) {
      final list = groups[k]!
        ..sort((a, b) => _cmpNum(a.score, b.score, desc: true));
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            '$k  (${list.length})',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ));
      slivers.add(SliverList.builder(
        itemCount: list.length,
        itemBuilder: (context, i) => _TastingCard(tasting: list[i]),
      ));
    }
    return slivers;
  }

  Widget _header(BuildContext context, List<Tasting> all, List<String> grapes) {
    final theme = Theme.of(context);
    final scored = all.where((t) => t.score != null).toList();
    final avg = scored.isEmpty
        ? null
        : scored.fold<int>(0, (a, t) => a + t.score!) / scored.length;
    final counts = <String, int>{};
    for (final t in all) {
      for (final g in t.grapes) {
        counts[g.name] = (counts[g.name] ?? 0) + 1;
      }
    }
    String? favorite;
    if (counts.isNotEmpty) {
      favorite = (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Ad, üzüm, yer ya da notlarda ara',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          Text(
            [
              '${all.length} tadım',
              if (avg != null) 'ortalama puan ${avg.toStringAsFixed(1)}',
              if (favorite != null) 'en çok: $favorite (${counts[favorite]})',
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          Text('Sıralama: ${sortLabels[_sort]}', style: theme.textTheme.bodySmall),
          if (grapes.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('Tüm üzümler'),
                      selected: _grape == null,
                      onSelected: (_) => setState(() => _grape = null),
                    ),
                  ),
                  for (final g in grapes)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(g),
                        selected: _grape == g,
                        onSelected: (s) => setState(() => _grape = s ? g : null),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (all.any((t) => t.price != null) &&
              all.map((t) => t.currency).toSet().length > 1 &&
              (_sort == SortMode.priceAsc || _sort == SortMode.priceDesc))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Not: Fiyat sıralamasında farklı para birimleri çevrilmeden karşılaştırılır.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _TastingCard extends StatelessWidget {
  final Tasting tasting;
  const _TastingCard({required this.tasting});

  @override
  Widget build(BuildContext context) {
    final t = tasting;
    final theme = Theme.of(context);
    final meta = [
      if (t.place != null && t.place!.isNotEmpty) t.place!,
      if (t.date != null) formatDate(t.date!),
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TastingDetailPage(tastingId: t.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              TastingThumb(tasting: t),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (t.grapes.isNotEmpty)
                      Text(grapesSummary(t),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall),
                    if (meta.isNotEmpty)
                      Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    if (t.price != null)
                      Text(formatPrice(t.price!, t.currency),
                          style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ScoreBadge(score: t.score),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/icon/icon.png', width: 96, height: 96),
            ),
            const SizedBox(height: 16),
            Text('Henüz kayıtlı şarap yok', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '“Yeni Tadım” sekmesinden ilk tadım notunu ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
