import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/tasting.dart';
import '../services/repository.dart';

/// İçeriği geniş ekranlarda (web/tablet) ortalar ve genişliği sınırlar.
class MaxWidth extends StatelessWidget {
  final Widget child;
  final double width;
  const MaxWidth({super.key, required this.child, this.width = 760});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: child,
        ),
      );
}

Color wineTypeColor(String? type) {
  switch (type) {
    case 'red':
      return const Color(0xFF8E1B36);
    case 'white':
      return const Color(0xFFD8B64A);
    case 'rose':
      return const Color(0xFFE58A9A);
    case 'sparkling':
      return const Color(0xFFC9B26B);
    case 'fortified':
      return const Color(0xFF8A4B1E);
    default:
      return const Color(0xFF7B1E3A);
  }
}

String scoreLabel(int score) {
  if (score >= 96) return 'Olağanüstü';
  if (score >= 90) return 'Mükemmel';
  if (score >= 85) return 'Çok iyi';
  if (score >= 80) return 'İyi';
  if (score >= 70) return 'Ortalama';
  if (score >= 60) return 'Ortanın altı';
  if (score >= 50) return 'Zayıf';
  return 'Kusurlu';
}

Color scoreColor(BuildContext context, int score) {
  if (score >= 90) return const Color(0xFF2E7D32);
  if (score >= 80) return const Color(0xFF558B2F);
  if (score >= 70) return const Color(0xFFF9A825);
  return Theme.of(context).colorScheme.error;
}

class ScoreBadge extends StatelessWidget {
  final int? score;
  final double size;
  const ScoreBadge({super.key, required this.score, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final s = score;
    final color = s == null ? Theme.of(context).colorScheme.outline : scoreColor(context, s);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      ),
      child: Text(
        s?.toString() ?? '–',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.36,
          color: color,
        ),
      ),
    );
  }
}

/// Kayıtlı fotoğrafın küçük resmi; fotoğraf yoksa renkli kadeh simgesi.
class TastingThumb extends StatelessWidget {
  final Tasting tasting;
  final double size;
  const TastingThumb({super.key, required this.tasting, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: wineTypeColor(tasting.wineType).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.wine_bar, color: wineTypeColor(tasting.wineType), size: size * 0.55),
    );
    if (!tasting.hasPhoto) return placeholder;
    final repo = TastingRepository.instance;
    return FutureBuilder<Uint8List?>(
      initialData: repo.cachedPhoto(tasting.id),
      future: repo.photo(tasting.id),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return placeholder;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 3).round(),
            gaplessPlayback: true,
          ),
        );
      },
    );
  }
}

/// PDF'teki yeşil başlık bantlarının şarap rengi karşılığı.
class SectionBand extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionBand({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: scheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          if (subtitle != null)
            Text(subtitle!,
                style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Fotoğrafı tam ekran, yakınlaştırılabilir gösterir.
void showPhotoViewer(BuildContext context, Uint8List bytes) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image.memory(bytes)),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String yes = 'Evet',
  String no = 'Hayır',
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(no)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
      ],
    ),
  );
  return res ?? false;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
