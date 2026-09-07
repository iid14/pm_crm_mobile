// Слой данных: SQLite (sqflite). Зеркалирует схему и правила десктопной
// версии: таблицы contacts / touches / settings, автообновление статусов.

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';
import 'utils.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'pm_crm.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT DEFAULT '',
        tg_phone TEXT DEFAULT '',
        vk TEXT DEFAULT '',
        instagram TEXT DEFAULT '',
        max TEXT DEFAULT '',
        status TEXT NOT NULL DEFAULT 'Новый',
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE touches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
        touch_type TEXT NOT NULL,
        result TEXT DEFAULT '',
        next_meeting TEXT,
        agreement TEXT DEFAULT '',
        comment TEXT DEFAULT '',
        date TEXT NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_touches_contact ON touches(contact_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_touches_date ON touches(next_meeting)');
    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  }

  // ------------------------------------------------------------- контакты
  Future<List<Contact>> listContacts({
    String statusFilter = Status.all,
    String search = '',
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    if (statusFilter != Status.all) {
      where.add('status = ?');
      args.add(statusFilter);
    }
    final q = search.trim();
    if (q.isNotEmpty) {
      where.add('(name LIKE ? OR phone LIKE ? OR tg_phone LIKE ?)');
      final like = '%$q%';
      args.addAll([like, like, like]);
    }
    final sql = '''
      SELECT c.*,
        (SELECT COUNT(*) FROM touches t WHERE t.contact_id = c.id) AS touches_count,
        (SELECT MAX(t.next_meeting) FROM touches t
           WHERE t.contact_id = c.id AND t.next_meeting IS NOT NULL
             AND t.next_meeting <> '') AS next_meeting
      FROM contacts c
      ${where.isEmpty ? '' : 'WHERE ' + where.join(' AND ')}
      ORDER BY c.created_at DESC, c.id DESC''';
    final rows = await db.rawQuery(sql, args);
    return rows.map((r) {
      final c = Contact.fromMap(r);
      return c;
    }).toList();
  }

  Future<Contact?> getContact(int id) async {
    final db = await database;
    final rows = await db.query('contacts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Contact.fromMap(rows.first);
  }

  Future<int> addContact(Contact c) async {
    final db = await database;
    return db.insert('contacts', c.toMap()..remove('id'));
  }

  Future<void> updateContact(Contact c) async {
    final db = await database;
    final map = c.toMap()..remove('id');
    await db.update('contacts', map, where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteContact(int id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // -------------------------------------------------------------- касания
  static String computeNextStatus({
    required String current,
    required String touchType,
    required String result,
    String? nextMeeting,
  }) {
    switch (result) {
      case TouchResult.signed:
        return Status.signed;
      case TouchResult.deepSigned:
        return Status.deepSigned;
      case TouchResult.notSigned:
        return Status.rejected;
      case TouchResult.postponed:
        if (nextMeeting != null && nextMeeting.isNotEmpty) {
          return Status.meeting;
        }
        return current;
      default:
        break;
    }
    final next = (nextMeeting ?? '').trim();
    if (next.isNotEmpty) return Status.meeting;
    if (touchType == 'Созвон' && current == Status.newContact) {
      return Status.call;
    }
    if (touchType == 'Встреча' &&
        (current == Status.newContact || current == Status.call)) {
      return Status.meeting;
    }
    return current;
  }

  Future<int> addTouch(Touch t) async {
    final db = await database;
    final id = await db.insert('touches', t.toMap()..remove('id'));
    final contact = await getContact(t.contactId);
    if (contact != null) {
      final newStatus = computeNextStatus(
        current: contact.status,
        touchType: t.touchType,
        result: t.result,
        nextMeeting: t.nextMeeting,
      );
      if (newStatus != contact.status) {
        await db.update('contacts', {'status': newStatus},
            where: 'id = ?', whereArgs: [t.contactId]);
      }
    }
    return id;
  }

  Future<List<Touch>> listTouches(int contactId) async {
    final db = await database;
    final rows = await db.query('touches',
        where: 'contact_id = ?',
        whereArgs: [contactId],
        orderBy: 'date DESC, id DESC');
    return rows.map(Touch.fromMap).toList();
  }

  Future<void> deleteTouch(int id) async {
    final db = await database;
    await db.delete('touches', where: 'id = ?', whereArgs: [id]);
  }

  /// Контакты с запланированной встречей на дату.
  Future<List<Map<String, Object?>>> meetingsOnDate(String isoDate) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.id AS contact_id, c.name, c.phone, c.status,
             t.id AS touch_id, t.next_meeting, t.result, t.agreement
      FROM touches t JOIN contacts c ON c.id = t.contact_id
      WHERE t.next_meeting = ? AND (t.result IS NULL OR t.result = ''
             OR t.result = 'Перенесено')
      ORDER BY c.name''', [isoDate]);
    return rows;
  }

  // ------------------------------------------------------------ настройки
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings',
        columns: ['value'], where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> getDailyGoal() async {
    final v = await getSetting('daily_goal_meetings');
    return int.tryParse(v ?? '') ?? 3;
  }

  /// Простое JSON-хранилище списков (возражения, ссылки).
  Future<List<Map<String, String>>> getJsonList(String key,
      List<Map<String, String>> defaults) async {
    final raw = await getSetting(key);
    if (raw == null || raw.trim().isEmpty) return defaults;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list
          .map((e) => {
                for (final k in e.keys) k: (e[k] ?? '').toString(),
              })
          .toList();
    } catch (_) {
      return defaults;
    }
  }

  Future<void> setJsonList(String key, List<Map<String, String>> list) async {
    await setSetting(key, jsonEncode(list));
  }

  // ------------------------------------------------------------ статистика
  Future<Map<String, Object?>> statsSummary() async {
    final db = await database;
    final today = todayIso();
    final counts = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN touch_type='Встреча' AND date LIKE ? THEN 1 ELSE 0 END) AS today_meetings,
        SUM(CASE WHEN touch_type='Встреча' THEN 1 ELSE 0 END) AS total_meetings
      FROM touches''', ['$today%']);
    final subscribed = await db
        .rawQuery("SELECT COUNT(*) c FROM contacts WHERE status='Подписан'");
    final deep = await db.rawQuery(
        "SELECT COUNT(*) c FROM contacts WHERE status='Подписан в глубь'");
    final rejected = await db
        .rawQuery("SELECT COUNT(*) c FROM contacts WHERE status='Отказ'");
    final todayMeetings = counts.first['today_meetings'] as int? ?? 0;
    final totalMeetings = counts.first['total_meetings'] as int? ?? 0;
    final signed = subscribed.first['c'] as int? ?? 0;
    final goal = await getDailyGoal();
    return {
      'meetings_today': todayMeetings,
      'meetings_total': totalMeetings,
      'subscribed_total': signed,
      'deep_signed_total': deep.first['c'] as int? ?? 0,
      'rejected_total': rejected.first['c'] as int? ?? 0,
      'goal': goal,
      'norm_done': todayMeetings >= goal,
      'conversion_pct': totalMeetings == 0
          ? 0.0
          : double.parse((signed * 100 / totalMeetings).toStringAsFixed(1)),
    };
  }
}
