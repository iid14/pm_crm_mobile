// Экран «Статистика»: метрики, норма встреч, рекомендация.

import 'package:flutter/material.dart';

import '../db.dart';
import '../theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, Object?>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AppDb.instance.statsSummary();
    if (!mounted) return;
    setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
              tooltip: 'Обновить', icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _metricGrid(s),
                  const SizedBox(height: 14),
                  _normPanel(s),
                  const SizedBox(height: 14),
                  PanelBox(child: _convBlock(s)),
                ],
              ),
            ),
    );
  }

  Widget _metricGrid(Map<String, Object?> s) {
    final items = [
      ('Встреч сегодня', '${s['meetings_today']}',
          s['norm_done'] == true ? kOk : kAccent),
      ('Норма в день', '${s['goal']}', kFg),
      ('Всего встреч', '${s['meetings_total']}', kAccent),
      ('Подписок', '${s['subscribed_total']}', kOk),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        for (final (label, value, color) in items)
          _metricCard(label, value, color),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return PanelBox(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _normPanel(Map<String, Object?> s) {
    final today = (s['meetings_today'] as int?) ?? 0;
    final goal = (s['goal'] as int?) ?? 0;
    final done = (s['norm_done'] == true);
    final percent = goal <= 0 ? 0.0 : (today / goal * 100).clamp(0, 100);
    return PanelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Выполнение дневной нормы встреч',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 12,
              backgroundColor: kBorder,
              color: done ? kOk : kTerracotta,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done
                ? 'Норма выполнена: $today из $goal встреч — так держать!'
                : 'Норма НЕ выполнена: $today из $goal. Вперёд к звонкам!',
            style: TextStyle(
              color: done ? kOk : kBad,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _convBlock(Map<String, Object?> s) {
    final conv = (s['conversion_pct'] as num?)?.toDouble() ?? 0.0;
    final low = conv > 0 && conv < 50;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Конверсия и отказы',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Конверсия «встреча → подписка»: ${conv.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text('Отказов: ${s['rejected_total']}  •  '
            '«Подписан в глубь»: ${s['deep_signed_total']}',
            style: const TextStyle(color: kMuted)),
        const SizedBox(height: 12),
        Text(
          'Низкая конверсия? — обратись к спонсору',
          style: TextStyle(
            color: low ? kTerracotta : kAccent,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
