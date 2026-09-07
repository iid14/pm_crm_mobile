// Вспомогательные функции: даты, телефоны, буфер обмена.

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

String _two(int v) => v.toString().padLeft(2, '0');

String todayIso() {
  final n = DateTime.now();
  return '${n.year}-${_two(n.month)}-${_two(n.day)}';
}

String nowStamp() {
  final n = DateTime.now();
  return '${n.year}-${_two(n.month)}-${_two(n.day)} '
      '${_two(n.hour)}:${_two(n.minute)}:${_two(n.second)}';
}

/// Разбор даты: ГГГГ-ММ-ДД и ДД.ММ.ГГГГ.
DateTime? parseDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
  if (m != null) {
    return DateTime.tryParse('${m.group(1)}-${m.group(2)}-${m.group(3)}');
  }
  final d = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(s);
  if (d != null) {
    return DateTime.tryParse('${d.group(3)}-${d.group(2)}-${d.group(1)}');
  }
  return null;
}

/// Отображение даты: ДД.ММ.ГГГГ.
String fmtDate(String? raw) {
  final dt = parseDate(raw);
  if (dt == null) return raw ?? '';
  return '${_two(dt.day)}.${_two(dt.month)}.${dt.year}';
}

String fmtStamp(String raw) {
  final dt = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (dt == null) return raw;
  return '${_two(dt.day)}.${_two(dt.month)}.${dt.year} '
      '${_two(dt.hour)}:${_two(dt.minute)}';
}

/// Нормализация телефона: '+7 999 123-45-67' -> '+79991234567'.
String normalizePhone(String raw) {
  final s = raw.trim();
  if (s.startsWith('+')) {
    return '+${s.replaceAll(RegExp(r'[^\d]'), '')}';
  }
  return s.replaceAll(RegExp(r'[^\d]'), '');
}

/// Копирование текста в буфер обмена.
Future<void> copyToClipboard(BuildContext context, String text) async {
  if (text.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    final short = text.length > 60 ? '${text.substring(0, 60)}…' : text;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Скопировано: $short'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
