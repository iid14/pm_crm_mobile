// Экран «Помощь»: реферальная ссылка, возражения, важные ссылки.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db.dart';
import '../theme.dart';
import '../utils.dart';

const List<Map<String, String>> kDefaultObjections = [
  {
    'question': '«Мне это не интересно / я не хочу заниматься сетевым»',
    'answer': 'Никто не заставляет. Предложите познакомиться с продуктом как '
        'клиенту: это ни к чему не обязывает. Решение останется за человеком.',
  },
  {
    'question': '«У меня нет времени»',
    'answer': 'Достаточно 3–5 часов в неделю. Начните с одной пробной встречи '
        'и посмотрите, как это устроено.',
  },
  {
    'question': '«Дорого»',
    'answer': 'Продукт можно брать по розничной цене или с дисконтом партнёра. '
        'Есть стартовые наборы под разный бюджет.',
  },
  {
    'question': '«У меня нет опыта продаж»',
    'answer': 'Специальный опыт не нужен: есть система, обучение и поддержка '
        'спонсора. Первые шаги — вместе с наставником.',
  },
  {
    'question': '«Уже пробовал МЛМ — не получилось»',
    'answer': 'Часто причина не в человеке, а в системе и поддержке. '
        'Сравните подход: обучение и сопровождение новых партнёров.',
  },
  {
    'question': '«Надо посоветоваться с семьёй»',
    'answer': 'Отличная идея! Договоритесь о встрече вдвоём, возьмите '
        'материалы — решение примете вместе.',
  },
];

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _refCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _newQCtrl = TextEditingController();
  final _linkTitleCtrl = TextEditingController();
  final _linkUrlCtrl = TextEditingController();

  List<Map<String, String>> _objections = [];
  List<Map<String, String>> _links = [];
  String _selectedQ = '';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _answerCtrl.dispose();
    _newQCtrl.dispose();
    _linkTitleCtrl.dispose();
    _linkUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ref = await AppDb.instance.getSetting('referral_link');
    var objections =
        await AppDb.instance.getJsonList('objections', kDefaultObjections);
    if (objections.isEmpty) {
      objections = kDefaultObjections;
      await AppDb.instance.setJsonList('objections', objections);
    }
    final links = await AppDb.instance.getJsonList('important_links', const []);
    if (!mounted) return;
    setState(() {
      _refCtrl.text = ref ?? '';
      _objections = objections;
      _links = links;
      _selectedQ = objections.isNotEmpty ? objections.first['question']! : '';
      _ready = true;
    });
    _showAnswer();
  }

  Map<String, String>? get _selectedObj {
    for (final o in _objections) {
      if (o['question'] == _selectedQ) return o;
    }
    return null;
  }

  void _showAnswer() {
    final o = _selectedObj;
    _answerCtrl.text = o?['answer'] ?? '';
  }

  void _snack(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  // ------------------------------------------------------------- referral
  Future<void> _saveRef() async {
    await AppDb.instance.setSetting('referral_link', _refCtrl.text.trim());
    _snack('Реферальная ссылка сохранена.');
  }

  Future<void> _openRef() => _openUrl(_refCtrl.text.trim());

  Future<void> _openUrl(String raw) async {
    var url = raw.trim();
    if (url.isEmpty) {
      _snack('Сначала введите ссылку.');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _snack('Не удалось открыть ссылку.');
    } catch (_) {
      _snack('Не удалось открыть ссылку.');
    }
  }

  // ---------------------------------------------------------- objections
  Future<void> _saveAnswer() async {
    final o = _selectedObj;
    if (o == null) return;
    o['answer'] = _answerCtrl.text.trim();
    await AppDb.instance.setJsonList('objections', _objections);
    _snack('Отработка сохранена.');
  }

  Future<void> _addObjection() async {
    final q = _newQCtrl.text.trim();
    if (q.isEmpty) {
      _snack('Введите текст нового возражения.');
      return;
    }
    _objections.add({'question': q, 'answer': _answerCtrl.text.trim()});
    await AppDb.instance.setJsonList('objections', _objections);
    _newQCtrl.clear();
    setState(() => _selectedQ = q);
    _snack('Возражение добавлено.');
  }

  Future<void> _deleteObjection() async {
    final o = _selectedObj;
    if (o == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить возражение?'),
        content: Text(o['question']!),
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
      _objections.removeWhere((x) => x['question'] == o['question']);
      await AppDb.instance.setJsonList('objections', _objections);
      setState(() {
        _selectedQ = _objections.isEmpty
            ? ''
            : _objections.first['question']!;
      });
      _showAnswer();
      _snack('Возражение удалено.');
    }
  }

  // -------------------------------------------------------------- links
  Future<void> _addLink() async {
    final title = _linkTitleCtrl.text.trim();
    final url = _linkUrlCtrl.text.trim();
    if (url.isEmpty) {
      _snack('Введите ссылку (обязательно).');
      return;
    }
    _links.add({'title': title.isEmpty ? url : title, 'url': url});
    await AppDb.instance.setJsonList('important_links', _links);
    _linkTitleCtrl.clear();
    _linkUrlCtrl.clear();
    setState(() {});
    _snack('Ссылка добавлена.');
  }

  Future<void> _deleteLink(Map<String, String> link) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить ссылку?'),
        content: Text(link['title']!),
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
      _links.removeWhere((x) => x['url'] == link['url']);
      await AppDb.instance.setJsonList('important_links', _links);
      setState(() {});
    }
  }

  // ------------------------------------------------------------------ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Помощь')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _referralCard(),
                const SizedBox(height: 12),
                _objectionsCard(),
                const SizedBox(height: 12),
                _linksCard(),
              ],
            ),
    );
  }

  Widget _referralCard() {
    return PanelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ваша реферальная ссылка',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _refCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://…',
              prefixIcon: Icon(Icons.link),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveRef,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Сохранить'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kAccent),
                  onPressed: () =>
                      copyToClipboard(context, _refCtrl.text.trim()),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Копировать'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openRef,
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('Открыть'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _objectionsCard() {
    return PanelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Основные возражения и их отработка',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_objections.isEmpty)
            const Text('Список пуст. Добавьте первое возражение ниже.',
                style: TextStyle(color: kMuted))
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedQ,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Возражение'),
              items: [
                for (final o in _objections)
                  DropdownMenuItem(
                    value: o['question']!,
                    child: Text(o['question']!,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedQ = v);
                _showAnswer();
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _answerCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Варианты отработки (можно редактировать)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () =>
                      copyToClipboard(context, _answerCtrl.text.trim()),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Копировать ответ'),
                ),
                OutlinedButton.icon(
                  onPressed: _saveAnswer,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Сохранить правку'),
                ),
                OutlinedButton.icon(
                  onPressed: _addObjection,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Добавить'),
                ),
                OutlinedButton.icon(
                  onPressed: _deleteObjection,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: kBad,
                      side: const BorderSide(color: kBad)),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Удалить'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newQCtrl,
              decoration: const InputDecoration(
                labelText: 'Новое возражение (текст для «Добавить»)',
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linksCard() {
    return PanelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Важные ссылки',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _linkTitleCtrl,
            decoration: const InputDecoration(
                labelText: 'Описание', isDense: true),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _linkUrlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
                labelText: 'Ссылка', isDense: true),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kAccent),
              onPressed: _addLink,
              icon: const Icon(Icons.add_link, size: 18),
              label: const Text('Добавить ссылку'),
            ),
          ),
          const SizedBox(height: 10),
          if (_links.isEmpty)
            const Text('Ссылок пока нет — добавьте первую выше.',
                style: TextStyle(color: kMuted))
          else
            for (final link in _links)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(link['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          InkWell(
                            onTap: () => _openUrl(link['url'] ?? ''),
                            child: Text(link['url'] ?? '',
                                style: TextStyle(
                                    color: kAccent,
                                    decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Копировать',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () =>
                          copyToClipboard(context, link['url'] ?? ''),
                    ),
                    IconButton(
                      tooltip: 'Открыть',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.open_in_browser, size: 20),
                      onPressed: () => _openUrl(link['url'] ?? ''),
                    ),
                    IconButton(
                      tooltip: 'Удалить',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: kBad),
                      onPressed: () => _deleteLink(link),
                    ),
                  ],
                ),
              ),
          const Text('Нажмите на ссылку — она откроется в браузере.',
              style: TextStyle(color: kMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
