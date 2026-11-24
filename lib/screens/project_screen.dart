import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'catalog_screen.dart';
import 'estimate.dart';
import 'forms.dart';

/// Карточка проекта: объект, состав (кол-во, удаление), смета, отправка заявки менеджеру
class ProjectScreen extends StatefulWidget {
  final int id;
  const ProjectScreen({super.key, required this.id});
  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  String? error;
  final Map<int, Timer> _qtyTimers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final t in _qtyTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await context.read<Store>().loadProject(widget.id);
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  void _qty(Project p, Item it, double step) {
    final nq = ((it.qty + step) * 100).round() / 100;
    if (nq < 1 || nq == it.qty) return;
    setState(() => it.qty = nq);
    _qtyTimers[it.bid]?.cancel();
    _qtyTimers[it.bid] = Timer(const Duration(milliseconds: 450), () async {
      try {
        await context.read<Store>().setQty(p.id, it.bid, nq);
      } catch (e) {
        if (mounted) {
          toast(context, e.toString());
          _load();
        }
      }
    });
  }

  Future<void> _remove(Project p, Item it) async {
    await run(context, () => context.read<Store>().removeItem(p.id, it.bid));
  }

  Future<void> _delete(Project p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: Text('«${p.name}» и его состав исчезнут из кабинета. Клиент останется.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.pd.badT, foregroundColor: ctx.pd.bad),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = await run(context, () async {
      await context.read<Store>().deleteProject(p.id);
      return true;
    });
    if (r == true && mounted) {
      toast(context, 'Проект удалён');
      Navigator.pop(context);
    }
  }

  Future<void> _send(Project p) async {
    final sent = await sheet<Project>(context, _SendSheet(p));
    if (sent != null && mounted) toast(context, 'Заявка № ${sent.number} отправлена менеджеру');
  }

  void _toCatalog(Project p) {
    startPicking(context, p);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final p = s.full[widget.id];
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: error != null
            ? EmptyState(
                Icons.error_outline,
                'Не удалось открыть проект',
                error!,
                action: OutlinedButton(onPressed: _load, child: const Text('Повторить')),
              )
            : const Loading(),
      );
    }
    final c = context.pd;
    final cl = s.client(p.clientId);
    final st = Project.statuses[p.status] ?? Project.statuses['work']!;
    final lock = !p.editable;
    final items = p.items ?? [];
    final mgr = s.me!.forDirs(p.dirList).map((x) => x.name).join(', ');
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name, overflow: TextOverflow.ellipsis),
        actions: [
          if (!lock)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? projectForm(context, edit: p) : _delete(p),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Изменить проект')),
                PopupMenuItem(value: 'del', child: Text('Удалить проект')),
              ],
            ),
        ],
      ),
      bottomNavigationBar: lock || items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  onPressed: () => _send(p),
                  icon: const Icon(Icons.send),
                  label: const Text('Отправить заявку менеджеру'),
                ),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (p.dir != null) Chip2(dirName[p.dir]!, icon: dirIcon(p.dir)),
                Pill(st.$1, st.$2),
                Text('Проект · ${cl?.name ?? ''}', style: TextStyle(color: c.muted, fontSize: 12.5)),
              ],
            ),
            const SizedBox(height: 12),
            Box(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _meta('Клиент', cl?.name ?? '', cl?.phone),
                  _meta('Объект', p.type + (p.area > 0 ? ', ${num2(p.area)} м²' : ''), p.address),
                  _meta('Менеджер', mgr, null),
                  _meta('Создан', dt(p.created), null),
                  if (p.budget.isNotEmpty) _meta('Бюджет', p.budget, null),
                  if (p.deadline.isNotEmpty) _meta('Сроки', p.deadline, null),
                  if (p.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(p.note, style: TextStyle(color: c.muted)),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: items.isEmpty ? null : () => run(context, () => shareEstimate(p: p, client: cl, me: s.me!)),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Смета для клиента'),
                  ),
                ),
                if (!lock) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(backgroundColor: c.goldTint, foregroundColor: c.goldInk),
                      onPressed: () => _toCatalog(p),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Из каталога'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Box(
              title: 'Состав проекта',
              sub: lock ? 'Состав зафиксирован в заявке' : null,
              child: items.isEmpty
                  ? EmptyState(
                      Icons.inventory_2_outlined,
                      'В проекте пока нет товаров',
                      'Подберите позиции из каталога света и красок.',
                      action: lock ? null : FilledButton(onPressed: () => _toCatalog(p), child: const Text('Открыть каталог')),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...items.map((i) => _itemRow(p, i, lock)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Итого по ценам каталога', style: TextStyle(color: c.muted)),
                            ),
                            Text(money(p.itemsSum), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          ],
                        ),
                        if (!lock)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Цены обновляются по каталогу при каждом открытии проекта, пока заявка не отправлена.',
                              style: TextStyle(fontSize: 11.5, color: c.muted),
                            ),
                          ),
                      ],
                    ),
            ),
            if (lock) _request(p),
          ],
        ),
      ),
    );
  }

  Widget _meta(String label, String value, String? sub) {
    final c = context.pd;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(color: c.muted, fontSize: 12.5)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (sub != null && sub.isNotEmpty) Text(sub, style: TextStyle(color: c.muted, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(Project p, Item i, bool lock) {
    final c = context.pd;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => openProductCard(context, i.pid),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: NetImg(i.img, w: 56, h: 56, fallback: dirIcon(i.dir)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [i.brand, if (i.article.isNotEmpty) 'арт. ${i.article}'].where((x) => x.isNotEmpty).join(' · '),
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${money(i.price)}${i.measure != 'шт' ? ' / ${i.measure}' : ''}',
                        style: TextStyle(fontSize: 12.5, color: c.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(money(i.price * i.qty), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                if (lock)
                  Text('Количество: ${num2(i.qty)} ${i.measure}', style: TextStyle(fontSize: 12.5, color: c.muted))
                else
                  Row(
                    children: [
                      QtyBox(qty: i.qty, onMinus: () => _qty(p, i, -1), onPlus: () => _qty(p, i, 1)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Удалить позицию',
                        onPressed: () => _remove(p, i),
                        icon: Icon(Icons.close, color: c.muted),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _request(Project p) {
    final c = context.pd;
    final st = Project.stages[p.stage]!;
    return Box(
      title: 'Заявка по проекту',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Заявка № ${p.number} · ${dt(p.sentAt)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Pill(st.$1, st.$2),
            ],
          ),
          const SizedBox(height: 6),
          StageBar(st.$3),
          const SizedBox(height: 6),
          Text(
            (p.deal != null && p.deal!.stageName.isNotEmpty ? 'Этап у менеджера: ${p.deal!.stageName}' : 'Ожидает менеджера') +
                (p.comment.isNotEmpty ? ' · ваш комментарий: ${p.comment}' : ''),
            style: TextStyle(color: c.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Text(
            money(p.deal != null && p.deal!.sum > 0 ? p.deal!.sum : p.sum),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
        ],
      ),
    );
  }
}

/// −  1  +
class QtyBox extends StatelessWidget {
  final double qty;
  final VoidCallback onMinus, onPlus;
  const QtyBox({super.key, required this.qty, required this.onMinus, required this.onPlus});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    Widget b(IconData i, VoidCallback f) => InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: f,
      child: Padding(padding: const EdgeInsets.all(8), child: Icon(i, size: 18)),
    );
    return Container(
      decoration: BoxDecoration(color: c.sunk, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          b(Icons.remove, onMinus),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 34),
            child: Text(
              num2(qty),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          b(Icons.add, onPlus),
        ],
      ),
    );
  }
}

class _SendSheet extends StatefulWidget {
  final Project p;
  const _SendSheet(this.p);
  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  final comment = TextEditingController();
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final r = await run(context, () => context.read<Store>().send(widget.p.id, comment.text.trim()));
    if (r != null && mounted) Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<Store>();
    final c = context.pd;
    final p = widget.p;
    final mm = s.me!.forDirs(p.dirList).map((x) => x.name).join(', ');
    final dirs = p.dirList.map((d) => dirName[d] ?? d).join(', ');
    return SheetBody(
      title: 'Отправить заявку менеджеру',
      children: [
        Text(
          '«${p.name}» · ${p.items?.length ?? p.count} поз. на ${money(p.itemsSum > 0 ? p.itemsSum : p.sum)}. '
          'Направление: ${dirs.isEmpty ? '—' : dirs}. Менеджер: $mm.',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.infoT, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, color: c.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text('После отправки состав проекта фиксируется и изменить его будет нельзя.', style: TextStyle(color: c.info)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        field(comment, 'Комментарий для менеджера', hint: 'Сроки, пожелания клиента, вопросы по наличию', lines: 3),
        FilledButton.icon(onPressed: _go, icon: const Icon(Icons.send), label: const Text('Отправить')),
      ],
    );
  }
}
