import 'package:flutter/material.dart';

import '../models/tasting.dart';
import '../services/repository.dart';
import '../services/similarity.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/tasting_summary.dart';
import 'compare_page.dart';
import 'flow/tasting_flow_page.dart';
import 'pick_tasting_sheet.dart';

class TastingDetailPage extends StatelessWidget {
  final String tastingId;
  const TastingDetailPage({super.key, required this.tastingId});

  Future<void> _edit(BuildContext context, Tasting t) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TastingFlowPage(
          initial: t,
          onSaved: (_) => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Tasting t) async {
    final ok = await confirmDialog(
      context,
      title: 'Tadımı sil',
      message: '“${t.title}” kalıcı olarak silinsin mi?',
      yes: 'Sil',
      no: 'Vazgeç',
    );
    if (!ok) return;
    await TastingRepository.instance.delete(t.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _compareWithAny(BuildContext context, Tasting t) async {
    final others = TastingRepository.instance.all.where((o) => o.id != t.id).toList()
      ..sort((a, b) => grapeSimilarity(t, b).compareTo(grapeSimilarity(t, a)));
    if (others.isEmpty) {
      showSnack(context, 'Karşılaştırmak için en az iki kayıt gerekli.');
      return;
    }
    final other = await pickTasting(context, others, title: 'Neyle karşılaştıralım?');
    if (other == null || !context.mounted) return;
    _openCompare(context, t, other);
  }

  void _openCompare(BuildContext context, Tasting a, Tasting b) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComparePage(a: a, b: b)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = TastingRepository.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final t = repo.byId(tastingId);
        if (t == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Kayıt bulunamadı')),
          );
        }
        final similar = findSimilar(t, repo.all);
        final related = [...similar.sameWine, ...similar.similarGrapes];
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(t.title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Karşılaştır',
                icon: const Icon(Icons.compare_arrows),
                onPressed: () => _compareWithAny(context, t),
              ),
              IconButton(
                tooltip: 'Düzenle',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(context, t),
              ),
              IconButton(
                tooltip: 'Sil',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, t),
              ),
            ],
          ),
          body: MaxWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                TastingSummary(tasting: t),
                if (related.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const SectionBand(title: 'Benzer tadımların'),
                  const SizedBox(height: 4),
                  for (final o in related.take(6))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: TastingThumb(tasting: o, size: 48),
                      title: Text(o.title),
                      subtitle: Text(
                        similar.sameWine.contains(o)
                            ? 'Aynı şarap${o.date != null ? ' · ${formatDate(o.date!)}' : ''}'
                            : 'Ortak üzüm: ${commonGrapes(t, o).join(', ')}',
                      ),
                      trailing: TextButton(
                        onPressed: () => _openCompare(context, t, o),
                        child: const Text('Karşılaştır'),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Kaydedildi: ${formatDate(t.createdAt)}'
                  '${t.updatedAt.difference(t.createdAt).inMinutes > 1 ? ' · Güncellendi: ${formatDate(t.updatedAt)}' : ''}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
