import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/tasting_sheet.dart';
import '../../models/tasting.dart';
import '../../services/repository.dart';
import '../../widgets/common.dart';
import 'step_notes.dart';
import 'step_sat.dart';
import 'step_score.dart';
import 'step_wine_info.dart';

/// Yeni tadım (ya da düzenleme) akışı: Şarap → Tadım Notu → Puan → Notlar.
class TastingFlowPage extends StatefulWidget {
  /// Düzenlenecek kayıt (yeni tadımda null).
  final Tasting? initial;

  /// Kayıt tamamlandığında çağrılır.
  final ValueChanged<Tasting>? onSaved;

  const TastingFlowPage({super.key, this.initial, this.onSaved});

  @override
  State<TastingFlowPage> createState() => _TastingFlowPageState();
}

class _TastingFlowPageState extends State<TastingFlowPage> {
  static const _stepTitles = ['Şarap', 'Tadım Notu', 'Puan', 'Notlar'];

  late Tasting _draft;
  Uint8List? _photo;
  bool _photoChanged = false;
  int _step = 0;
  bool _satAttempted = false;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial?.copy() ?? Tasting.empty();
    if (_isEditing && _draft.hasPhoto) {
      TastingRepository.instance.photo(_draft.id).then((bytes) {
        if (mounted && !_photoChanged) setState(() => _photo = bytes);
      });
    }
  }

  void _changed() => setState(() {});

  bool _validateInfo() {
    if (_draft.name.trim().isEmpty) {
      showSnack(context, 'Lütfen şarabın adını yaz ya da etiketin fotoğrafını çek.');
      return false;
    }
    return true;
  }

  Future<void> _goTo(int target) async {
    if (target == _step || _saving) return;
    if (target > _step) {
      if (_step == 0 && !_validateInfo()) return;
      if (_step <= 1 && target >= 2 && !await _confirmSatEmpty()) return;
    }
    setState(() => _step = target);
  }

  /// Boş bırakılan sistematik alanlarını hatırlatır. Devam edilecekse true.
  Future<bool> _confirmSatEmpty() async {
    final empty = <SatSection, List<SatField>>{};
    for (final s in satSections) {
      for (final f in s.fields) {
        if (_draft.values(f.key).isEmpty) empty.putIfAbsent(s, () => []).add(f);
      }
    }
    if (empty.isEmpty) return true;
    setState(() => _satAttempted = true);
    final count = empty.values.fold<int>(0, (a, l) => a + l.length);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('Boş bırakılan alanlar var'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count alan boş bırakıldı. Hepsi isteğe bağlı, '
                    'ama kontrol etmek isteyebilirsin:'),
                const SizedBox(height: 12),
                for (final e in empty.entries) ...[
                  Text(e.key.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8, top: 2),
                    child: Text(e.value.map((f) => f.tr).join(', ')),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Geri dön, doldur'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Boş bırak, devam et'),
          ),
        ],
      ),
    );
    if (proceed != true) {
      if (mounted && _step != 1) setState(() => _step = 1);
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_validateInfo()) {
      setState(() => _step = 0);
      return;
    }
    final missing = <String>[
      if (_draft.score == null) 'Puan',
      if ((_draft.notes ?? '').trim().isEmpty) 'Ek notlar',
    ];
    if (missing.isNotEmpty) {
      final ok = await confirmDialog(
        context,
        title: 'Boş bırakılan alanlar',
        message: '${missing.join(' ve ')} boş bırakıldı. Yine de kaydedilsin mi?',
        yes: 'Kaydet',
        no: 'Geri dön',
      );
      if (!ok) {
        setState(() => _step = _draft.score == null ? 2 : 3);
        return;
      }
    }
    setState(() => _saving = true);
    _tidy(_draft);
    try {
      await TastingRepository.instance.save(
        _draft,
        photo: _photoChanged ? _photo : null,
        removePhoto: _photoChanged && _photo == null,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Kaydedilemedi: $e');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    showSnack(context, '“${_draft.name}” kaydedildi.');
    widget.onSaved?.call(_draft);
  }

  void _tidy(Tasting t) {
    String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
    t.name = t.name.trim();
    t.vintage = clean(t.vintage);
    t.place = clean(t.place);
    t.food = clean(t.food);
    t.notes = clean(t.notes);
  }

  Future<void> _reset() async {
    final ok = await confirmDialog(
      context,
      title: 'Formu temizle',
      message: 'Girdiğin bilgiler silinsin ve yeni bir tadıma başlansın mı?',
      yes: 'Temizle',
      no: 'Vazgeç',
    );
    if (!ok) return;
    setState(() {
      _draft = Tasting.empty();
      _photo = null;
      _photoChanged = false;
      _step = 0;
      _satAttempted = false;
    });
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return StepWineInfo(
          key: ValueKey('info-${_draft.id}'),
          draft: _draft,
          photo: _photo,
          onPhoto: (bytes) => setState(() {
            _photo = bytes;
            _photoChanged = true;
          }),
          onChanged: _changed,
        );
      case 1:
        return StepSat(
          key: ValueKey('sat-${_draft.id}'),
          draft: _draft,
          showEmpty: _satAttempted,
          onChanged: _changed,
        );
      case 2:
        return StepScore(key: ValueKey('score-${_draft.id}'), draft: _draft, onChanged: _changed);
      default:
        return StepNotes(key: ValueKey('notes-${_draft.id}'), draft: _draft, onChanged: _changed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _stepTitles.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? const Text('Tadımı düzenle')
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/icon/icon.png', width: 32, height: 32),
                  ),
                  const SizedBox(width: 10),
                  const Text('Tadım Notlarım'),
                ],
              ),
        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: 'Formu temizle',
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
            ),
        ],
      ),
      body: Column(
        children: [
          _StepIndicator(titles: _stepTitles, current: _step, onTap: _goTo),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildStep(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: MaxWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (_step > 0) ...[
                  OutlinedButton.icon(
                    onPressed: () => _goTo(_step - 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Geri'),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: _saving ? null : (isLast ? _save : () => _goTo(_step + 1)),
                    icon: _saving
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(isLast ? Icons.save_outlined : Icons.arrow_forward),
                    label: Text(isLast ? 'Kaydet' : 'Devam Et'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final List<String> titles;
  final int current;
  final ValueChanged<int> onTap;
  const _StepIndicator({required this.titles, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MaxWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < titles.length; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: i <= current ? scheme.primary : scheme.surfaceContainerHighest,
                          foregroundColor: i <= current ? scheme.onPrimary : scheme.onSurfaceVariant,
                          child: i < current
                              ? const Icon(Icons.check, size: 16)
                              : Text('${i + 1}', style: const TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          titles[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == current ? FontWeight.bold : FontWeight.normal,
                            color: i == current ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
