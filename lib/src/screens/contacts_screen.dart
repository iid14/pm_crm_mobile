// Экран «Контакты»: список, поиск, фильтр по статусу, импорт CSV, FAB.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../csv_import.dart';
import '../db.dart';
import '../models.dart';
import '../theme.dart';
import 'contact_detail_screen.dart';
import 'contact_edit_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _items = [];
  bool _loading = true;
  String _query = '';
  String _filter = Status.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await AppDb.instance
        .listContacts(statusFilter: _filter, search: _query);
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  // ------------------------------------------------------------------ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
        actions: [
          IconButton(
            tooltip: 'Импорт CSV из Telegram',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: _importCsv,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        onPressed: _openCreate,
        icon: const Icon(Icons.person_add),
        label: const Text('Добавить'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск по имени или телефону…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) {
                _query = v.trim();
                _load();
              },
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: Status.filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final s = Status.filters[i];
                return ChoiceChip(
                  label: Text(s),
                  selected: _filter == s,
                  onSelected: (_) {
                    _filter = s;
                    _load();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Icon(Icons.people_outline,
                                  size: 64, color: kMuted),
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Контактов пока нет.\n\nДобавьте вручную кнопкой '
                                  '«Добавить» или импортируйте список из Telegram '
                                  '(иконка ⬆ вверху справа).',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: kMuted),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _items.length,
                            itemBuilder: (context, i) {
                              final c = _items[i];
                              return _ContactTile(
                                contact: c,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ContactDetailScreen(contactId: c.id!),
                                    ),
                                  );
                                  _load();
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- создание
  Future<void> _openCreate() async {
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(builder: (_) => const ContactEditScreen()),
    );
    if (contact != null) {
      await AppDb.instance.addContact(contact);
      _load();
    }
  }

  // ------------------------------------------------------------- импорт CSV
  Future<void> _importCsv() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть выбор файла: $e')),
        );
      }
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes ?? Uint8List(0);
    if (bytes.isEmpty) {
      _snack('Не удалось прочитать файл.');
      return;
    }
    final text = decodeCsv(bytes);
    final ParsedCsv parsed;
    try {
      parsed = parseCsv(text);
    } catch (_) {
      _snack('Ошибка разбора CSV.');
      return;
    }
    final mapping = autoMap(parsed.headers);
    if (mapping['name'] == null) {
      _snack('В файле не найдена колонка с именем контакта.');
      return;
    }
    final contacts = buildContacts(parsed.rows, mapping);

    // пропуск дубликатов (имя или нормализованный телефон)
    var added = 0;
    var dup = 0;
    for (final c in contacts) {
      final exists = await _exists(c);
      if (exists) {
        dup++;
      } else {
        await AppDb.instance.addContact(c);
        added++;
      }
    }
    _load();
    _snack('Импорт завершён: добавлено $added, дубликатов пропущено $dup.');
  }

  Future<bool> _exists(Contact c) async {
    final rows = await AppDb.instance
        .listContacts(search: c.phone.isNotEmpty ? c.phone : c.name);
    for (final r in rows) {
      if (c.phone.isNotEmpty && r.phone == c.phone) return true;
      if (r.name.toLowerCase() == c.name.toLowerCase()) return true;
    }
    return false;
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const _ContactTile({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: statusColor(contact.status).withOpacity(0.2),
        child: Text(
          contact.name.isEmpty ? '?' : contact.name[0].toUpperCase(),
          style: TextStyle(
              color: statusColor(contact.status),
              fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(contact.name),
      subtitle: Text(
        [contact.phone, contact.tgPhone]
            .where((s) => s.isNotEmpty)
            .join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor(contact.status).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          contact.status,
          style: TextStyle(
              color: statusColor(contact.status),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
