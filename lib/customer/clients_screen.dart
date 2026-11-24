import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/projects/project_row.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/i18n.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/theme/theme.dart';
import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/customer/client_form.dart';
import 'package:prodecor/customer/project_form.dart';

/// Клиенты и проекты: фильтр по статусу, поиск, раскрывающиеся клиенты с проектами
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String f = 'all';
  String q = '';
  final closed = <int>{};

  bool has(String s, String q) => q.isEmpty || s.toLowerCase().contains(q.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final all = s.projects;
    int cnt(String k) => all.where((p) => p.status == k).length;
    final list = s.clients.reversed.where((cl) {
      final ps = all.where(
        (x) => x.clientId == cl.id && (f == 'all' || x.status == f) && (has(x.name, q) || has(cl.name, q) || has(cl.phone, q)),
      );
      return ps.isNotEmpty || (f == 'all' && (has(cl.name, q) || has(cl.phone, q)));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(s.lang, 'clients')),
        actions: [IconButton(tooltip: 'Новый клиент', onPressed: () => clientForm(context), icon: const Icon(Icons.person_add_alt))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => projectForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Проект'),
        backgroundColor: c.g1,
        foregroundColor: c.onG,
      ),
      body: RefreshIndicator(
        onRefresh: () => s.refreshProjects().catchError((_) {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по клиенту, телефону или проекту'),
              onChanged: (v) => setState(() => q = v.trim()),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                          ('all', 'Все', all.length),
                          ('draft', 'Черновики', cnt('draft')),
                          ('ready', 'К отправке', cnt('ready')),
                          ('work', 'В работе', cnt('work')),
                        ]
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('${t.$2} ${t.$3}'),
                              selected: f == t.$1,
                              onSelected: (_) => setState(() => f = t.$1),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              Box(
                child: EmptyState(
                  Icons.people_outline,
                  s.clients.isEmpty ? 'Клиентов пока нет' : 'Ничего не найдено',
                  s.clients.isEmpty ? 'Добавьте первого клиента — под него создадите проект.' : 'Измените фильтр или строку поиска.',
                  action: s.clients.isEmpty
                      ? FilledButton.icon(
                          onPressed: () => clientForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить клиента'),
                        )
                      : null,
                ),
              )
            else
              ...list.map((cl) {
                final mine = all.where((p) => p.clientId == cl.id).toList();
                final ps = mine
                    .where((x) => (f == 'all' || x.status == f) && (has(x.name, q) || has(cl.name, q) || has(cl.phone, q)))
                    .toList();
                final open = !closed.contains(cl.id);
                final tot = mine.fold<double>(0.0, (a, p) => a + p.sum);
                return Box(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () => setState(() => open ? closed.add(cl.id) : closed.remove(cl.id)),
                        child: Row(
                          children: [
                            Avatar(cl.name, size: 36),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cl.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  Text(
                                    [cl.phone, if (cl.city.isNotEmpty) cl.city].join(' · '),
                                    style: TextStyle(color: c.muted, fontSize: 12.5),
                                  ),
                                  Text('${mine.length} проект(а) · ${money(tot)}', style: TextStyle(color: c.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) => v == 'edit' ? clientForm(context, client: cl) : projectForm(context, clientId: cl.id),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'project', child: Text('Новый проект')),
                                PopupMenuItem(value: 'edit', child: Text('Изменить клиента')),
                              ],
                            ),
                            Icon(open ? Icons.expand_less : Icons.expand_more, color: c.muted),
                          ],
                        ),
                      ),
                      if (open && ps.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...ps.map((p) => Padding(padding: const EdgeInsets.only(right: 6), child: ProjectRow(p, showClient: false))),
                      ],
                      if (open && mine.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => projectForm(context, clientId: cl.id),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Проект для клиента'),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
