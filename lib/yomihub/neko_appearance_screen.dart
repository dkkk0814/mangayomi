// YomiHub: settings screen for the Nekoyomi-style interface options.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/yomihub/neko_ui_prefs.dart';

class NekoAppearanceScreen extends ConsumerWidget {
  const NekoAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(nekoUiPrefsProvider);
    final n = ref.read(nekoUiPrefsProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao diện Nekoyomi'),
        actions: [
          IconButton(
            tooltip: 'Khôi phục mặc định',
            icon: const Icon(Icons.restart_alt),
            onPressed: n.reset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          header('Thanh điều hướng'),
          SwitchListTile(
            secondary: const Icon(Icons.space_bar_rounded),
            title: const Text('Thanh điều hướng nổi'),
            subtitle: const Text('Dạng viên thuốc bo tròn, trong suốt'),
            value: p.floatingNav,
            onChanged: (v) => n.edit((s) => s.copyWith(floatingNav: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.label_outline),
            title: const Text('Hiện nhãn dưới biểu tượng'),
            value: p.navShowLabels,
            onChanged: (v) => n.edit((s) => s.copyWith(navShowLabels: v)),
          ),
          if (p.floatingNav) ...[
            _PercentSlider(
              title: 'Độ đục nền thanh',
              value: p.navOpacity,
              min: 0,
              max: 100,
              onChanged: (v) => n.edit((s) => s.copyWith(navOpacity: v)),
            ),
            _PercentSlider(
              title: 'Làm mờ phía sau',
              value: p.navBlur,
              min: 0,
              max: 30,
              unit: ' dp',
              offLabelAtZero: true,
              onChanged: (v) => n.edit((s) => s.copyWith(navBlur: v)),
            ),
          ],
          _PercentSlider(
            title: 'Chiều cao thanh',
            value: p.navHeight,
            min: 70,
            max: 130,
            onChanged: (v) => n.edit((s) => s.copyWith(navHeight: v)),
          ),
          _PercentSlider(
            title: 'Cỡ biểu tượng',
            value: p.navIconScale,
            min: 60,
            max: 140,
            onChanged: (v) => n.edit((s) => s.copyWith(navIconScale: v)),
          ),
          header('Trang chi tiết'),
          SwitchListTile(
            secondary: const Icon(Icons.blur_on),
            title: const Text('Nền bìa mờ'),
            subtitle: const Text('Ảnh bìa làm mờ phía sau trang chi tiết'),
            value: p.backdropEnabled,
            onChanged: (v) => n.edit((s) => s.copyWith(backdropEnabled: v)),
          ),
          if (p.backdropEnabled) ...[
            _PercentSlider(
              title: 'Độ hiện của bìa',
              value: p.backdropOpacity,
              min: 0,
              max: 100,
              onChanged: (v) => n.edit((s) => s.copyWith(backdropOpacity: v)),
            ),
            _PercentSlider(
              title: 'Độ mờ',
              value: p.backdropBlur,
              min: 0,
              max: 30,
              unit: ' dp',
              offLabelAtZero: true,
              onChanged: (v) => n.edit((s) => s.copyWith(backdropBlur: v)),
            ),
            _PercentSlider(
              title: 'Làm tối',
              value: p.backdropDim,
              min: 0,
              max: 100,
              onChanged: (v) => n.edit((s) => s.copyWith(backdropDim: v)),
            ),
          ],
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: const Text('Màu theo ảnh bìa'),
            subtitle: const Text('Tự lấy màu nhấn từ bìa của từng truyện/phim'),
            value: p.coverTheme,
            onChanged: (v) => n.edit((s) => s.copyWith(coverTheme: v)),
          ),
        ],
      ),
    );
  }
}

class _PercentSlider extends StatefulWidget {
  final String title;
  final int value;
  final int min;
  final int max;
  final String unit;
  final bool offLabelAtZero;
  final ValueChanged<int> onChanged;

  const _PercentSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '%',
    this.offLabelAtZero = false,
  });

  @override
  State<_PercentSlider> createState() => _PercentSliderState();
}

class _PercentSliderState extends State<_PercentSlider> {
  late double _v = widget.value.toDouble();

  @override
  void didUpdateWidget(covariant _PercentSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _v = widget.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final r = _v.round();
    final label = widget.offLabelAtZero && r == 0 ? 'Tắt' : '$r${widget.unit}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Slider(
            value: _v.clamp(widget.min.toDouble(), widget.max.toDouble()),
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            onChanged: (v) => setState(() => _v = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}
