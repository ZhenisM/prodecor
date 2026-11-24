import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Поддержка: менеджеры и письмо в поддержку платформы
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String topic = 'Заявка или заказ';
  final text = TextEditingController();

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = text.text.trim();
    if (t.isEmpty) {
      toast(context, 'Опишите вопрос');
      return;
    }
    final ok = await run(context, () async {
      await context.read<Store>().support(topic, t);
      return true;
    });
    if (ok == true && mounted) {
      text.clear();
      toast(context, 'Обращение отправлено — ответим в ближайшее время');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    return Scaffold(
      appBar: AppBar(title: Text(tr(s.lang, 'support'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Вопросы по заявкам решает ваш менеджер, по работе платформы — поддержка.', style: TextStyle(color: c.muted)),
          const SizedBox(height: 12),
          const ManagersBox(),
          Box(
            title: 'Написать в поддержку',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dropdown('Тема', topic, const [
                  'Заявка или заказ',
                  'Каталог и цены',
                  'Работа кабинета',
                  'Другое',
                ], (v) => setState(() => topic = v)),
                field(text, 'Сообщение', hint: 'Опишите вопрос', lines: 5),
                FilledButton.icon(onPressed: _send, icon: const Icon(Icons.send), label: const Text('Отправить')),
                const SizedBox(height: 8),
                Text(
                  'Ответ придёт на ${s.me!.email.isEmpty ? 'e-mail из профиля' : s.me!.email} или по телефону ${s.me!.phone}.',
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
