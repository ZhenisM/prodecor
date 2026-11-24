import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/catalog/catalog_actions.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/theme/theme.dart';

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
