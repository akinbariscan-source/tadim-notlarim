import 'package:flutter/material.dart';

import '../../data/tasting_sheet.dart';
import '../../models/tasting.dart';
import '../../services/repository.dart';
import '../../widgets/common.dart';
import '../descriptor_picker_page.dart';

/// 2. adım: TADIM NOTLARI.pdf'teki sistematik (her satırda çoklu seçim).
class StepSat extends StatefulWidget {
  final Tasting draft;
  final bool showEmpty;
  final VoidCallback onChanged;

  const StepSat({
    super.key,
    required this.draft,
    required this.showEmpty,
    required this.onChanged,
  });

  @override
  State<StepSat> createState() => _StepSatState();
}

class _StepSatState extends State<StepSat> {
  Tasting get d => widget.draft;

  void _toggle(String key, String value) {
    final list = [...d.values(key)];
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    setState(() => d.setValues(key, list));
    widget.onChanged();
  }

  void _set(String key, List<String> values) {
    setState(() => d.setValues(key, values));
    widget.onChanged();
  }

  Future<void> _addCustomObservation(SatField f) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${f.tr} ekle'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'örn. yoğun bacak, tortu yok…'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Ekle')),
        ],
      ),
    );
    ctrl.dispose();
    final v = text?.trim() ?? '';
    if (v.isEmpty || d.values(f.key).contains(v)) return;
    _set(f.key, [...d.values(f.key), v]);
  }

  Future<void> _openDescriptors(SatField f) async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => DescriptorPickerPage(
          title: f.key == 'aroma' ? 'Aromalar (koku)' : 'Lezzetler (damak)',
          initial: d.values(f.key),
        ),
      ),
    );
    if (result != null) _set(f.key, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = satSections.fold<int>(0, (a, s) => a + s.fields.length);
    final filled = satSections.fold<int>(
        0, (a, s) => a + s.fields.where((f) => d.values(f.key).isNotEmpty).length);

    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.checklist, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Her satırda bir veya birden fazla seçeneği işaretleyebilirsin. '
                      'Tüm alanlar isteğe bağlı; boş bıraktıklarını devam ederken hatırlatırım.\n'
                      'Doldurulan: $filled / $total',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final section in satSections) ...[
            SectionBand(title: section.en, subtitle: section.tr),
            const SizedBox(height: 4),
            for (final f in section.fields) _field(f, theme),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _field(SatField f, ThemeData theme) {
    final values = d.values(f.key);
    final isEmpty = values.isEmpty;
    final scheme = theme.colorScheme;

    Widget body = const SizedBox.shrink();
    switch (f.kind) {
      case SatKind.scale:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final g in f.groups) ...[
              if (g.label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(g.label!,
                      style: theme.textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic)),
                ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final o in g.options)
                    FilterChip(
                      label: Text(o),
                      selected: values.contains(g.valueOf(o)),
                      onSelected: (_) => _toggle(f.key, g.valueOf(o)),
                    ),
                ],
              ),
            ],
          ],
        );
        break;
      case SatKind.observations:
        final known = f.groups.expand((g) => g.options).toList();
        final extra = <String>{
          ...values.where((v) => !known.contains(v)),
          ...TastingRepository.instance.customValues(f.key, known),
        }.toList();
        body = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in [...known, ...extra])
              FilterChip(
                label: Text(o),
                selected: values.contains(o),
                onSelected: (_) => _toggle(f.key, o),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Ekle'),
              onPressed: () => _addCustomObservation(f),
            ),
          ],
        );
        break;
      case SatKind.descriptors:
        final copyFromNose = f.key == 'flavour' && d.aromas.isNotEmpty;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'e.g. primary, secondary, tertiary — listeden seç, ara ya da kendin ekle.',
              style: theme.textTheme.bodySmall,
            ),
            if (values.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final v in values)
                    InputChip(
                      label: Text(v),
                      onDeleted: () => _set(f.key, [...values]..remove(v)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openDescriptors(f),
                  icon: const Icon(Icons.manage_search),
                  label: Text(f.key == 'aroma' ? 'Aroma seç / ara / ekle' : 'Lezzet seç / ara / ekle'),
                ),
                if (copyFromNose)
                  TextButton.icon(
                    onPressed: () => _set(f.key, {...values, ...d.aromas}.toList()),
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: const Text('Kokudakileri ekle'),
                  ),
              ],
            ),
          ],
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: f.tr,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '  ${f.en}',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              if (isEmpty && widget.showEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Boş bırakıldı',
                      style: TextStyle(fontSize: 11, color: scheme.onTertiaryContainer)),
                ),
              if (!isEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Temizle',
                  icon: const Icon(Icons.backspace_outlined, size: 18),
                  onPressed: () => _set(f.key, []),
                ),
            ],
          ),
          const SizedBox(height: 6),
          body,
        ],
      ),
    );
  }
}
