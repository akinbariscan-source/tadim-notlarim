import 'package:flutter/material.dart';

import '../models/tasting.dart';
import '../services/repository.dart';
import '../services/similarity.dart';
import '../widgets/common.dart';
import '../widgets/tasting_summary.dart';
import 'compare_page.dart';
import 'pick_tasting_sheet.dart';

/// Kayıttan sonra: aynı şarap ya da aynı üzümlerden şarap daha önce tadıldıysa
/// haber verir, eski notları gösterir ve karşılaştırma önerir.
Future<void> runSimilarityPrompt(BuildContext context, Tasting saved) async {
  final matches = findSimilar(saved, TastingRepository.instance.all);
  if (matches.sameWine.isNotEmpty) {
    final list = matches.sameWine;
    final sameVintage = list.any((o) => (o.vintage ?? '') == (saved.vintage ?? ''));
    final times = list.length > 1 ? ' (${list.length} kez)' : '';
    await _offer(
      context,
      saved,
      list,
      title: 'Bu şarabı daha önce içtin',
      message: sameVintage
          ? 'Daha önce aynı şarabı içtin$times. Görüntülemek ister misin?'
          : 'Bu şarabın farklı bir rekoltesini daha önce içtin$times. Görüntülemek ister misin?',
    );
  } else if (matches.similarGrapes.isNotEmpty) {
    final list = matches.similarGrapes;
    final common = commonGrapes(saved, list.first);
    final same = grapeSimilarity(saved, list.first) >= 0.999;
    await _offer(
      context,
      saved,
      list,
      title: 'Daha önce benzer bir tadım yaptın',
      message: same
          ? 'Aynı üzümlerden (${common.join(', ')}) yapılmış bir şarabı daha önce tattın. '
              'Görüntülemek ister misin?'
          : 'Benzer üzümlerden (${common.join(', ')}) yapılmış bir şarabı daha önce tattın. '
              'Görüntülemek ister misin?',
    );
  }
}

Future<void> _offer(
  BuildContext context,
  Tasting saved,
  List<Tasting> matches, {
  required String title,
  required String message,
}) async {
  final view = await confirmDialog(context,
      title: title, message: message, yes: 'Görüntüle', no: 'Hayır');
  if (!view || !context.mounted) return;

  final target = matches.length == 1
      ? matches.first
      : await pickTasting(context, matches, title: 'Hangisini görüntülemek istersin?');
  if (target == null || !context.mounted) return;

  final compare = await showOldNotes(context, target);
  if (compare == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ComparePage(a: saved, b: target)),
    );
  }
}

/// Eski tadımın notlarını gösterir; altta "Karşılaştırmak ister misin?" sorar.
Future<bool?> showOldNotes(BuildContext context, Tasting old) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.88,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [TastingSummary(tasting: old)],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Text('Karşılaştırmak ister misin?',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hayır'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.compare_arrows),
                          label: const Text('Evet, karşılaştır'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
