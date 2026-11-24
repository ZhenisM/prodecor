import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/catalog/catalog_state.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/theme/theme.dart';

/// Фильтр раздела (умный фильтр сайта): диапазоны и списки значений
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});
  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  final open = <String, bool>{};
  final more = <String>{};
  final fq = <String, String>{};

  bool _facetOpen(CatalogState cat, Facet f) =>
      open[f.id] ?? (f.isRange || f.expanded || f.values.any((v) => cat.ctl[v.c] != null) || cat.facets.indexOf(f) < 3);

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogState>();
    final c = context.pd;
    // списки, где все значения недоступны, не показываем (как «Ничего не найдено» в пустом блоке)
    final facets = cat.facets.where((f) => f.isRange || f.values.any((v) => !v.disabled || cat.ctl[v.c] != null)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text('Фильтр', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              if (cat.ctl.isNotEmpty) LinkBtn('Сбросить', cat.resetFilter),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              if (facets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(cat.loading ? 'Загрузка…' : 'Нет параметров для фильтра', style: TextStyle(color: c.muted)),
                ),
              ...facets.map((f) => _facet(cat, f)),
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

  Widget _facet(CatalogState cat, Facet f) {
    final c = context.pd;
    final isOpen = _facetOpen(cat, f);
    Widget body;
    if (f.isRange) {
      body = Row(
        children: [
          Expanded(
            child: RangeField(ctlKey: f.cMin, hint: 'от ${num2(f.min)}', cat: cat),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RangeField(ctlKey: f.cMax, hint: 'до ${num2(f.max)}', cat: cat),
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

/// Поле «от / до» диапазона
class RangeField extends StatefulWidget {
  final String ctlKey, hint;
  final CatalogState cat;
  const RangeField({super.key, required this.ctlKey, required this.hint, required this.cat});
  @override
  State<RangeField> createState() => _RangeFieldState();
}

class _RangeFieldState extends State<RangeField> {
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

/// Открыть окно фильтра
void showFilter(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const FractionallySizedBox(heightFactor: .9, child: FilterSheet()),
);
