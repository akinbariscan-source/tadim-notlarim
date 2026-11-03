import 'package:flutter/material.dart';

import '../models/tasting.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Listeden bir tadım seçtirir (karşılaştırma için).
Future<Tasting?> pickTasting(
  BuildContext context,
  List<Tasting> candidates, {
  String title = 'Bir tadım seç',
}) {
  return showModalBottomSheet<Tasting>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => _PickSheet(candidates: candidates, title: title),
  );
}

class _PickSheet extends StatefulWidget {
  final List<Tasting> candidates;
  final String title;
  const _PickSheet({required this.candidates, required this.title});

  @override
  State<_PickSheet> createState() => _PickSheetState();
}

class _PickSheetState extends State<_PickSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = normalizeText(_query);
    final items = widget.candidates.where((t) {
      if (q.isEmpty) return true;
      return normalizeText('${t.name} ${t.vintage ?? ''} ${grapesSummary(t)}').contains(q);
    }).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(widget.title, style: theme.textTheme.titleLarge),
            ),
            if (widget.candidates.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Ara',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Kayıt bulunamadı'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final t = items[i];
                        return ListTile(
                          leading: TastingThumb(tasting: t, size: 48),
                          title: Text(t.title),
                          subtitle: Text(
                            [
                              if (t.grapes.isNotEmpty) grapesSummary(t),
                              if (t.date != null) formatDate(t.date!),
                            ].join('\n'),
                          ),
                          trailing: ScoreBadge(score: t.score, size: 38),
                          onTap: () => Navigator.pop(context, t),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
