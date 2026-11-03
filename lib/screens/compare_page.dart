import 'package:flutter/material.dart';

import '../data/tasting_sheet.dart';
import '../models/tasting.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tasting_summary.dart';

/// İki tadımı yan yana karşılaştırır. Farklı satırlar renklendirilir,
/// ortak seçimler koyu renkle vurgulanır.
class ComparePage extends StatelessWidget {
  final Tasting a;
  final Tasting b;
  const ComparePage({super.key, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];

    void text(String label, String? x, String? y) {
      if ((x ?? '').isEmpty && (y ?? '').isEmpty) return;
      rows.add(_CompareRow(
        label: label,
        differs: (x ?? '') != (y ?? ''),
        left: Text(x == null || x.isEmpty ? '—' : x),
        right: Text(y == null || y.isEmpty ? '—' : y),
      ));
    }

    text('Rekolte', a.vintage, b.vintage);
    text('Tip', wineTypes[a.wineType], wineTypes[b.wineType]);
    text('Üzüm', grapesSummary(a), grapesSummary(b));
    text('Tadım yeri', a.place, b.place);
    text('Tarih', a.date == null ? null : formatDate(a.date!), b.date == null ? null : formatDate(b.date!));
    text('Fiyat', a.price == null ? null : formatPrice(a.price!, a.currency),
        b.price == null ? null : formatPrice(b.price!, b.currency));
    text('Tekrar alır mıyım?', _yesNo(a.wouldBuyAgain), _yesNo(b.wouldBuyAgain));
    text('Yemek', a.food, b.food);

    for (final section in satSections) {
      final fieldRows = <Widget>[];
      for (final f in section.fields) {
        final va = a.values(f.key);
        final vb = b.values(f.key);
        if (va.isEmpty && vb.isEmpty) continue;
        final common = va.toSet().intersection(vb.toSet());
        final differs = va.toSet().length != vb.toSet().length || common.length != va.toSet().length;
        Widget side(List<String> v) {
          if (v.isEmpty) return const Text('—');
          if (f.kind == SatKind.descriptors) {
            return DescriptorGroups(values: v, highlight: common);
          }
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [for (final x in v) SmallChip(satDisplay(x), highlighted: common.contains(x))],
          );
        }

        fieldRows.add(_CompareRow(
          label: '${f.tr} · ${f.en}',
          differs: differs,
          left: side(va),
          right: side(vb),
          footer: f.kind == SatKind.descriptors && (va.isNotEmpty && vb.isNotEmpty)
              ? 'Ortak: ${common.isEmpty ? 'yok' : '${common.length} (${common.join(', ')})'}'
              : null,
        ));
      }
      if (fieldRows.isEmpty) continue;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: SectionBand(title: '${section.tr} · ${section.en}'),
      ));
      rows.addAll(fieldRows);
    }

    if ((a.notes ?? '').isNotEmpty || (b.notes ?? '').isNotEmpty) {
      rows.add(const Padding(
        padding: EdgeInsets.only(top: 16, bottom: 4),
        child: SectionBand(title: 'Ek notlar'),
      ));
      rows.add(_CompareRow(
        label: '',
        differs: false,
        left: Text(a.notes ?? '—'),
        right: Text(b.notes ?? '—'),
      ));
    }

    final diff = (a.score != null && b.score != null) ? a.score! - b.score! : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Karşılaştırma')),
      body: MaxWidth(
        width: 980,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Head(t: a, tag: 'Bu tadım')),
                const SizedBox(width: 8),
                Expanded(
                  child: _Head(
                    t: b,
                    tag: (b.date ?? b.createdAt).isBefore(a.date ?? a.createdAt)
                        ? 'Önceki tadım'
                        : 'Diğer tadım',
                  ),
                ),
              ],
            ),
            if (diff != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  diff == 0
                      ? 'Puanlar eşit'
                      : 'Puan farkı: ${diff > 0 ? '+' : ''}$diff (soldaki ${diff > 0 ? 'daha yüksek' : 'daha düşük'})',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'Farklı satırlar renkli zeminle, iki tadımda ortak olan seçimler koyu renkle gösterilir.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            ...rows,
          ],
        ),
      ),
    );
  }

  static String? _yesNo(bool? v) => v == null ? null : (v ? 'Evet' : 'Hayır');
}

class _Head extends StatelessWidget {
  final Tasting t;
  final String tag;
  const _Head({required this.t, required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(tag, style: theme.textTheme.labelSmall),
            const SizedBox(height: 6),
            TastingThumb(tasting: t, size: 72),
            const SizedBox(height: 6),
            Text(t.title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ScoreBadge(score: t.score, size: 46),
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final bool differs;
  final Widget left;
  final Widget right;
  final String? footer;

  const _CompareRow({
    required this.label,
    required this.differs,
    required this.left,
    required this.right,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: differs ? scheme.tertiaryContainer.withValues(alpha: 0.45) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: scheme.outlineVariant,
              ),
              Expanded(child: right),
            ],
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(footer!, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
