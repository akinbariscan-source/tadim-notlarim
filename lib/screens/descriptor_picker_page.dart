import 'package:flutter/material.dart';

import '../data/tasting_sheet.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// DESCRIBING AROMA AND FLAVOUR: kümelere göre seçim, arama ve elle ekleme.
class DescriptorPickerPage extends StatefulWidget {
  final String title;
  final List<String> initial;
  const DescriptorPickerPage({super.key, required this.title, required this.initial});

  @override
  State<DescriptorPickerPage> createState() => _DescriptorPickerPageState();
}

class _DescriptorPickerPageState extends State<DescriptorPickerPage> {
  late final List<String> _selected = [...widget.initial];
  late final List<String> _custom = {
    ...TastingRepository.instance.customDescriptors(),
    ...widget.initial.where((v) => !knownDescriptors.contains(v)),
  }.toList()
    ..sort();
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String s) => _query.isEmpty || normalizeText(s).contains(normalizeText(_query));

  void _toggle(String v) {
    setState(() {
      if (_selected.contains(v)) {
        _selected.remove(v);
      } else {
        _selected.add(v);
      }
    });
  }

  void _addCustom() {
    final v = _query.trim();
    if (v.isEmpty) return;
    setState(() {
      if (!knownDescriptors.contains(v) && !_custom.contains(v)) _custom.add(v);
      if (!_selected.contains(v)) _selected.add(v);
      _search.clear();
      _query = '';
    });
  }

  void _done() => Navigator.of(context).pop(_selected);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = normalizeText(_query);
    final exact = q.isNotEmpty &&
        [...knownDescriptors, ..._custom].any((v) => normalizeText(v) == q);
    final custom = _custom.where(_matches).toList();

    final tierWidgets = <Widget>[];
    for (final tier in descriptorTiers) {
      final clusters = <Widget>[];
      for (final c in tier.clusters) {
        final items = c.items.where((i) => _matches(i) || _matches(c.name)).toList();
        if (items.isEmpty) continue;
        clusters.add(Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final i in items)
                    FilterChip(
                      label: Text(i),
                      selected: _selected.contains(i),
                      onSelected: (_) => _toggle(i),
                    ),
                ],
              ),
            ],
          ),
        ));
      }
      if (clusters.isEmpty) continue;
      tierWidgets.add(Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionBand(title: '${tier.en} Aromas and Flavours', subtitle: '${tier.tr} — ${tier.subtitle}'),
            if (_query.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Key questions: ${tier.keyQuestions}',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ),
            ...clusters,
          ],
        ),
      ));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _done();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _done,
                child: Text(_selected.isEmpty ? 'Tamam' : 'Tamam (${_selected.length})'),
              ),
            ),
          ],
        ),
        body: MaxWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Ara (örn. cherry, vanilla) ya da yeni aroma / tat yaz',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _search.clear();
                              _query = '';
                            }),
                          ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  onSubmitted: (_) {
                    if (!exact) _addCustom();
                  },
                ),
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 110),
                    child: SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final s in _selected)
                              InputChip(
                                label: Text(s),
                                selected: true,
                                onDeleted: () => _toggle(s),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    if (_query.trim().isNotEmpty && !exact)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.add_circle_outline),
                          title: Text('“${_query.trim()}” ekle'),
                          subtitle: const Text('Listede olmayan aroma / tat olarak eklenir'),
                          onTap: _addCustom,
                        ),
                      ),
                    if (custom.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kendi eklediklerin', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final c in custom)
                                  FilterChip(
                                    label: Text(c),
                                    selected: _selected.contains(c),
                                    onSelected: (_) => _toggle(c),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ...tierWidgets,
                    if (tierWidgets.isEmpty && custom.isEmpty && _query.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text('Listede eşleşme yok. Yukarıdan ekleyebilirsin.',
                            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
