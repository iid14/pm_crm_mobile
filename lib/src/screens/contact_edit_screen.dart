// Экран добавления/редактирования контакта.

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../utils.dart';

class ContactEditScreen extends StatefulWidget {
  final Contact? contact;

  const ContactEditScreen({super.key, this.contact});

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _tg;
  late final TextEditingController _vk;
  late final TextEditingController _instagram;
  late final TextEditingController _max;
  late String _status;

  bool get _isEdit => widget.contact != null;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _tg = TextEditingController(text: c?.tgPhone ?? '');
    _vk = TextEditingController(text: c?.vk ?? '');
    _instagram = TextEditingController(text: c?.instagram ?? '');
    _max = TextEditingController(text: c?.max ?? '');
    _status = c?.status ?? Status.newContact;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _tg.dispose();
    _vk.dispose();
    _instagram.dispose();
    _max.dispose();
    super.dispose();
  }

  Contact _collect() => Contact(
        id: widget.contact?.id,
        name: _name.text.trim(),
        phone: normalizePhone(_phone.text),
        tgPhone: _tg.text.trim(),
        vk: _vk.text.trim(),
        instagram: _instagram.text.trim(),
        max: _max.text.trim(),
        status: _status,
        createdAt: widget.contact?.createdAt ?? nowStamp(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Изменить контакт' : 'Новый контакт')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            PanelBox(
              child: Column(
                children: [
                  _field(_name, 'Имя *', Icons.person_outline),
                  const SizedBox(height: 10),
                  _field(_phone, 'Телефон', Icons.phone_outlined),
                  const SizedBox(height: 10),
                  _field(_tg, 'Telegram (тел.)', Icons.send_outlined),
                  const SizedBox(height: 10),
                  _field(_vk, 'VK', Icons.public),
                  const SizedBox(height: 10),
                  _field(_instagram, 'Instagram', Icons.camera_alt_outlined),
                  const SizedBox(height: 10),
                  _field(_max, 'Max (мессенджер)', Icons.chat_outlined),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PanelBox(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Статус'),
                items: Status.list
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? 'Сохранить изменения' : 'Добавить контакт',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: c == _name
          ? (v) => (v == null || v.trim().isEmpty) ? 'Укажите имя' : null
          : null,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_collect());
  }
}
