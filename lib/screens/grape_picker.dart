import 'package:flutter/material.dart';

import '../data/grapes.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Üzüm seçme penceresi. Seçilen üzüm adlarını (sırasıyla) döndürür.
Future<List<String>?> showGrapePicker(BuildContext context, List<String> selected) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => _GrapePickerSheet(initial: selected),
  );
}

class _GrapePickerSheet extends StatefulWidget {
  final List<String> initial;
  const _GrapePickerSheet({required this.initial});

  @override
  State<_GrapePickerSheet> createState() => _GrapePickerSheetState();
}

class _GrapePickerSheetState extends State<_GrapePickerSheet> {
  late final List<String> _selected = [...widget.initial];
  final _search = TextEditingController();
  String _query = '';

  late final List<String> _custom = {
    ...TastingRepository.instance.usedGrapes(),
    ...widget.initial,
  }.where((n) => findGrape(n) == null).toList()
    ..sort();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String text) => _query.isEmpty || normalizeText(text).contains(normalizeText(_query));

  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  void _addCustom() {
    final name = _query.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_custom.contains(name)) _custom.add(name);
      if (!_selected.contains(name)) _selected.add(name);
      _search.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final world = worldGrapes.where((g) => _matches(g.name)).toList();
    final turkish = turkishGrapes.where((g) => _matches(g.name)).toList();
    final custom = _custom.where(_matches).toList();
    final exact = _query.isNotEmpty &&
        [...allGrapes.map((g) => g.name), ..._custom]
            .any((n) => normalizeText(n) == normalizeText(_query));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(child: Text('Üzüm seç', style: theme.textTheme.titleLarge)),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text(_selected.isEmpty ? 'Tamam' : 'Tamam (${_selected.length})'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Üzüm ara ya da listede olmayanı yaz',
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in _selected)
                      InputChip(label: Text(s), onDeleted: () => _toggle(s)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (_query.trim().isNotEmpty && !exact)
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text('“${_query.trim()}” üzümünü ekle'),
                    subtitle: const Text('Listede olmayan bir üzüm olarak eklenir'),
                    onTap: _addCustom,
                  ),
                if (custom.isNotEmpty) ...[
                  const _Header('Eklediklerin'),
                  for (final n in custom)
                    CheckboxListTile(
                      value: _selected.contains(n),
                      onChanged: (_) => _toggle(n),
                      title: Text(n),
                    ),
                ],
                if (world.isNotEmpty) ...[
                  const _Header('Dünyada en çok ekilen 50 üzüm'),
                  for (final g in world) _tile(g),
                ],
                if (turkish.isNotEmpty) ...[
                  const _Header('Türkiye’nin yerli üzümleri'),
                  for (final g in turkish) _tile(g),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _tile(Grape g) => CheckboxListTile(
        value: _selected.contains(g.name),
        onChanged: (_) => _toggle(g.name),
        title: Text(g.name),
        subtitle: Text('${g.isRed ? 'Kırmızı' : 'Beyaz'} · ${g.regions}'),
        secondary: Icon(Icons.circle,
            size: 14, color: g.isRed ? wineTypeColor('red') : wineTypeColor('white')),
      );
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}
