// Экран «Напоминания»: встречи, запланированные на сегодня.

import 'package:flutter/material.dart';

import '../db.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, Object?>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await AppDb.instance.meetingsOnDate(todayIso());
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = const [
      'понедельник', 'вторник', 'среда', 'четверг',
      'пятница', 'суббота', 'воскресенье',
    ][now.weekday - 1];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Напоминания'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text('${fmtDate(now.toIso8601String())}, $weekday',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Запланированные встречи на сегодня',
              style: TextStyle(color: kMuted)),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            const PanelBox(
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: kMuted),
                  SizedBox(height: 8),
                  Text('На сегодня встреч нет.\nОтличный день для новых звонков!',
                      textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
                ],
              ),
            )
          else
            for (final r in _items) _MeetingCard(data: r),
          const SizedBox(height: 8),
          const Text(
            'Совет: держите список открытым — после каждой встречи отмечайте '
            'результат во вкладке «Контакты».',
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Map<String, Object?> data;

  const _MeetingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '') as String;
    return PanelBox(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text((data['name'] ?? '') as String,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor(status), fontSize: 12)),
              ),
            ],
          ),
          if ((data['phone'] ?? '') is String && (data['phone'] as String).isNotEmpty)
            Text((data['phone'] ?? '') as String,
                style: const TextStyle(color: kMuted)),
          if ((data['agreement'] ?? '') is String &&
              (data['agreement'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Договорились: ${data['agreement']}'),
            ),
        ],
      ),
    );
  }
}
