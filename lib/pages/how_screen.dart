import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/common/i18n.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/theme/theme.dart';
import 'package:prodecor/common/widgets.dart';

/// Путь: клиент → проект → товары → заявка → продажа → бонус
class HowSteps extends StatelessWidget {
  final bool full;
  const HowSteps({super.key, this.full = false});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    final list = [
      ('Клиент', 'Контакты клиента'),
      ('Проект', 'Объект, тип, площадь'),
      ('Товары', 'Свет и краски из каталога'),
      ('Заявка', 'Уходит менеджеру'),
      ('Продажа', full ? 'Заказ оплачен в 1С' : 'Заказ оформляет менеджер'),
      if (full) ('Бонус 10%', 'Можно вывести'),
    ];
    return Box(
      title: 'Как это работает',
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.g1, borderRadius: BorderRadius.circular(9)),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(color: c.onG, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(list[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(list[i].$2, style: TextStyle(color: c.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class HowScreen extends StatelessWidget {
  const HowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    Widget rule(String t) => RowX(
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
    Widget faq(String q, String a) => RowX(title: Text(q), subtitle: Text(a));
    return Scaffold(
      appBar: AppBar(title: Text(tr(s.lang, 'how'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Путь от клиента до бонуса и правила программы.', style: TextStyle(color: c.muted)),
          const SizedBox(height: 12),
          const HowSteps(full: true),
          Box(
            title: 'Правила бонусов',
            child: Column(
              children: [
                rule('Бонус — 10% от суммы заказа по вашей заявке.'),
                rule('Начисляется после подтверждённой продажи (оплата заказа в 1С).'),
                rule('При возврате товара бонус по нему сторнируется.'),
                rule('Вывод — на реквизиты из профиля, по запросу.'),
                rule('1 балл за каждые 10 000 ₸ продаж; баллы повышают уровень: Базовый → Серебряный → Золотой.'),
              ],
            ),
          ),
          Box(
            title: 'Частые вопросы',
            child: Column(
              children: [
                faq('Как начать?', 'Добавьте клиента, создайте под него проект и подберите товары из каталога — сумма посчитается сама.'),
                faq('Кто ведёт сделку после заявки?', 'Закреплённый за вами менеджер. Статусы заявки видны в разделе «Заявки».'),
                faq('Можно ли изменить заявку после отправки?', 'Нет — состав фиксируется. Напишите менеджеру или создайте новый проект.'),
                faq('Можно ли отправить заявку без товаров?', 'Нет — заявка формируется из проекта с составом.'),
                faq(
                  'Какие цены в каталоге?',
                  'Розничные цены pro-decor.kz. Пока заявка не отправлена, цены в проекте обновляются по каталогу.',
                ),
                faq('Смета для клиента', 'В карточке проекта — кнопка «Смета для клиента»: PDF можно распечатать или отправить клиенту.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
