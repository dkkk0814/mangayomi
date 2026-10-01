// YomiHub: Nekoyomi-style UI preferences.
//
// Stored in a small Hive box instead of the Isar `Settings` collection so no
// Isar schema/codegen change (and no DB migration) is needed. Defaults and
// slider ranges mirror Nekoyomi's UiPreferences.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NekoUiPrefs {
  /// Floating "pill" bottom navigation (Nekoyomi default: on).
  final bool floatingNav;

  /// Floating bar background opacity, 0..100 (Nekoyomi default 81).
  final int navOpacity;

  /// Blur behind the floating bar, 0..30 (default 0 = off).
  final int navBlur;

  /// Bar height scale in percent, 70..130 (default 100).
  final int navHeight;

  /// Navigation icon size in percent, 60..140 (default 100).
  final int navIconScale;

  /// Show text labels under navigation icons (Nekoyomi default: hidden).
  final bool navShowLabels;

  /// Blurred cover backdrop behind the entry detail page.
  final bool backdropEnabled;

  /// Backdrop opacity 0..100 (default 20).
  final int backdropOpacity;

  /// Backdrop blur 0..30 (default 4).
  final int backdropBlur;

  /// Extra darkening of the backdrop 0..100 (default 0).
  final int backdropDim;

  /// Tint the detail page with colours taken from the cover (Anikku).
  final bool coverTheme;

  const NekoUiPrefs({
    this.floatingNav = true,
    this.navOpacity = 81,
    this.navBlur = 0,
    this.navHeight = 100,
    this.navIconScale = 100,
    this.navShowLabels = false,
    this.backdropEnabled = true,
    this.backdropOpacity = 20,
    this.backdropBlur = 4,
    this.backdropDim = 0,
    this.coverTheme = true,
  });

  NekoUiPrefs copyWith({
    bool? floatingNav,
    int? navOpacity,
    int? navBlur,
    int? navHeight,
    int? navIconScale,
    bool? navShowLabels,
    bool? backdropEnabled,
    int? backdropOpacity,
    int? backdropBlur,
    int? backdropDim,
    bool? coverTheme,
  }) {
    return NekoUiPrefs(
      floatingNav: floatingNav ?? this.floatingNav,
      navOpacity: navOpacity ?? this.navOpacity,
      navBlur: navBlur ?? this.navBlur,
      navHeight: navHeight ?? this.navHeight,
      navIconScale: navIconScale ?? this.navIconScale,
      navShowLabels: navShowLabels ?? this.navShowLabels,
      backdropEnabled: backdropEnabled ?? this.backdropEnabled,
      backdropOpacity: backdropOpacity ?? this.backdropOpacity,
      backdropBlur: backdropBlur ?? this.backdropBlur,
      backdropDim: backdropDim ?? this.backdropDim,
      coverTheme: coverTheme ?? this.coverTheme,
    );
  }

  Map<String, Object> toMap() => {
    'floatingNav': floatingNav,
    'navOpacity': navOpacity,
    'navBlur': navBlur,
    'navHeight': navHeight,
    'navIconScale': navIconScale,
    'navShowLabels': navShowLabels,
    'backdropEnabled': backdropEnabled,
    'backdropOpacity': backdropOpacity,
    'backdropBlur': backdropBlur,
    'backdropDim': backdropDim,
    'coverTheme': coverTheme,
  };

  factory NekoUiPrefs.fromMap(Map<dynamic, dynamic>? m) {
    const d = NekoUiPrefs();
    if (m == null) return d;
    bool b(String k, bool def) => m[k] is bool ? m[k] as bool : def;
    int i(String k, int def, int lo, int hi) =>
        m[k] is int ? (m[k] as int).clamp(lo, hi) : def;
    return NekoUiPrefs(
      floatingNav: b('floatingNav', d.floatingNav),
      navOpacity: i('navOpacity', d.navOpacity, 0, 100),
      navBlur: i('navBlur', d.navBlur, 0, 30),
      navHeight: i('navHeight', d.navHeight, 70, 130),
      navIconScale: i('navIconScale', d.navIconScale, 60, 140),
      navShowLabels: b('navShowLabels', d.navShowLabels),
      backdropEnabled: b('backdropEnabled', d.backdropEnabled),
      backdropOpacity: i('backdropOpacity', d.backdropOpacity, 0, 100),
      backdropBlur: i('backdropBlur', d.backdropBlur, 0, 30),
      backdropDim: i('backdropDim', d.backdropDim, 0, 100),
      coverTheme: b('coverTheme', d.coverTheme),
    );
  }
}

/// Owns the Hive box. [init] is called once from `main()`; if it fails the
/// app still runs with in-memory defaults.
class NekoUiPrefsStore {
  static const _boxName = 'yomihub_ui';
  static Box<dynamic>? _box;

  static Future<void> init() async {
    try {
      await Hive.initFlutter('yomihub');
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (_) {
      _box = null;
    }
  }

  static Map<dynamic, dynamic>? read() => _box?.toMap();

  static void write(NekoUiPrefs prefs) {
    final box = _box;
    if (box == null) return;
    box.putAll(prefs.toMap());
  }
}

class NekoUiPrefsNotifier extends Notifier<NekoUiPrefs> {
  @override
  NekoUiPrefs build() => NekoUiPrefs.fromMap(NekoUiPrefsStore.read());

  void edit(NekoUiPrefs Function(NekoUiPrefs current) change) {
    state = change(state);
    NekoUiPrefsStore.write(state);
  }

  void reset() {
    state = const NekoUiPrefs();
    NekoUiPrefsStore.write(state);
  }
}

final nekoUiPrefsProvider = NotifierProvider<NekoUiPrefsNotifier, NekoUiPrefs>(
  NekoUiPrefsNotifier.new,
);
