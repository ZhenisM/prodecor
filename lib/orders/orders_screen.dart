import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/requests/request_data.dart';
import 'package:prodecor/projects/project_row.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/i18n.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/theme/theme.dart';
import 'package:prodecor/common/widgets.dart';

/// Мои заказы: оплаченные заказы по заявкам (отгрузка, бонус) + «Заказы в салонах» (контакт в Б24 и заказы сайтов)
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<Store>();
      if (s.history == null) s.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    const ship = {'paid': ('Ожидает отгрузки', 'ready'), 'shipped': ('Передан на доставку', 'work'), 'sold': ('Выполнен', 'ok')};
    final real = realRequests(s).where((r) => ship.containsKey(r.stage)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr(s.lang, 'orders'))),
      body: RefreshIndicator(
        onRefresh: () async {
          await s.refreshProjects().catchError((_) {});
          await s.loadHistory(fresh: true);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(
              'Оплаченные заказы по вашим заявкам: отгрузка и бонус по каждому. Статусы приходят из сделки менеджера в Битрикс24.',
              style: TextStyle(color: c.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (real.isEmpty && !demo)
              const Box(
                child: EmptyState(
                  Icons.inventory_2_outlined,
                  'Заказов пока нет',
                  'Заказ появится здесь, когда менеджер отметит оплату по вашей заявке.',
                ),
              ),
            ...real.map(
              (r) => _orderCard(
                context,
                number: r.number,
                date: r.sentAt,
                client: r.client,
                project: '${r.name} · ${r.dirs.map((d) => dirName[d]).join(', ')}',
                count: r.count,
                ship: ship[r.stage]!,
                sum: r.sum,
                bonus: (r.sum * .1).roundToDouble(),
                sold: r.stage == 'sold',
                onTap: () => openProject(context, r.id!),
              ),
            ),
            if (demo)
              _orderCard(
                context,
                number: '61201',
                date: '2026-09-24',
                client: 'Мадина Ержанова',
                project: 'Дом в Таусамалы',
                count: 4,
                ship: ('Отгружен', 'ok'),
                sum: 2718500,
                bonus: 271850,
                sold: true,
                isDemo: true,
              ),
            const SizedBox(height: 6),
            _history(context, s, c),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(
    BuildContext context, {
    required String number,
    required String date,
    required String client,
    required String project,
    required int count,
    required (String, String) ship,
    required double sum,
    required double bonus,
    required bool sold,
    bool isDemo = false,
    VoidCallback? onTap,
  }) {
    final c = context.pd;
    return Box(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    '№ $number',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDemo) const DemoTag(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dt(date),
                    style: TextStyle(color: c.muted, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(money(sum), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            Text(client, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('$project · $count поз.', style: TextStyle(color: c.muted, fontSize: 12.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                const Pill('Оплачен', 'ok'),
                Pill(ship.$1, ship.$2),
                sold ? Pill('Бонус ${money(bonus)}', 'gold') : Pill('Ожидается ${money(bonus)}', 'draft'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _history(BuildContext context, Store s, Pd c) {
    final h = s.history;
    return Box(
      title: 'Заказы в салонах',
      sub: 'Ваши проекты у менеджеров салонов и заказы по ним — из Битрикс24 и сайтов света и красок',
      action: s.historyLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(tooltip: 'Обновить', onPressed: () => s.loadHistory(fresh: true), icon: const Icon(Icons.refresh)),
      child: h == null
          ? Text('Загрузка…', style: TextStyle(color: c.muted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (h.error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: c.infoT, borderRadius: BorderRadius.circular(12)),
                    child: Text(h.error, style: TextStyle(color: c.info)),
                  ),
                if (h.projects.isEmpty && h.error.isEmpty)
                  Text('Проектов, привязанных к вам как к контакту, не найдено.', style: TextStyle(color: c.muted)),
                ...h.projects.map((p) {
                  final st = _hst[p.state] ?? _hst['open']!;
                  return RowX(
                    title: Text(p.title),
                    subtitle: Text(
                      'с ${dt(p.created)}${p.stageName.isNotEmpty ? ' · ${p.stageName}' : ''}\n'
                      '${p.orders.isEmpty ? 'заказов нет' : 'заказов ${p.orders.length} · оплачено ${money(p.paidSum)}'}',
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Pill(st.$1, st.$2),
                        const SizedBox(height: 4),
                        Text(money(p.ordersSum), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    onTap: () => _histProject(context, p),
                  );
                }),
                if (h.orders.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Заказы без проекта', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('Заказы на ваш номер телефона, у которых не выбран проект', style: TextStyle(color: c.muted, fontSize: 12)),
                  ...h.orders.map((o) => SiteOrderRow(o)),
                ],
              ],
            ),
    );
  }

  void _histProject(BuildContext context, HistProject p) {
    final st = _hst[p.state] ?? _hst['open']!;
    sheet<void>(
      context,
      SheetBody(
        title: p.title,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [Pill(st.$1, st.$2), if (p.stageName.isNotEmpty) Text(p.stageName)],
          ),
          const SizedBox(height: 6),
          Text('с ${dt(p.created)} · заказов ${p.orders.length} на ${money(p.ordersSum)}, оплачено ${money(p.paidSum)}'),
          const SizedBox(height: 8),
          if (p.orders.isEmpty) const Text('По проекту ещё нет заказов на сайтах.') else ...p.orders.map((o) => SiteOrderRow(o)),
        ],
      ),
    );
  }
}

const _hst = {'won': ('Успешно', 'ok'), 'lost': ('Закрыт', 'bad'), 'closed': ('Закрыт', 'draft'), 'open': ('В работе', 'work')};

class SiteOrderRow extends StatelessWidget {
  final SiteOrder o;
  const SiteOrderRow(this.o, {super.key});
  @override
  Widget build(BuildContext context) => RowX(
    title: Text('№ ${o.number}'),
    subtitle: Text('${dt(o.date)} · ${dirName[o.dir] ?? ''} · ${o.statusName}'),
    trailing: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        o.canceled ? const Pill('Отменён', 'bad') : (o.paid ? const Pill('Оплачен', 'ok') : const Pill('Не оплачен', 'ready')),
        const SizedBox(height: 4),
        Text(money(o.sum), style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
