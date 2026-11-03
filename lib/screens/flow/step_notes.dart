import 'package:flutter/material.dart';

import '../../data/tasting_sheet.dart';
import '../../models/tasting.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// 4. adım: ek notlar ve kayıt özeti.
class StepNotes extends StatefulWidget {
  final Tasting draft;
  final VoidCallback onChanged;
  const StepNotes({super.key, required this.draft, required this.onChanged});

  @override
  State<StepNotes> createState() => _StepNotesState();
}

class _StepNotesState extends State<StepNotes> {
  late final TextEditingController _food = TextEditingController(text: widget.draft.food ?? '');
  late final TextEditingController _notes = TextEditingController(text: widget.draft.notes ?? '');

  @override
  void dispose() {
    _food.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final theme = Theme.of(context);
    final total = satSections.fold<int>(0, (a, s) => a + s.fields.length);
    final filled = satSections.fold<int>(
        0, (a, s) => a + s.fields.where((f) => d.values(f.key).isNotEmpty).length);

    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextField(
            controller: _notes,
            minLines: 6,
            maxLines: 14,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Ek notlar',
              hintText: 'Genel izlenim, kiminle içtin, servis sıcaklığı, dekantasyon…',
              alignLabelWithHint: true,
            ),
            onChanged: (v) {
              d.notes = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _food,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Yemek eşleşmesi (isteğe bağlı)',
              hintText: 'örn. kuzu tandır, olgun peynirler',
              prefixIcon: Icon(Icons.restaurant_outlined),
            ),
            onChanged: (v) {
              d.food = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kaydedilecekler', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _line(theme, 'Şarap', d.title.isEmpty ? '—' : d.title),
                  if (d.grapes.isNotEmpty) _line(theme, 'Üzüm', grapesSummary(d)),
                  if (d.place != null && d.place!.trim().isNotEmpty) _line(theme, 'Yer', d.place!),
                  if (d.date != null) _line(theme, 'Tarih', formatDate(d.date!)),
                  if (d.price != null) _line(theme, 'Fiyat', formatPrice(d.price!, d.currency)),
                  _line(theme, 'Tadım notu', '$filled / $total alan dolduruldu'),
                  _line(theme, 'Puan', d.score == null ? 'verilmedi' : '${d.score} · ${scoreLabel(d.score!)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kaydet’e bastığında, daha önce aynı şarabı ya da aynı üzümlerden bir şarabı '
            'tattıysan sana haber verip karşılaştırma önereceğim.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _line(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Text(label, style: theme.textTheme.bodySmall)),
            Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
}
