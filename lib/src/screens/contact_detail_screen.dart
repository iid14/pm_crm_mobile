// Экран контакта: карточка, добавление касания, история (воронка).

import 'package:flutter/material.dart';

import '../db.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'contact_edit_screen.dart';

class ContactDetailScreen extends StatefulWidget {
  final int contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  Contact? _contact;
  List<Touch> _touches = [];
  bool _loading = true;

  // форма нового касания
  String _type = 'Созвон';
  String _result = '';
  DateTime? _nextDate;

  // контроллеры текста
  final _agreementCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _agreementCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final contact = await AppDb.instance.getContact(widget.contactId);
    final touches =
        contact == null ? <Touch>[] : await AppDb.instance.listTouches(contact.id!);
    if (!mounted) return;
    setState(() {
      _contact = contact;
      _touches = touches;
      _loading = false;
    });
  }

  Future<void> _editContact() async {
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (_) => ContactEditScreen(contact: _contact),
      ),
    );
    if (contact != null) {
      await AppDb.instance.updateContact(contact);
      await _load();
    }
  }

  Future<void> _deleteContact() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить контакт?'),
        content: const Text(
            'Контакт будет удалён вместе со всей историей касаний. '
            'Действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBad),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AppDb.instance.deleteContact(widget.contactId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _saveTouch() async {
    final next = _nextDate == null
        ? null
        : '${_nextDate!.year}-${_nextDate!.month.toString().padLeft(2, '0')}-'
            '${_nextDate!.day.toString().padLeft(2, '0')}';
    await AppDb.instance.addTouch(Touch(
      contactId: widget.contactId,
      touchType: _type,
      result: _result,
      nextMeeting: next,
      agreement: _agreementCtrl.text.trim(),
      comment: _commentCtrl.text.trim(),
      date: nowStamp(),
    ));
    _agreementCtrl.clear();
    _commentCtrl.clear();
    _result = '';
    _nextDate = null;
    setState(() {});
    await _load();
  }

  Future<void> _deleteTouch(Touch t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить касание?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBad),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AppDb.instance.deleteTouch(t.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contact;
    return Scaffold(
      appBar: AppBar(
        title: Text(contact?.name ?? 'Контакт'),
        actions: [
          IconButton(
            tooltip: 'Изменить',
            icon: const Icon(Icons.edit_outlined),
            onPressed: contact == null ? null : _editContact,
          ),
          IconButton(
            tooltip: 'Удалить',
            icon: const Icon(Icons.delete_outline),
            onPressed: contact == null ? null : _deleteContact,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : contact == null
              ? const Center(child: Text('Контакт не найден'))
              : _buildBody(contact),
    );
  }

  Widget _buildBody(Contact contact) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // карточка контакта
        PanelBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor(contact.status).withOpacity(0.2),
                    child: Text(
                      contact.name.isEmpty ? '?' : contact.name[0].toUpperCase(),
                      style: TextStyle(
                          color: statusColor(contact.status),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                          [
                            if (contact.phone.isNotEmpty) contact.phone,
                            if (contact.tgPhone.isNotEmpty) 'TG: ${contact.tgPhone}',
                          ].join('\n'),
                          style: const TextStyle(color: kMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor(contact.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(contact.status,
                        style: TextStyle(
                            color: statusColor(contact.status),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Создан: ${fmtDate(contact.createdAt.split(' ').first)}',
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // новое касание
        PanelBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Новое касание',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Созвон', label: Text('Созвон')),
                  ButtonSegment(value: 'Встреча', label: Text('Встреча')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _result,
                decoration: const InputDecoration(
                    labelText: 'Результат (необязательно)', isDense: true),
                items: [
                  const DropdownMenuItem(value: '', child: Text('— результат —')),
                  for (final r in TouchResult.list)
                    if (r.isNotEmpty)
                      DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setState(() => _result = v ?? ''),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined, size: 20),
                label: Text(_nextDate == null
                    ? 'Дата следующей встречи'
                    : 'След. встреча: ${fmtDate(_nextDate!.toIso8601String())}'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _agreementCtrl,
                decoration: const InputDecoration(
                    labelText: 'О чём договорились', isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Комментарий'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kAccent),
                  onPressed: _saveTouch,
                  icon: const Icon(Icons.add),
                  label: const Text('Сохранить касание'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // история
        Text('История касаний (${_touches.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        if (_touches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Пока нет касаний — добавьте первое выше.',
                style: TextStyle(color: kMuted)),
          )
        else
          for (final t in _touches) _TouchTile(touch: t, onDelete: () => _deleteTouch(t)),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }
}

class _TouchTile extends StatelessWidget {
  final Touch touch;
  final VoidCallback onDelete;

  const _TouchTile({required this.touch, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ok = touch.result == TouchResult.signed ||
        touch.result == TouchResult.deepSigned;
    final bad = touch.result == TouchResult.notSigned;
    final resultColor = ok ? kOk : (bad ? kBad : kMuted);

    return PanelBox(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${touch.touchType}  •  ${fmtStamp(touch.date)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20, color: kMuted),
                onPressed: onDelete,
              ),
            ],
          ),
          if (touch.result.isNotEmpty)
            Text('Результат: ${touch.result}',
                style: TextStyle(color: resultColor, fontWeight: FontWeight.w600)),
          if (touch.nextMeeting != null && touch.nextMeeting!.isNotEmpty)
            Text('След. встреча: ${fmtDate(touch.nextMeeting)}'),
          if (touch.agreement.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Договорились: ${touch.agreement}'),
            ),
          if (touch.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(touch.comment, style: const TextStyle(color: kMuted)),
            ),
        ],
      ),
    );
  }
}
