import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/catalog.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';
import 'forms.dart';
import 'product_screen.dart';

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

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final search = TextEditingController(text: context.read<CatalogState>().q);
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CatalogState>().ensure());
    scroll.addListener(() {
      final cat = context.read<CatalogState>();
      if (scroll.position.pixels > scroll.position.maxScrollExtent - 600 && !cat.loading && cat.page < cat.pages) {
        cat.load(more: true);
      }
    });
  }

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final cat = context.watch<CatalogState>();
    final c = context.pd;
    final ctx = s.ctxProject;
    final path = cat.path(cat.section);
    final nf = cat.ctl.length;
    final title = path.isNotEmpty ? path.last.name : tr(s.lang, 'catalog');
    final dirs = ctx?.dir != null ? [ctx!.dir!] : ['light', 'paint'];
    if (search.text != cat.q && !FocusScope.of(context).hasFocus) search.text = cat.q;

    return Scaffold(
      appBar: AppBar(
        leading: cat.section != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => cat.setSection(path.length > 1 ? path[path.length - 2].id : 0),
              )
            : null,
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          if (!cat.rootCards)
            IconButton(
              tooltip: 'Разделы и фильтр',
              onPressed: () => _filters(context),
              icon: Badge(isLabelVisible: nf > 0, label: Text('$nf'), child: const Icon(Icons.tune)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => cat.load(),
        child: CustomScrollView(
          controller: scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverList.list(
                children: [
                  if (ctx != null) _ctxBanner(context, ctx),
                  Row(
                    children: [
                      ...dirs.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            avatar: Icon(dirIcon(d), size: 16),
                            label: Text(dirName[d]!),
                            selected: cat.dir == d,
                            onSelected: (_) => cat.setDir(d),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: cat.rootCards ? 'Поиск по всему каталогу: название или артикул' : 'Название или артикул',
                      suffixIcon: cat.q.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                search.clear();
                                cat.setQuery('');
                              },
                            )
                          : null,
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: cat.setQuery,
                  ),
                  const SizedBox(height: 8),
                  if (!cat.rootCards) ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: cat.sort,
                              isExpanded: true,
                              items: sorts.map((x) => DropdownMenuItem(value: x.$1, child: Text(x.$2))).toList(),
                              onChanged: (v) => cat.setSort(v ?? 'default'),
                            ),
                          ),
                        ),
                        FilterChip(label: const Text('В наличии'), selected: cat.inStock, onSelected: cat.setStock),
                      ],
                    ),
                    if (path.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            LinkBtn(dirName[cat.dir]!, () => cat.setSection(0)),
                            ...path.expand((x) => [const Text(' / '), LinkBtn(x.name, () => cat.setSection(x.id))]),
                          ],
                        ),
                      ),
                    _chips(context, cat),
                    // подразделы текущего раздела — быстрый переход
                    if (cat.children(cat.section).isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: cat
                              .children(cat.section)
                              .map(
                                (x) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(label: Text('${x.name} · ${x.count}'), onPressed: () => cat.setSection(x.id)),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    if (cat.total > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('Найдено: ${num2(cat.total)}', style: TextStyle(color: c.muted, fontSize: 12.5)),
                      ),
                  ],
                  if (cat.error.isNotEmpty)
                    Box(
                      child: EmptyState(
                        Icons.wifi_off,
                        'Не удалось загрузить',
                        cat.error,
                        action: OutlinedButton(onPressed: () => cat.load(), child: const Text('Повторить')),
                      ),
                    ),
                ],
              ),
            ),
            if (cat.rootCards)
              _rootCards(context, cat)
            else if (cat.items.isEmpty && !cat.loading && cat.error.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Box(child: EmptyState(Icons.search_off, 'Ничего не найдено', 'Измените раздел, фильтр или строку поиска.')),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .56,
                  ),
                  delegate: SliverChildBuilderDelegate((_, i) => ProductCard(cat.items[i]), childCount: cat.items.length),
                ),
              ),
            if (cat.loading) const SliverToBoxAdapter(child: Loading()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _ctxBanner(BuildContext context, Project ctx) {
    final c = context.pd;
    final s = context.read<Store>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(color: c.goldTint, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(Icons.folder_outlined, color: c.goldInk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Добавляете в «${ctx.name}» · ${ctx.items?.length ?? ctx.count} поз. на ${money(ctx.itemsSum)}',
              style: TextStyle(color: c.goldInk, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              final id = ctx.id;
              s.ctxProjectId = null;
              s.goTab(1);
              openProject(context, id);
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  Widget _chips(BuildContext context, CatalogState cat) {
    final out = <Widget>[];
    for (final f in cat.facets) {
      if (f.isRange) {
        final a = cat.ctl[f.cMin], b = cat.ctl[f.cMax];
        if ((a ?? '').isNotEmpty || (b ?? '').isNotEmpty) {
          out.add(
            InputChip(
              label: Text('${f.name}: ${a != null ? 'от $a ' : ''}${b != null ? 'до $b' : ''}'),
              onDeleted: () {
                cat.ctl.remove(f.cMin);
                cat.ctl.remove(f.cMax);
                cat.load();
              },
            ),
          );
        }
      } else {
        for (final v in f.values) {
          if (cat.ctl[v.c] != null) out.add(InputChip(label: Text(v.v), onDeleted: () => cat.setCtl(v.c, null, now: true)));
        }
      }
    }
    if (out.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: [...out, LinkBtn('Сбросить всё', cat.resetFilter)]);
  }

  Widget _rootCards(BuildContext context, CatalogState cat) {
    final roots = cat.children(0);
    final c = context.pd;
    if (cat.tree[cat.dir] == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: .85,
        ),
        delegate: SliverChildBuilderDelegate((_, i) {
          final sct = roots[i];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => cat.setSection(sct.id),
            child: Container(
              decoration: BoxDecoration(
                color: c.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.line),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(child: NetImg(sct.img, fallback: dirIcon(cat.dir))),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sct.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text('${num2(sct.count)} товаров', style: TextStyle(color: c.muted, fontSize: 12)),
                ],
              ),
            ),
          );
        }, childCount: roots.length),
      ),
    );
  }

  void _filters(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FractionallySizedBox(heightFactor: .9, child: _FilterSheet()),
  );
}

/// Карточка товара в сетке
class ProductCard extends StatelessWidget {
  final Product pr;
  const ProductCard(this.pr, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final ctx = s.ctxProject;
    final inQ = ctx?.items?.where((i) => i.pid == pr.id).firstOrNull?.qty;
    return Material(
      color: c.paper,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        onTap: () => openProductCard(context, pr.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: NetImg(pr.img, fallback: dirIcon(pr.dir)),
                    ),
                  ),
                  if (pr.brand.isNotEmpty)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: c.paper.withValues(alpha: .9), borderRadius: BorderRadius.circular(99)),
                        child: Text(pr.brand, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pr.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pr.qty > 0 ? 'в наличии ${num2(pr.qty)} ${pr.measure}' : 'под заказ',
                    style: TextStyle(fontSize: 11.5, color: pr.qty > 0 ? c.ok : c.muted),
                  ),
                  const SizedBox(height: 4),
                  if (pr.price > 0)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 6,
                      children: [
                        Text(money(pr.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                        if (pr.old != null)
                          Text(
                            money(pr.old),
                            style: TextStyle(fontSize: 11.5, color: c.muted, decoration: TextDecoration.lineThrough),
                          ),
                      ],
                    )
                  else
                    Text('Цена по запросу', style: TextStyle(fontSize: 12, color: c.muted)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: inQ != null ? c.goldTint : null,
                        foregroundColor: inQ != null ? c.goldInk : null,
                      ),
                      onPressed: pr.canAdd ? () => addProduct(context, pr) : null,
                      child: Text(inQ != null ? 'В проекте · ${num2(inQ)}' : 'В проект', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Разделы и фильтр (как боковая панель каталога на сайте)
class _FilterSheet extends StatefulWidget {
  const _FilterSheet();
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final open = <String, bool>{};
  final more = <String>{};
  final fq = <String, String>{};
  final secOpen = <int>{};

  bool _facetOpen(CatalogState cat, Facet f) =>
      open[f.id] ?? (f.isRange || f.expanded || f.values.any((v) => cat.ctl[v.c] != null) || cat.facets.indexOf(f) < 3);

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogState>();
    final c = context.pd;
    final sel = cat.path(cat.section).map((x) => x.id).toSet();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text('Разделы и фильтр', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              if (cat.ctl.isNotEmpty) LinkBtn('Сбросить', cat.resetFilter),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              const Text('Разделы', style: TextStyle(fontWeight: FontWeight.w700)),
              _secTile(cat, null, 0, sel),
              ...cat.children(0).map((x) => _secNode(cat, x, 0, sel)),
              const Divider(height: 24),
              const Text('Фильтр', style: TextStyle(fontWeight: FontWeight.w700)),
              if (cat.facets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(cat.loading ? 'Загрузка…' : 'Нет параметров для фильтра', style: TextStyle(color: c.muted)),
                ),
              ...cat.facets.map((f) => _facet(cat, f)),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(cat.loading ? 'Загрузка…' : 'Показать ${num2(cat.total)}'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _secTile(CatalogState cat, Section? x, int depth, Set<int> sel) {
    final c = context.pd;
    final id = x?.id ?? 0;
    final kids = x == null ? <Section>[] : cat.children(id);
    final isOpen = x != null && (secOpen.contains(id) || (sel.contains(id) && !secOpen.contains(-id)));
    return InkWell(
      onTap: () => cat.setSection(id),
      child: Padding(
        padding: EdgeInsets.only(left: depth * 14.0, top: 6, bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: kids.isEmpty
                  ? null
                  : InkWell(
                      onTap: () => setState(() {
                        if (isOpen) {
                          secOpen.remove(id);
                          secOpen.add(-id);
                        } else {
                          secOpen.add(id);
                          secOpen.remove(-id);
                        }
                      }),
                      child: Icon(isOpen ? Icons.expand_more : Icons.chevron_right, size: 20, color: c.muted),
                    ),
            ),
            Expanded(
              child: Text(
                x?.name ?? 'Все разделы',
                style: TextStyle(
                  fontWeight: cat.section == id ? FontWeight.w800 : FontWeight.w500,
                  color: cat.section == id ? c.goldInk : c.ink,
                ),
              ),
            ),
            if (x != null) Text(num2(x.count), style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
    );
  }

  Widget _secNode(CatalogState cat, Section x, int depth, Set<int> sel) {
    final kids = cat.children(x.id);
    final isOpen = secOpen.contains(x.id) || (sel.contains(x.id) && !secOpen.contains(-x.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_secTile(cat, x, depth, sel), if (isOpen) ...kids.map((k) => _secNode(cat, k, depth + 1, sel))],
    );
  }

  Widget _facet(CatalogState cat, Facet f) {
    final c = context.pd;
    final isOpen = _facetOpen(cat, f);
    Widget body;
    if (f.isRange) {
      body = Row(
        children: [
          Expanded(
            child: _RangeField(ctlKey: f.cMin, hint: 'от ${num2(f.min)}', cat: cat),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RangeField(ctlKey: f.cMax, hint: 'до ${num2(f.max)}', cat: cat),
          ),
        ],
      );
    } else {
      final avail = f.values.where((v) => !v.disabled || cat.ctl[v.c] != null).toList();
      final q = (fq[f.id] ?? '').toLowerCase();
      final vis = q.isEmpty ? avail : avail.where((v) => v.v.toLowerCase().contains(q) || cat.ctl[v.c] != null).toList();
      final all = more.contains(f.id) || q.isNotEmpty;
      final shown = all ? vis.take(300).toList() : vis.take(8).toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (avail.length > 15)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Поиск по значениям', prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => setState(() => fq[f.id] = v),
              ),
            ),
          ...shown.map(
            (v) => CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              visualDensity: VisualDensity.compact,
              value: cat.ctl[v.c] != null,
              onChanged: (on) => cat.setCtl(v.c, on == true ? 'Y' : null),
              title: Text(v.v, style: TextStyle(color: v.disabled ? c.soft : c.ink)),
              secondary: v.n != null ? Text('${v.n}', style: TextStyle(fontSize: 12, color: c.muted)) : null,
            ),
          ),
          if (vis.isEmpty) Text('Ничего не найдено', style: TextStyle(color: c.muted)),
          if (q.isEmpty && vis.length > 8)
            Align(
              alignment: Alignment.centerLeft,
              child: LinkBtn(
                all ? 'Свернуть' : 'Показать все (${vis.length})',
                () => setState(() => all ? more.remove(f.id) : more.add(f.id)),
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => open[f.id] = !isOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: c.muted),
              ],
            ),
          ),
        ),
        if (isOpen) body,
        Divider(color: c.line),
      ],
    );
  }
}

class _RangeField extends StatefulWidget {
  final String ctlKey, hint;
  final CatalogState cat;
  const _RangeField({required this.ctlKey, required this.hint, required this.cat});
  @override
  State<_RangeField> createState() => _RangeFieldState();
}

class _RangeFieldState extends State<_RangeField> {
  late final ctl = TextEditingController(text: widget.cat.ctl[widget.ctlKey] ?? '');
  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(hintText: widget.hint),
    onChanged: (v) => widget.cat.setCtl(widget.ctlKey, v.trim().replaceAll(',', '.')),
  );
}
