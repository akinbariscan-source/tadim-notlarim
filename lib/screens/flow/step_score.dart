import 'package:flutter/material.dart';

import '../../models/tasting.dart';
import '../../widgets/common.dart';

/// 3. adım: 100 üzerinden puan.
class StepScore extends StatefulWidget {
  final Tasting draft;
  final VoidCallback onChanged;
  const StepScore({super.key, required this.draft, required this.onChanged});

  @override
  State<StepScore> createState() => _StepScoreState();
}

class _StepScoreState extends State<StepScore> {
  static const _bands = [
    ('96–100', 'Olağanüstü'),
    ('90–95', 'Mükemmel'),
    ('85–89', 'Çok iyi'),
    ('80–84', 'İyi'),
    ('70–79', 'Ortalama'),
    ('60–69', 'Ortanın altı'),
    ('50–59', 'Zayıf'),
    ('0–49', 'Kusurlu'),
  ];

  Tasting get d => widget.draft;

  void _set(int? v) {
    setState(() => d.score = v == null ? null : v.clamp(0, 100).toInt());
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = d.score;
    final color = score == null ? theme.colorScheme.outline : scoreColor(context, score);

    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Text('Şaraba 100 üzerinden puan ver',
              textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton.filledTonal(
                  onPressed: score == null || score <= 0 ? null : () => _set(score - 1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                Text(
                  score?.toString() ?? '–',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14, left: 4),
                  child: Text('/100', style: theme.textTheme.titleMedium),
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  onPressed: score != null && score >= 100 ? null : () => _set((score ?? 84) + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Text(
            score == null ? 'Henüz puan verilmedi' : scoreLabel(score),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 12),
          Slider(
            value: (score ?? 85).toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '${score ?? 85}',
            onChanged: (v) => _set(v.round()),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in [80, 85, 88, 90, 92, 95])
                ChoiceChip(
                  label: Text('$v'),
                  selected: score == v,
                  onSelected: (_) => _set(v),
                ),
              if (score != null)
                ActionChip(
                  avatar: const Icon(Icons.clear, size: 18),
                  label: const Text('Temizle'),
                  onPressed: () => _set(null),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Bu şarabı tekrar alır mısın? (isteğe bağlı)',
              textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Center(
            child: SegmentedButton<bool>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: true, label: Text('Evet'), icon: Icon(Icons.thumb_up_outlined)),
                ButtonSegment(value: false, label: Text('Hayır'), icon: Icon(Icons.thumb_down_outlined)),
              ],
              selected: {if (d.wouldBuyAgain != null) d.wouldBuyAgain!},
              onSelectionChanged: (s) {
                setState(() => d.wouldBuyAgain = s.isEmpty ? null : s.first);
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(height: 28),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Puan rehberi', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  for (final (range, label) in _bands)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(width: 70, child: Text(range, style: theme.textTheme.bodySmall)),
                          Text(label, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
