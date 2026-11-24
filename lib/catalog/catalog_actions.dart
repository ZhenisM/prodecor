import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/catalog/catalog_state.dart';
import 'package:prodecor/catalog/product_screen.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/customer/project_form.dart';
import 'package:prodecor/theme/theme.dart';

/// Начать подбор в проект: каталог открывается в его направлении, кнопки «В проект» кладут в него
void startPicking(BuildContext context, Project p) {
  final s = context.read<Store>();
  final cat = context.read<CatalogState>();
  s.ctxProjectId = p.id;
  final d = p.dir ?? (p.dirs.isNotEmpty ? p.dirs.first : null);
  if (d != null && d != cat.dir) {
    cat.setDir(d);
  } else {
    cat.ensure();
  }
  s.goTab(3);
}

/// «Добавьте товары в проект» — первый проект в работе у дизайнера
Future<void> goCatalogFirst(BuildContext context) async {
  final s = context.read<Store>();
  final p = s.projects.where((x) => x.editable).firstOrNull;
  if (p == null) {
    s.goTab(3);
    return;
  }
  if (s.full[p.id] == null) await run(context, () => s.loadProject(p.id));
  if (context.mounted) startPicking(context, s.full[p.id] ?? p);
}

void openProductCard(BuildContext context, int id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(id: id)));

/// Добавить товар: в проект подбора или выбрать проект
Future<void> addProduct(BuildContext context, Product pr, {double qty = 1}) async {
  final s = context.read<Store>();
  final ctx = s.ctxProject;
  if (ctx != null && ctx.editable) {
    final p = await run(context, () => s.addItem(ctx.id, pr.id, qty));
    if (p != null && context.mounted) toast(context, 'Добавлено в «${p.name}»');
    return;
  }
  final picked = await sheet<int>(context, _PickProject(pr));
  if (picked == null || !context.mounted) return;
  s.ctxProjectId = picked;
  final p = await run(context, () => s.addItem(picked, pr.id, qty));
  if (p != null && context.mounted) toast(context, 'Добавлено в «${p.name}»');
}

class _PickProject extends StatelessWidget {
  final Product pr;
  const _PickProject(this.pr);
  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final ps = s.projects.where((p) => p.editable && (p.dir == null || p.dir == pr.dir)).toList();
    return SheetBody(
      title: 'В какой проект добавить?',
      children: [
        Text('${pr.name} · ${money(pr.price)}', style: TextStyle(color: c.muted)),
        const SizedBox(height: 8),
        if (ps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Нет подходящих проектов${pr.dir.isNotEmpty ? ' по направлению «${dirName[pr.dir]}»' : ''} в статусе «Черновик» или «К отправке».',
              style: TextStyle(color: c.muted),
            ),
          )
        else
          ...ps.map(
            (p) => RowX(
              title: Text(p.name),
              subtitle: Text('${s.client(p.clientId)?.name ?? ''} · ${p.count} поз.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, p.id),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await projectForm(context, dir: pr.dir);
          },
          icon: const Icon(Icons.add),
          label: const Text('Новый проект'),
        ),
      ],
    );
  }
}
