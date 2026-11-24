import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/catalog.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'catalog_screen.dart';
import 'project_screen.dart';

/// Карточка товара: фото, цена, наличие, количество, «В проект», характеристики, описание
class ProductScreen extends StatefulWidget {
  final int id;
  const ProductScreen({super.key, required this.id});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? p;
  String? error;
  double qty = 1;
  int img = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<CatalogState>().product(widget.id);
      if (mounted) setState(() => p = r);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final p = this.p;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: error != null
            ? EmptyState(
                Icons.error_outline,
                'Не удалось открыть товар',
                error!,
                action: OutlinedButton(onPressed: _load, child: const Text('Повторить')),
              )
            : const Loading(),
      );
    }
    final ctx = s.ctxProject;
    final inQ = ctx?.items?.where((i) => i.pid == p.id).firstOrNull?.qty;
    final gallery = p.gallery.isNotEmpty ? p.gallery : (p.img != null ? [(big: p.img!, thumb: p.img!)] : <({String big, String thumb})>[]);
    final text = htmlToText(p.text);
    return Scaffold(
      appBar: AppBar(title: Text(p.brand.isNotEmpty ? p.brand : dirName[p.dir] ?? '')),
      bottomNavigationBar: p.canAdd
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    QtyBox(qty: qty, onMinus: () => setState(() => qty = qty > 1 ? qty - 1 : 1), onPlus: () => setState(() => qty += 1)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => addProduct(context, p, qty: qty),
                        icon: const Icon(Icons.add),
                        label: Text(ctx != null ? 'В проект «${ctx.name}»' : 'В проект', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: gallery.isEmpty
                ? Center(child: Icon(dirIcon(p.dir), size: 64, color: c.soft))
                : PageView.builder(
                    itemCount: gallery.length,
                    onPageChanged: (i) => setState(() => img = i),
                    itemBuilder: (_, i) => Padding(padding: const EdgeInsets.all(12), child: NetImg(gallery[i].big)),
                  ),
          ),
          if (gallery.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  gallery.length,
                  (i) => Container(
                    width: i == img ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: i == img ? c.g1 : c.line, borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          if (p.chain.isNotEmpty)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < p.chain.length; i++) ...[
                  if (i > 0) Text(' / ', style: TextStyle(color: c.muted)),
                  LinkBtn(p.chain[i].name, () {
                    context.read<CatalogState>().openSection(p.dir, p.chain[i].id);
                    s.goTab(3);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }),
                ],
              ],
            ),
          if (p.brand.isNotEmpty)
            Text(
              p.brand.toUpperCase(),
              style: TextStyle(fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.w700, color: c.gold),
            ),
          const SizedBox(height: 4),
          Text(p.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (p.article.isNotEmpty) Text('Артикул: ${p.article}', style: TextStyle(color: c.muted, fontSize: 12.5)),
              Chip2(dirName[p.dir] ?? p.dir, icon: dirIcon(p.dir)),
            ],
          ),
          const SizedBox(height: 12),
          if (p.price > 0)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Text(money(p.price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                if (p.old != null)
                  Text(
                    money(p.old),
                    style: TextStyle(color: c.muted, decoration: TextDecoration.lineThrough),
                  ),
                if (p.measure != 'шт') Text('/ ${p.measure}', style: TextStyle(color: c.muted)),
              ],
            )
          else
            Text('Цена по запросу', style: TextStyle(color: c.muted)),
          const SizedBox(height: 4),
          Text(
            p.qty > 0 ? 'В наличии: ${num2(p.qty)} ${p.measure}' : 'Под заказ — срок уточнит менеджер',
            style: TextStyle(color: p.qty > 0 ? c.ok : c.muted, fontWeight: p.qty > 0 ? FontWeight.w600 : FontWeight.w400),
          ),
          if (inQ != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Уже в проекте: ${num2(inQ)} ${p.measure}', style: TextStyle(color: c.goldInk)),
            ),
          if (p.url.isNotEmpty)
            Align(alignment: Alignment.centerLeft, child: LinkBtn('Открыть на pro-decor.kz', () => openUrl(Api.abs(p.url)!))),
          const SizedBox(height: 10),
          if (p.chars.isNotEmpty)
            Box(
              title: 'Характеристики',
              child: Column(
                children: p.chars
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(r.name, style: TextStyle(color: c.muted, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(r.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (text.isNotEmpty)
            Box(
              title: 'Описание',
              child: Text(text, style: const TextStyle(height: 1.45)),
            ),
        ],
      ),
    );
  }
}
