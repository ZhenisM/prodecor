import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Профиль дизайнера и смена пароля
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final me = context.read<Store>().me!;
  late final name = TextEditingController(text: me.name);
  late final inst = TextEditingController(text: me.inst);
  late final studio = TextEditingController(text: me.studio);
  late final spec = TextEditingController(text: me.spec);
  late final portfolio = TextEditingController(text: me.portfolio);
  late String city = me.city.isEmpty ? 'Алматы' : me.city;
  final old = TextEditingController(), p1 = TextEditingController(), p2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [name, inst, studio, spec, portfolio, old, p1, p2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await run(context, () async {
      await context.read<Store>().saveProfile({
        'name': name.text.trim(),
        'city': city,
        'inst': inst.text.trim(),
        'studio': studio.text.trim(),
        'spec': spec.text.trim(),
        'portfolio': portfolio.text.trim(),
      });
      return true;
    });
    if (ok == true && mounted) toast(context, 'Профиль сохранён');
  }

  Future<void> _password() async {
    final ok = await run(context, () async {
      await context.read<Store>().changePassword(old.text, p1.text, p2.text);
      return true;
    });
    if (ok == true && mounted) {
      old.clear();
      p1.clear();
      p2.clear();
      toast(context, 'Пароль изменён. На других устройствах нужно войти заново');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final m = s.me!;
    final cityList = cities.contains(city) ? cities : [city, ...cities];
    return Scaffold(
      appBar: AppBar(title: Text(tr(s.lang, 'profile'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Эти данные видят администратор и закреплённый менеджер.', style: TextStyle(color: c.muted)),
          const SizedBox(height: 12),
          Box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    m.active ? const Pill('Активен', 'ok') : const Pill('На модерации', 'ready'),
                    Text('Свет: ${m.light.name}', style: TextStyle(color: c.muted, fontSize: 12.5)),
                    Text('Краски: ${m.paint.name}', style: TextStyle(color: c.muted, fontSize: 12.5)),
                    if (m.iin.isNotEmpty) Text('ИИН: ${m.iin}', style: TextStyle(color: c.muted, fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 14),
                field(name, 'ФИО'),
                field(TextEditingController(text: m.phone), 'Телефон (логин)', readOnly: true),
                field(TextEditingController(text: m.email), 'E-mail', readOnly: true),
                dropdown('Город', city, cityList, (v) => setState(() => city = v)),
                field(inst, 'Instagram', hint: '@studio'),
                field(studio, 'Студия или ИП'),
                field(spec, 'Специализация'),
                field(portfolio, 'Портфолио (ссылка)', hint: 'https://', kb: TextInputType.url),
                FilledButton(onPressed: _save, child: const Text('Сохранить')),
              ],
            ),
          ),
          Box(
            title: 'Смена пароля',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field(old, 'Текущий пароль', obscure: true),
                field(p1, 'Новый пароль', obscure: true),
                field(p2, 'Повторите новый пароль', obscure: true),
                OutlinedButton(onPressed: _password, child: const Text('Изменить пароль')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
