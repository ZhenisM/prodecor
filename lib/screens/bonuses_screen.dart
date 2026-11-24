import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'requests_screen.dart';

const _levels = [
  ('Базовый', 0, 'Бонус 10%, каталог, обучение'),
  ('Серебряный', 500, 'Приоритет у менеджера, закрытые акции'),
  ('Золотой', 1500, 'Персональный менеджер, повышенный бонус на акции'),
];

/// Бонусы — пока на примерах, расчёт появится с подключением 1С (как в кабинете)
class BonusesScreen extends StatelessWidget {
  const BonusesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final req = realRequests(s);
    final sold = [
      ...req
          .where((r) => r.stage == 'sold')
          .map((r) => (date: r.sentAt, project: r.name, number: r.number, sum: r.sum, bonus: (r.sum * .1).roundToDouble(), demo: false)),
      if (demo) (date: '2026-09-24', project: 'Дом в Таусамалы', number: '61201', sum: 2718500.0, bonus: 271850.0, demo: true),
    ];
    final inwork = [
      ...req.where((r) => ['sent', 'inwork', 'paid', 'shipped'].contains(r.stage)),
      if (demo) ...demoReq.where((r) => r.stage == 'inwork'),
    ];
    final sales = sold.fold<double>(0.0, (a, o) => a + o.sum);
    final bonus = sold.fold<double>(0.0, (a, o) => a + o.bonus);
    final pending = (inwork.fold<double>(0.0, (a, r) => a + r.sum) * .1).roundToDouble();
    const paid = 0.0;
    final points = (sales / 10000).floor();
    var li = _levels.length - 1;
    while (li > 0 && points < _levels[li].$2) {
      li--;
    }
    final level = _levels[li];
    final next = li + 1 < _levels.length ? _levels[li + 1] : null;
    final pct = next == null ? 1.0 : ((points - level.$2) / (next.$2 - level.$2)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(tr(s.lang, 'bonuses'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const PageHead(
            'Программа лояльности',
            'Бонус 10%',
            sub: '10% от суммы каждой подтверждённой продажи. Баллы за продажи повышают уровень.',
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              Tile('Доступно к выводу', money(bonus - paid), 'После подтверждения продаж', Icons.account_balance_wallet_outlined, c.gold),
              Tile('Ожидается', money(pending), 'Заявки в работе — бонус после оплаты', Icons.schedule, c.info),
              Tile('Начислено всего', money(bonus), 'За ${sold.length} продаж(у)', Icons.card_giftcard, c.ok),
              Tile('Выплачено', money(paid), 'На реквизиты из профиля', Icons.trending_up, c.warn),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: c.infoT, borderRadius: BorderRadius.circular(14)),
            child: Text(
              'Расчёт бонусов и вывод заработают после подключения к 1С. Сейчас раздел показывает пример.',
              style: TextStyle(color: c.info),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.gold, c.gold2]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Уровень «${level.$1}»',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        next != null ? 'До «${next.$1}»: $points из ${next.$2} баллов' : 'Максимальный уровень',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: pct, minHeight: 6, color: Colors.white, backgroundColor: Colors.white24),
                ),
                const SizedBox(height: 6),
                Text(level.$3, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          Box(
            title: 'История',
            child: sold.isEmpty
                ? Text('Начисления появятся после первой подтверждённой продажи.', style: TextStyle(color: c.muted))
                : Column(
                    children: sold
                        .map(
                          (o) => RowX(
                            title: Row(
                              children: [
                                Flexible(child: Text('Начисление · ${o.project}')),
                                if (o.demo) const DemoTag(),
                              ],
                            ),
                            subtitle: Text('Заказ № ${o.number} · продажа ${money(o.sum)} · ${dt(o.date)}'),
                            trailing: Text(
                              '+${money(o.bonus)}',
                              style: TextStyle(color: c.ok, fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          Box(
            title: 'Уровни',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _levels.length; i++)
                  RowX(
                    title: Row(
                      children: [
                        Text(_levels[i].$1),
                        if (i == li) ...[const SizedBox(width: 6), const Chip2('ваш')],
                      ],
                    ),
                    subtitle: Text(_levels[i].$3),
                    trailing: Text('от ${_levels[i].$2} баллов', style: TextStyle(color: c.muted, fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                Text(
                  '1 балл — за каждые 10 000 ₸ подтверждённых продаж. Пороги уровней настраиваются администратором.',
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
