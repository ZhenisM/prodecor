import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/catalog/catalog_state.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/i18n.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/theme/theme.dart';
import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/catalog/filter_sheet.dart';
import 'package:prodecor/catalog/product_card.dart';
import 'package:prodecor/catalog/sections_sheet.dart';
import 'package:prodecor/projects/project_row.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final search = TextEditingController(text: context.read<CatalogState>().q);
  final searchFocus = FocusNode();
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
    searchFocus.dispose();
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
    // поиск сброшен (смена раздела, направления, аккаунта) — очистить поле
    if (search.text != cat.q && !searchFocus.hasFocus) search.text = cat.q;

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
          IconButton(tooltip: 'Разделы', onPressed: () => showSections(context), icon: const Icon(Icons.account_tree_outlined)),
          if (!cat.rootCards)
            IconButton(
              tooltip: 'Фильтр',
              onPressed: () => showFilter(context),
              icon: Badge(isLabelVisible: nf > 0, label: Text('$nf'), child: const Icon(Icons.tune)),
            ),
          const SizedBox(width: 4),
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
                    focusNode: searchFocus,
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
}
