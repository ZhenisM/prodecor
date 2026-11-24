import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/catalog/catalog_actions.dart';
import 'package:prodecor/projects/project_row.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/i18n.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/theme/theme.dart';
import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/customer/client_form.dart';
import 'package:prodecor/customer/project_form.dart';
import 'package:prodecor/pages/how_screen.dart';
import 'package:prodecor/profile/profile_screen.dart';

typedef StepItem = ({String title, bool done, String text, Future<void> Function(BuildContext) go});

/// «Первые шаги» — как подсказка «Следующий шаг» в кабинете
List<StepItem> steps(Store s) {
  final pr = s.projects;
  return [
    (
      title: 'Добавьте первого клиента',
      done: s.clients.isNotEmpty,
      text: 'С клиента начинается работа — потом под него создаётся проект.',
      go: (c) => clientForm(c),
    ),
    (
      title: 'Создайте проект',
      done: pr.isNotEmpty,
      text: 'Проект — это объект клиента: тип помещения, площадь, адрес.',
      go: (c) => projectForm(c),
    ),
    (
      title: 'Добавьте товары в проект',
      done: pr.any((p) => p.count > 0),
      text: 'Соберите состав из каталога света и красок — сумма посчитается сама.',
      go: (c) => goCatalogFirst(c),
    ),
    (
      title: 'Отправьте заявку менеджеру',
      done: pr.any((p) => p.status == 'work'),
      text: 'Кнопка «Отправить заявку менеджеру» — в карточке проекта.',
      go: (c) async => c.read<Store>().goTab(1),
    ),
    (
      title: 'Заполните профиль',
      done: (s.me?.studio.isNotEmpty ?? false) && (s.me?.inst.isNotEmpty ?? false),
      text: 'Студия и Instagram помогают менеджеру быстрее с вами работать.',
      go: (c) async => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
    ),
  ];
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final me = s.me!;
    final first = me.firstName.isNotEmpty ? me.firstName : shortName(me.name).split(' ').first;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(children: [PdLogo(size: 26), SizedBox(width: 10), Text('PRODECOR')]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Avatar(shortName(me.name), size: 34),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => s.refreshProjects().catchError((_) {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: s.active ? _active(context, s, first) : _moderation(context, first, c),
        ),
      ),
    );
  }

  List<Widget> _moderation(BuildContext context, String first, Pd c) => [
    PageHead(tr(context.read<Store>().lang, 'dash'), 'Добрый день, $first'),
    Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: c.infoT, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: c.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Профиль на модерации',
                  style: TextStyle(color: c.info, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Администратор проверит данные и закрепит менеджера — обычно в течение рабочего дня. Пока можно заполнить профиль.',
            style: TextStyle(color: c.info),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: const Text('Профиль'),
          ),
        ],
      ),
    ),
    const HowSteps(),
    TextButton(onPressed: () => context.read<Store>().refreshMe(), child: const Text('Проверить статус')),
  ];

  List<Widget> _active(BuildContext context, Store s, String first) {
    final prs = s.projects;
    final sp = steps(s);
    final done = sp.where((x) => x.done).length;
    final work = prs.where((p) => p.status == 'work').toList();
    final act = prs.where((p) => p.editable).toList();
    final hideSteps = s.me!.stepsHidden || done == sp.length;
    final c = context.pd;
    final next = sp.where((x) => !x.done).firstOrNull;
    return [
      PageHead(tr(s.lang, 'dash'), 'Добрый день, $first', sub: 'Сводка по клиентам, проектам и заявкам менеджеру.'),
      FilledButton.icon(onPressed: () => projectForm(context), icon: const Icon(Icons.add), label: const Text('Новый проект')),
      const SizedBox(height: 14),
      if (!s.me!.hintOff && next != null)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.g1, c.g2]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: c.gold2, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Следующий шаг', style: TextStyle(color: c.onG.withValues(alpha: .8), fontSize: 12)),
                  ),
                  InkWell(
                    onTap: () => s.setPref('hintOff'),
                    child: Icon(Icons.close, color: c.onG, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                next.title,
                style: TextStyle(color: c.onG, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Text(next.text, style: TextStyle(color: c.onG.withValues(alpha: .85), fontSize: 12.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: c.onG, foregroundColor: c.g1),
                    onPressed: () => next.go(context),
                    child: const Text('Перейти'),
                  ),
                  TextButton(
                    onPressed: () => s.setPref('hintOff'),
                    child: Text('Я разобрался', style: TextStyle(color: c.onG)),
                  ),
                ],
              ),
            ],
          ),
        ),
      if (!hideSteps)
        Box(
          title: 'Первые шаги',
          sub: 'Выполнено $done из ${sp.length}',
          action: LinkBtn('Скрыть', () => s.setPref('stepsHidden')),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: done / sp.length, minHeight: 6, backgroundColor: c.sunk, color: c.gold),
              ),
              const SizedBox(height: 6),
              ...sp.map(
                (x) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () => x.go(context),
                  leading: Icon(x.done ? Icons.check_circle : Icons.radio_button_unchecked, color: x.done ? c.ok : c.soft),
                  title: Text(
                    x.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: x.done ? TextDecoration.lineThrough : null,
                      color: x.done ? c.muted : c.ink,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ],
          ),
        ),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
        children: [
          Tile('Клиенты', '${s.clients.length}', 'В вашей базе', Icons.people_outline, c.gold),
          Tile('Проекты у вас', '${act.length}', 'Черновики и к отправке · всего ${prs.length}', Icons.folder_outlined, c.info),
          Tile('Заявки менеджеру', '${work.length}', 'Отправлены и в работе', Icons.send_outlined, c.warn),
          Tile('Сумма заявок', money(work.fold<double>(0.0, (a, p) => a + p.sum)), 'По ценам каталога', Icons.trending_up, c.ok),
        ],
      ),
      const SizedBox(height: 14),
      Box(
        title: 'Последние проекты',
        action: LinkBtn('Все проекты', () => s.goTab(1)),
        child: prs.isEmpty
            ? EmptyState(
                Icons.folder_outlined,
                'Проектов пока нет',
                'Создайте первый проект под клиента.',
                action: FilledButton.icon(
                  onPressed: () => projectForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Новый проект'),
                ),
              )
            : Column(children: prs.take(6).map((p) => ProjectRow(p)).toList()),
      ),
      Box(
        title: 'Заявки менеджеру',
        action: LinkBtn('Все', () => s.goTab(2)),
        child: work.isEmpty
            ? Text('Заявок пока нет. Отправьте проект менеджеру из его карточки.', style: TextStyle(color: c.muted))
            : Column(
                children: work
                    .take(4)
                    .map(
                      (p) => RowX(
                        title: Text('№ ${p.number}'),
                        subtitle: Text(p.name),
                        trailing: Pill(Project.stages[p.stage]!.$1, Project.stages[p.stage]!.$2),
                        onTap: () => openProject(context, p.id),
                      ),
                    )
                    .toList(),
              ),
      ),
      const ManagersBox(),
    ];
  }
}
