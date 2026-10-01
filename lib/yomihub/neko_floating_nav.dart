// YomiHub: Nekoyomi-style floating bottom navigation.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/neko_ui_prefs.dart';

/// Default Material 3 NavigationBar height, scaled by the user's height pref.
double nekoNavBarHeight(NekoUiPrefs p) => 80.0 * p.navHeight / 100.0;

/// Theme applied to the NavigationBar in both classic and floating styles:
/// icon size and label visibility follow the Nekoyomi preferences.
NavigationBarThemeData nekoNavBarTheme(
  BuildContext context,
  NekoUiPrefs p, {
  required bool floating,
}) {
  final scale = p.navIconScale / 100.0;
  return NavigationBarThemeData(
    height: nekoNavBarHeight(p),
    labelBehavior: p.navShowLabels
        ? NavigationDestinationLabelBehavior.alwaysShow
        : NavigationDestinationLabelBehavior.alwaysHide,
    labelTextStyle: const WidgetStatePropertyAll(
      TextStyle(overflow: TextOverflow.ellipsis),
    ),
    iconTheme: WidgetStatePropertyAll(IconThemeData(size: 24.0 * scale)),
    indicatorShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    backgroundColor: floating ? Colors.transparent : null,
    elevation: floating ? 0 : null,
    surfaceTintColor: floating ? Colors.transparent : null,
  );
}

/// Wraps a [NavigationBar] in a rounded, translucent, optionally blurred pill
/// that floats above the content, like Nekoyomi's floating navigation.
class NekoFloatingNav extends StatelessWidget {
  final NekoUiPrefs prefs;
  final Widget child;

  const NekoFloatingNav({super.key, required this.prefs, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final radius = BorderRadius.circular(nekoNavBarHeight(prefs) / 2);
    Widget pill = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(
          alpha: prefs.navOpacity / 100.0,
        ),
        borderRadius: radius,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      // The bar sits inside the pill, so it must not add its own
      // system-gesture padding at the bottom.
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
    if (prefs.navBlur > 0) {
      final sigma = prefs.navBlur.toDouble();
      pill = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: pill,
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: Material(
        type: MaterialType.transparency,
        elevation: 6,
        shadowColor: Colors.black54,
        borderRadius: radius,
        child: ClipRRect(borderRadius: radius, child: pill),
      ),
    );
  }
}
