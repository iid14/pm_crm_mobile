// Импорт контактов из CSV, выгруженного Telegram Desktop.
// Поддерживает UTF-8 (обычно) и CP1251, автоподбор колонок.

import 'dart:convert';
import 'dart:typed_data';

import 'models.dart';
import 'utils.dart';

/// Декодирование текста CSV: UTF-8, UTF-16LE с BOM, затем CP1251 как latin1.
String decodeCsv(Uint8List bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    final units = <int>[];
    for (var i = 2; i + 1 < bytes.length; i += 2) {
      units.add(bytes[i] | (bytes[i + 1] << 8));
    }
    return String.fromCharCodes(units);
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

/// Результат разбора: заголовки и строки данных.
class ParsedCsv {
  final List<String> headers;
  final List<Map<String, String>> rows;
  ParsedCsv(this.headers, this.rows);
}

/// Разбор CSV (разделитель , ; или таб; поддержка кавычек).
ParsedCsv parseCsv(String text) {
  text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  // выбор разделителя: больше всего вхождений вне кавычек в первых строках
  final delim = _detectDelimiter(text);

  // строки -> списки полей
  final table = <List<String>>[];
  final row = <String>[];
  final buf = StringBuffer();
  var inQuotes = false;

  void flushField() {
    row.add(buf.toString());
    buf.clear();
  }

  void flushRow() {
    flushField();
    table.add(row.toList());
    row.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '"') {
      if (inQuotes && i + 1 < text.length && text[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch == delim && !inQuotes) {
      flushField();
    } else if (ch == '\n' && !inQuotes) {
      flushRow();
    } else {
      buf.write(ch);
    }
  }
  if (buf.isNotEmpty || row.isNotEmpty) flushRow();

  // отбрасываем полностью пустые строки
  final nonEmpty = table
      .where((r) => r.any((f) => f.trim().isNotEmpty))
      .toList();
  if (nonEmpty.isEmpty) return ParsedCsv([], []);
  final headers = nonEmpty.first.map((h) => h.trim()).toList();

  final rows = <Map<String, String>>[];
  for (var i = 1; i < nonEmpty.length; i++) {
    final map = <String, String>{};
    for (var j = 0; j < headers.length; j++) {
      map[headers[j]] =
          (j < nonEmpty[i].length ? nonEmpty[i][j] : '').trim();
    }
    rows.add(map);
  }
  return ParsedCsv(headers, rows);
}

String _detectDelimiter(String text) {
  const candidates = [',', ';', '\t'];
  var inQ = false;
  final counts = {for (final c in candidates) c: 0};
  final sample = text.length > 4000 ? text.substring(0, 4000) : text;
  for (final ch in sample.split('')) {
    if (ch == '"') {
      inQ = !inQ;
    } else if (!inQ && counts.containsKey(ch)) {
      counts[ch] = counts[ch]! + 1;
    }
  }
  var best = ',';
  var bestN = -1;
  counts.forEach((k, v) {
    if (v > bestN) {
      bestN = v;
      best = k;
    }
  });
  return best;
}

// ------------------------------------------------------------------ поля

String? _findColumn(List<String> headers, List<String> tokens) {
  final lower = headers.map((h) => h.toLowerCase().trim()).toList();
  for (final token in tokens) {
    for (var i = 0; i < lower.length; i++) {
      if (lower[i] == token || lower[i].contains(token)) {
        return headers[i];
      }
    }
  }
  return null;
}

/// Автоматическое сопоставление колонок (telegram: result.csv).
/// Возвращает null-значения для не найденных полей.
Map<String, String?> autoMap(List<String> headers) {
  const nameFull = ['name', 'full name', 'полное имя', 'фио', 'fio',
      'имя контакта', 'contact', 'имя и фамилия'];
  String? name;
  for (final h in headers) {
    if (nameFull.contains(h.toLowerCase().trim())) {
      name = h;
      break;
    }
  }
  final first = _findColumn(headers,
      const ['first name', 'first_name', 'firstname', 'имя']);
  final last = _findColumn(headers,
      const ['last name', 'last_name', 'lastname', 'фамилия']);
  name ??= (first != null && last != null)
      ? 'first+last'
      : (first ?? last);
  final phone = _findColumn(headers, const [
    'phone number', 'phone', 'telephone', 'тел.', 'телефон', 'номер телефона',
    'phone number (mobile)', 'mobile',
  ]);
  return {'name': name, 'phone': phone};
}

/// Построение списка контактов из строк CSV.
/// [tgHeader] — колонка номера в Telegram (по умолчанию как телефон).
List<Contact> buildContacts(
  List<Map<String, String>> rows,
  Map<String, String?> mapping, {
  String? tgHeader,
}) {
  final out = <Contact>[];
  for (final row in rows) {
    final name = _extractName(row, mapping['name']);
    if (name.isEmpty) continue;
    final phone = normalizePhone(_extract(row, mapping['phone']));
    final tg = _extract(row, tgHeader ?? mapping['phone']);
    out.add(Contact(
      name: name,
      phone: phone,
      tgPhone: tg.isNotEmpty ? normalizePhone(tg) : phone,
      createdAt: nowStamp(),
    ));
  }
  return out;
}

String _extract(Map<String, String> row, String? col) {
  if (col == null || col.isEmpty || col == 'first+last') return '';
  return row[col] ?? '';
}

String _extractName(Map<String, String> row, String? col) {
  if (col == null) return '';
  if (col == 'first+last') {
    String val(String prefix, List<String> tokens) {
      final sb = StringBuffer();
      row.forEach((k, v) {
        final kl = k.toLowerCase().trim();
        if (tokens.contains(kl)) {
          if (sb.isNotEmpty) sb.write(' ');
          sb.write(v);
        }
      });
      return sb.toString().trim();
    }

    final f = val('', const ['first name', 'first_name', 'имя']);
    final l = val('', const ['last name', 'last_name', 'фамилия', 'surname']);
    return '$f $l'.trim();
  }
  return (row[col] ?? '').trim();
}
