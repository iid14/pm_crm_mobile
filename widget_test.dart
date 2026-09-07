// Базовые проверки без запуска платформенных каналов.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_crm_mobile/src/models.dart';
import 'package:pm_crm_mobile/src/theme.dart';
import 'package:pm_crm_mobile/src/utils.dart';

void main() {
  test('список статусов содержит «Подписан в глубь»', () {
    expect(Status.list, contains(Status.deepSigned));
    expect(Status.filters.length, Status.list.length + 1);
  });

  test('результаты касаний содержат «в глубь»', () {
    expect(TouchResult.list, contains(TouchResult.deepSigned));
  });

  test('строится тема приложения', () {
    final theme = buildTheme();
    expect(theme, isA<ThemeData>());
  });

  test('нормализация телефона', () {
    expect(normalizePhone('+7 912 345-67-89'), '+79123456789');
    expect(normalizePhone('8 (921) 111-22-33'), '89211112233');
  });

  test('разбор дат', () {
    expect(parseDate('2026-03-05'), isNotNull);
    expect(parseDate('05.03.2026'), isNotNull);
    expect(fmtDate('2026-03-05'), '05.03.2026');
  });
}
