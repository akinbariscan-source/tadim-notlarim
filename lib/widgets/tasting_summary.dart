import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/tasting_sheet.dart';
import '../models/tasting.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import 'common.dart';

/// Bir tadımın tüm bilgilerini salt okunur gösterir (detay sayfası ve uyarı penceresi).
class TastingSummary extends StatelessWidget {
  final Tasting tasting;
  const TastingSummary({super.key, required this.tasting});

  @override
  Widget build(BuildContext context) {
    final t = tasting;
    final theme = Theme.of(context);
    final children = <Widget>[];

    if (t.hasPhoto) {
      children.add(_Photo(tasting: t));
      children.add(const SizedBox(height: 12));
    }

    children.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                [
                  if (t.vintage != null && t.vintage!.isNotEmpty) 'Rekolte ${t.vintage}',
                  if (t.wineType != null) wineTypes[t.wineType] ?? t.wineType!,
                ].join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            ScoreBadge(score: t.score, size: 56),
            if (t.score != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(scoreLabel(t.score!), style: theme.textTheme.labelSmall),
              ),
          ],
        ),
      ],
    ));
    children.add(const SizedBox(height: 12));

    final info = <(IconData, String, String)>[
      if (t.grapes.isNotEmpty) (Icons.spa_outlined, 'Üzüm', grapesSummary(t)),
      if (t.place != null && t.place!.isNotEmpty) (Icons.place_outlined, 'Tadım yeri', t.place!),
      if (t.date != null) (Icons.event_outlined, 'Tadım tarihi', formatDate(t.date!)),
      if (t.price != null) (Icons.sell_outlined, 'Fiyat', formatPrice(t.price!, t.currency)),
      if (t.wouldBuyAgain != null)
        (Icons.replay, 'Tekrar alır mıyım?', t.wouldBuyAgain! ? 'Evet' : 'Hayır'),
      if (t.food != null && t.food!.isNotEmpty) (Icons.restaurant_outlined, 'Yemek eşleşmesi', t.food!),
    ];
    if (info.isNotEmpty) {
      children.add(Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final (icon, label, value) in info)
                ListTile(
                  dense: true,
                  leading: Icon(icon),
                  title: Text(label, style: theme.textTheme.labelMedium),
                  subtitle: Text(value, style: theme.textTheme.bodyLarge),
                ),
            ],
          ),
        ),
      ));
      children.add(const SizedBox(height: 16));
    }

    for (final section in satSections) {
      final filled = section.fields.where((f) => t.values(f.key).isNotEmpty).toList();
      if (filled.isEmpty) continue;
      children.add(SectionBand(title: '${section.tr} · ${section.en}'));
      children.add(const SizedBox(height: 8));
      for (final f in filled) {
        children.add(_SatRow(field: f, values: t.values(f.key)));
      }
      children.add(const SizedBox(height: 12));
    }

    if (t.notes != null && t.notes!.trim().isNotEmpty) {
      children.add(const SectionBand(title: 'Ek notlar'));
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
        child: SelectableText(t.notes!, style: theme.textTheme.bodyLarge),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _SatRow extends StatelessWidget {
  final SatField field;
  final List<String> values;
  const _SatRow({required this.field, required this.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content;
    if (field.kind == SatKind.descriptors) {
      content = DescriptorGroups(values: values);
    } else {
      content = Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final v in values) SmallChip(satDisplay(v))],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${field.tr} · ${field.en}',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          content,
        ],
      ),
    );
  }
}

/// Aroma/lezzetleri Primary / Secondary / Tertiary başlıkları altında gösterir.
class DescriptorGroups extends StatelessWidget {
  final List<String> values;
  final Set<String> highlight;
  const DescriptorGroups({super.key, required this.values, this.highlight = const {}});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byTier = <String, List<String>>{};
    for (final v in values) {
      final origin = descriptorOrigin(v);
      final label = origin == null ? 'Özel' : '${origin.$1.en} · ${origin.$1.tr}';
      byTier.putIfAbsent(label, () => []).add(v);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in byTier.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key, style: theme.textTheme.labelSmall),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final v in e.value) SmallChip(v, highlighted: highlight.contains(v)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SmallChip extends StatelessWidget {
  final String text;
  final bool highlighted;
  const SmallChip(this.text, {super.key, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? scheme.primary : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: highlighted ? scheme.onPrimary : scheme.onSecondaryContainer,
          fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final Tasting tasting;
  const _Photo({required this.tasting});

  @override
  Widget build(BuildContext context) {
    final repo = TastingRepository.instance;
    return FutureBuilder<Uint8List?>(
      initialData: repo.cachedPhoto(tasting.id),
      future: repo.photo(tasting.id),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) {
          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
        }
        return GestureDetector(
          onTap: () => showPhotoViewer(context, bytes),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
            ),
          ),
        );
      },
    );
  }
}
