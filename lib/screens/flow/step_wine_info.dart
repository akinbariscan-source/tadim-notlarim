import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/grapes.dart';
import '../../models/tasting.dart';
import '../../services/ocr/ocr_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../grape_picker.dart';

/// 1. adım: etiket fotoğrafı, ad, rekolte, üzümler, yer, tarih, fiyat.
class StepWineInfo extends StatefulWidget {
  final Tasting draft;
  final Uint8List? photo;
  final ValueChanged<Uint8List?> onPhoto;
  final VoidCallback onChanged;

  const StepWineInfo({
    super.key,
    required this.draft,
    required this.photo,
    required this.onPhoto,
    required this.onChanged,
  });

  @override
  State<StepWineInfo> createState() => _StepWineInfoState();
}

class _StepWineInfoState extends State<StepWineInfo> {
  late final TextEditingController _name;
  late final TextEditingController _vintage;
  late final TextEditingController _place;
  late final TextEditingController _price;
  final Map<String, TextEditingController> _percent = {};

  bool _ocrBusy = false;
  bool _nameFromOcr = false;
  List<String> _candidates = [];

  Tasting get d => widget.draft;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: d.name);
    _vintage = TextEditingController(text: d.vintage ?? '');
    _place = TextEditingController(text: d.place ?? '');
    _price = TextEditingController(text: d.price == null ? '' : formatNumber(d.price!));
  }

  @override
  void dispose() {
    _name.dispose();
    _vintage.dispose();
    _place.dispose();
    _price.dispose();
    for (final c in _percent.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _percentCtrl(GrapePortion g) => _percent.putIfAbsent(
        g.name,
        () => TextEditingController(
          text: g.percent == null ? '' : formatPercent(g.percent!).substring(1),
        ),
      );

  // ------------------------------------------------------------ Fotoğraf --

  Future<void> _pick(ImageSource source) async {
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Fotoğraf alınamadı: $e');
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    widget.onPhoto(bytes);
    await _runOcr(file, bytes);
  }

  Future<void> _runOcr(XFile file, Uint8List bytes) async {
    if (!OcrService.isSupported) return;
    setState(() {
      _ocrBusy = true;
      _candidates = [];
    });
    try {
      final guess = await OcrService.readLabel(file, bytes);
      if (!mounted) return;
      final candidates = [...guess.candidates];
      setState(() {
        if (guess.name != null) {
          final typedByHand = d.name.trim().isNotEmpty && !_nameFromOcr;
          if (typedByHand) {
            candidates.insert(0, guess.name!);
          } else {
            _name.text = guess.name!;
            d.name = guess.name!;
            _nameFromOcr = true;
          }
        }
        if (guess.vintage != null && (d.vintage ?? '').isEmpty) {
          _vintage.text = guess.vintage!;
          d.vintage = guess.vintage;
        }
        _candidates = candidates;
      });
      widget.onChanged();
      showSnack(
        context,
        guess.isEmpty
            ? 'Etiketten ad okunamadı; bilgileri elle yazabilirsin.'
            : 'Etiket okundu. Ad ve rekolteyi kontrol et, gerekirse düzelt.',
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Etiket okunamadı; bilgileri elle yazabilirsin.');
    } finally {
      if (mounted) setState(() => _ocrBusy = false);
    }
  }

  // --------------------------------------------------------------- Üzüm --

  Future<void> _pickGrapes() async {
    final result = await showGrapePicker(context, d.grapes.map((g) => g.name).toList());
    if (result == null) return;
    setState(() {
      final old = {for (final g in d.grapes) g.name: g};
      d.grapes = [for (final name in result) old[name] ?? GrapePortion(name)];
      for (final key in _percent.keys.toList()) {
        if (!result.contains(key)) _percent.remove(key)?.dispose();
      }
      d.wineType ??= d.guessTypeFromGrapes();
    });
    widget.onChanged();
  }

  void _distributeEvenly() {
    final n = d.grapes.length;
    if (n == 0) return;
    final base = (100 / n).floorToDouble();
    setState(() {
      for (var i = 0; i < n; i++) {
        final p = i == n - 1 ? 100 - base * (n - 1) : base;
        d.grapes[i].percent = p;
        _percentCtrl(d.grapes[i]).text = formatPercent(p).substring(1);
      }
    });
    widget.onChanged();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: d.date ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Tadım tarihi',
    );
    if (picked == null) return;
    setState(() => d.date = picked);
    widget.onChanged();
  }

  // -------------------------------------------------------------- Arayüz --

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPercent = d.grapes.fold<double>(0, (a, g) => a + (g.percent ?? 0));
    final anyPercent = d.grapes.any((g) => g.percent != null);

    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _photoCard(theme),
          const SizedBox(height: 20),
          Text('Şarap bilgileri', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Fotoğraf çekmeden de adı ve rekolteyi doğrudan yazabilirsin.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Şarabın adı *',
              prefixIcon: Icon(Icons.wine_bar_outlined),
            ),
            onChanged: (v) {
              d.name = v;
              _nameFromOcr = false;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vintage,
            decoration: const InputDecoration(
              labelText: 'Rekolte',
              hintText: 'örn. 2019 · yıl yoksa NV',
              prefixIcon: Icon(Icons.calendar_month_outlined),
            ),
            onChanged: (v) {
              d.vintage = v.trim().isEmpty ? null : v.trim();
              widget.onChanged();
            },
          ),
          const SizedBox(height: 16),
          Text('Şarap tipi (isteğe bağlı)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in wineTypes.entries)
                ChoiceChip(
                  label: Text(e.value),
                  avatar: Icon(Icons.circle, size: 12, color: wineTypeColor(e.key)),
                  selected: d.wineType == e.key,
                  onSelected: (s) {
                    setState(() => d.wineType = s ? e.key : null);
                    widget.onChanged();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Üzüm (isteğe bağlı)', style: theme.textTheme.titleMedium)),
              if (d.grapes.length > 1)
                TextButton(onPressed: _distributeEvenly, child: const Text('Eşit dağıt')),
            ],
          ),
          if (d.grapes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Yüzde oranlarını girmek isteğe bağlıdır.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final g in d.grapes) _grapeRow(g, theme),
          if (anyPercent)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Toplam: ${formatPercent(totalPercent)}'
                '${(totalPercent - 100).abs() > 0.01 ? '  (toplam %100 olmalı)' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (totalPercent - 100).abs() > 0.01 ? theme.colorScheme.error : null,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _pickGrapes,
              icon: const Icon(Icons.add),
              label: Text(d.grapes.isEmpty ? 'Üzüm seç' : 'Üzümleri düzenle'),
            ),
          ),
          const SizedBox(height: 20),
          Text('Tadım bilgileri (isteğe bağlı)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _place,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tadım yeri',
              hintText: 'örn. evde, restoran adı, şarap evi…',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            onChanged: (v) {
              d.place = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tadım tarihi',
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: d.date == null
                    ? null
                    : IconButton(
                        tooltip: 'Tarihi temizle',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => d.date = null);
                          widget.onChanged();
                        },
                      ),
              ),
              child: Text(d.date == null ? 'Seçilmedi' : formatDate(d.date!)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fiyat',
                    hintText: 'örn. 1.250',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  onChanged: (v) {
                    d.price = parsePrice(v);
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: DropdownButton<String>(
                  value: d.currency,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final e in currencies.entries)
                      DropdownMenuItem(value: e.key, child: Text('${e.value}  ${e.key}')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => d.currency = v);
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grapeRow(GrapePortion g, ThemeData theme) {
    final grape = findGrape(g.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle,
              size: 12,
              color: grape == null
                  ? theme.colorScheme.outline
                  : (grape.isRed ? wineTypeColor('red') : wineTypeColor('white'))),
          const SizedBox(width: 10),
          Expanded(child: Text(g.name, style: theme.textTheme.bodyLarge)),
          SizedBox(
            width: 92,
            child: TextField(
              controller: _percentCtrl(g),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(prefixText: '% ', hintText: '—'),
              onChanged: (v) {
                final p = double.tryParse(v.replaceAll(',', '.').trim());
                setState(() => g.percent = (p == null || p < 0 || p > 100) ? null : p);
                widget.onChanged();
              },
            ),
          ),
          IconButton(
            tooltip: 'Kaldır',
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                d.grapes.remove(g);
                _percent.remove(g.name)?.dispose();
              });
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _photoCard(ThemeData theme) {
    final scheme = theme.colorScheme;
    final photo = widget.photo;
    if (photo == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_camera_outlined, size: 48, color: scheme.primary),
            const SizedBox(height: 8),
            Text('Etiketin fotoğrafını çek', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Şarabın adı (etiketteki en büyük yazı) ve rekoltesi otomatik okunur.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Fotoğraf çek'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeriden seç'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => showPhotoViewer(context, photo),
            child: Container(
              color: Colors.black,
              height: 240,
              child: Image.memory(photo, fit: BoxFit.contain, gaplessPlayback: true),
            ),
          ),
          if (_ocrBusy) ...[
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                kIsWeb
                    ? 'Etiket okunuyor… (ilk kullanımda okuma motoru indirilir, biraz sürebilir)'
                    : 'Etiket okunuyor…',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          if (_candidates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ad bu değilse etikette okunan diğer yazılardan seç:',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in _candidates)
                        ActionChip(
                          label: Text(c),
                          onPressed: () {
                            setState(() {
                              _name.text = c;
                              d.name = c;
                            });
                            widget.onChanged();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 4,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _ocrBusy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Yeniden çek'),
                ),
                TextButton.icon(
                  onPressed: _ocrBusy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
                TextButton.icon(
                  onPressed: _ocrBusy
                      ? null
                      : () {
                          widget.onPhoto(null);
                          setState(() => _candidates = []);
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Kaldır'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
