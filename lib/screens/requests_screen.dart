import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';

/* ---------- примеры для показа, пока нет связи с 1С (как в кабинете: DEMO = true) ---------- */
const demo = true;

typedef Req = ({
  int? id,
  String number,
  String sentAt,
  String name,
  String client,
  List<String> dirs,
  String stage,
  String stageName,
  double sum,
  int count,
  bool demo,
});

final demoReq = <Req>[
  (
    id: null,
    number: '90502',
    sentAt: '2026-09-02',
    name: 'Дом в Таусамалы',
    client: 'Мадина Ержанова',
    dirs: ['paint'],
    stage: 'sold',
    stageName: '',
    sum: 2718500,
    count: 4,
    demo: true,
  ),
  (
    id: null,
    number: '90501',
    sentAt: '2026-10-09',
    name: 'Квартира в ЖК Esentai City',
    client: 'Айгерим Нурланова',
    dirs: ['light'],
    stage: 'inwork',
    stageName: '',
    sum: 382800,
    count: 6,
    demo: true,
  ),
];

/// Реальные отправленные заявки дизайнера
List<Req> realRequests(Store s) {
  final list = s.projects.where((p) => p.status == 'work').toList()
    ..sort((a, b) => b.sentAt.compareTo(a.sentAt) != 0 ? b.sentAt.compareTo(a.sentAt) : b.id - a.id);
  return list
      .map(
        (p) => (
          id: p.id,
          number: p.number,
          sentAt: p.sentAt,
          name: p.name,
          client: s.client(p.clientId)?.name ?? '',
          dirs: p.dirList,
          stage: p.stage,
          stageName: p.deal?.stageName ?? '',
          sum: (p.deal != null && p.deal!.sum > 0) ? p.deal!.sum : p.sum,
          count: p.count,
          demo: false,
        ),
      )
      .toList();
}

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final rows = [...realRequests(s), if (demo) ...demoReq];
    int cnt(String st) => rows.where((r) => r.stage == st).length;
    final stg = [
      ('Новая', 'Готов к отправке', s.projects.where((p) => p.status == 'ready').length),
      ('Отправлена', 'Ждёт менеджера', cnt('sent')),
      ('В работе', 'Менеджер ведёт сделку', cnt('inwork')),
      ('Оплачен', 'Оплата и доставка', cnt('paid') + cnt('shipped')),
      ('Продано', 'Сделка завершена', cnt('sold')),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(tr(s.lang, 'requests'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newReq(context),
        icon: const Icon(Icons.send),
        label: const Text('Новая заявка'),
        backgroundColor: c.g1,
        foregroundColor: c.onG,
      ),
      body: RefreshIndicator(
        onRefresh: () => s.refreshProjects().catchError((_) {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          children: [
            Text(
              'Дизайнер отправляет заявку — менеджер продолжает работу в Bitrix24. После подтверждённой продажи начисляется бонус 10%.',
              style: TextStyle(color: c.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stg.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final x = stg[i];
                  return Container(
                    width: 118,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.paper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: x.$3 > 0 ? c.g1 : c.sunk, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            '${x.$3}',
                            style: TextStyle(color: x.$3 > 0 ? c.onG : c.muted, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          x.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          x.$2,
                          style: TextStyle(fontSize: 10.5, color: c.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Box(
                child: EmptyState(
                  Icons.send_outlined,
                  'Заявок пока нет',
                  'Соберите состав проекта и нажмите «Отправить заявку менеджеру» в его карточке.',
                ),
              )
            else
              ...rows.map((r) => _RequestCard(r)),
          ],
        ),
      ),
    );
  }

  void _newReq(BuildContext context) {
    final s = context.read<Store>();
    final ps = s.projects.where((p) => p.status == 'ready').toList();
    sheet<void>(
      context,
      SheetBody(
        title: 'Новая заявка',
        children: [
          Text('Заявка формируется из проекта с собранным составом.', style: TextStyle(color: context.pd.muted)),
          const SizedBox(height: 8),
          if (ps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Нет проектов, готовых к отправке. Добавьте товары в проект.'),
            )
          else
            ...ps.map(
              (p) => RowX(
                title: Text(p.name),
                subtitle: Text('${s.client(p.clientId)?.name ?? ''} · ${p.count} поз.'),
                trailing: Text(money(p.sum), style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  openProject(context, p.id);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Req r;
  const _RequestCard(this.r);
  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final st = Project.stages[r.stage]!;
    return Box(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: r.id == null ? null : () => openProject(context, r.id!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${r.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (r.demo) const DemoTag(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dt(r.sentAt),
                    style: TextStyle(color: c.muted, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(child: Pill(st.$1, st.$2)),
              ],
            ),
            const SizedBox(height: 6),
            Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(r.client, style: TextStyle(color: c.muted, fontSize: 12.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                dirChips(r.dirs),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.me!.forDirs(r.dirs).map((x) => x.name).join(', '),
                    style: TextStyle(color: c.muted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StageBar(st.$3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.stageName,
                    style: TextStyle(fontSize: 11.5, color: c.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(money(r.sum), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
