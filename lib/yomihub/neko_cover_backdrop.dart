// YomiHub: Nekoyomi-style blurred cover backdrop and Anikku-style
// "theme colour from cover" for the entry detail page.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/utils/cached_network.dart';
import 'package:mangayomi/utils/constant.dart';
import 'package:mangayomi/utils/headers.dart';
import 'package:mangayomi/yomihub/neko_ui_prefs.dart';

String _coverUrl(Manga manga) =>
    toImgUrl(manga.customCoverFromTracker ?? manga.imageUrl ?? "");

Map<String, String>? _coverHeaders(WidgetRef ref, Manga manga) {
  if (manga.isLocalArchive ?? false) return null;
  if (manga.source == null || manga.lang == null) return null;
  return ref.watch(
    headersProvider(
      source: manga.source!,
      lang: manga.lang!,
      sourceId: manga.sourceId,
    ),
  );
}

/// Full-page blurred cover drawn behind the (transparent) detail scaffold.
/// Opacity / blur / dim follow the Nekoyomi preferences.
class NekoCoverBackdrop extends ConsumerWidget {
  final Manga manga;

  const NekoCoverBackdrop({super.key, required this.manga});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(nekoUiPrefsProvider);
    if (!p.backdropEnabled || p.backdropOpacity == 0) {
      return const SizedBox.shrink();
    }
    final Widget image = manga.customCoverImage != null
        ? Image.memory(
            Uint8List.fromList(manga.customCoverImage!),
            fit: BoxFit.cover,
          )
        : cachedCompressedNetworkImage(
            headers: _coverHeaders(ref, manga),
            imageUrl: _coverUrl(manga),
            width: null,
            height: null,
            fit: BoxFit.cover,
            errorWidget: const SizedBox.shrink(),
            maxBytes: 256 << 10,
          );
    final sigma = p.backdropBlur.toDouble();
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: p.backdropOpacity / 100.0,
              child: sigma > 0
                  ? ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: sigma,
                        sigmaY: sigma,
                        tileMode: TileMode.decal,
                      ),
                      child: image,
                    )
                  : image,
            ),
            if (p.backdropDim > 0)
              ColoredBox(
                color: Colors.black.withValues(alpha: p.backdropDim / 100.0),
              ),
          ],
        ),
      ),
    );
  }
}

/// Re-themes [child] with a colour scheme extracted from the entry's cover
/// (Anikku "auto theme color"). Falls back to the app theme while the cover
/// loads, when extraction fails, or when the preference is off.
class CoverColorTheme extends ConsumerStatefulWidget {
  final Manga manga;
  final Widget child;

  const CoverColorTheme({super.key, required this.manga, required this.child});

  @override
  ConsumerState<CoverColorTheme> createState() => _CoverColorThemeState();
}

class _CoverColorThemeState extends ConsumerState<CoverColorTheme> {
  ColorScheme? _scheme;
  Brightness? _brightness;
  String? _key;

  void _maybeExtract(Brightness brightness) {
    final manga = widget.manga;
    final key = '${manga.id}|${_coverUrl(manga)}|'
        '${manga.customCoverImage?.length ?? 0}|$brightness';
    if (key == _key) return;
    _key = key;
    _brightness = brightness;
    final ImageProvider provider = manga.customCoverImage != null
        ? ResizeImage(
            MemoryImage(Uint8List.fromList(manga.customCoverImage!)),
            width: 112,
          )
        : coverProvider(
            _coverUrl(manga),
            headers: _coverHeaders(ref, manga),
            maxBytes: 64 << 10,
          );
    ColorScheme.fromImageProvider(provider: provider, brightness: brightness)
        .then((scheme) {
          if (!mounted || _key != key) return;
          setState(() => _scheme = scheme);
        })
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(nekoUiPrefsProvider.select((p) => p.coverTheme));
    if (!enabled) return widget.child;
    final theme = Theme.of(context);
    _maybeExtract(theme.brightness);
    final scheme = _scheme;
    if (scheme == null || _brightness != theme.brightness) {
      return widget.child;
    }
    return Theme(
      data: theme.copyWith(
        colorScheme: scheme.copyWith(
          // Keep the app's surfaces so text contrast and the pure-black
          // option are preserved; only accents follow the cover.
          surface: theme.colorScheme.surface,
          onSurface: theme.colorScheme.onSurface,
        ),
        progressIndicatorTheme: theme.progressIndicatorTheme.copyWith(
          color: scheme.primary,
        ),
      ),
      child: widget.child,
    );
  }
}
