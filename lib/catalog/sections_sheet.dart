import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/catalog/catalog_state.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/theme/theme.dart';

/// Дерево разделов каталога направления. Выбор раздела закрывает окно
/// (фильтр, сортировка и поиск при этом сбрасываются — см. CatalogState.setSection).
class SectionsSheet extends StatefulWidget {
  const SectionsSheet({super.key});
  @override
  State<SectionsSheet> createState() => _SectionsSheetState();
}

class _SectionsSheetState extends State<SectionsSheet> {
  /// раскрытые вручную (id) и свёрнутые вручную (-id) узлы
  final toggled = <int>{};

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogState>();
    final sel = cat.path(cat.section).map((x) => x.id).toSet();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Row(
            children: [
              Expanded(
                child: Text('Разделы · ${dirName[cat.dir] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [_tile(cat, null, 0, sel), ...cat.children(0).map((x) => _node(cat, x, 0, sel))],
          ),
        ),
      ],
    );
  }

  bool _open(int id, Set<int> sel) => toggled.contains(id) || (sel.contains(id) && !toggled.contains(-id));

  void _pick(CatalogState cat, int id) {
    cat.setSection(id);
    Navigator.pop(context);
  }

  Widget _tile(CatalogState cat, Section? x, int depth, Set<int> sel) {
    final c = context.pd;
    final id = x?.id ?? 0;
    final kids = x == null ? <Section>[] : cat.children(id);
    final isOpen = x != null && _open(id, sel);
    final active = cat.section == id;
    return InkWell(
      onTap: () => _pick(cat, id),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.only(left: depth * 14.0, top: 8, bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: kids.isEmpty
                  ? null
                  : InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => setState(() {
                        if (isOpen) {
                          toggled.remove(id);
                          toggled.add(-id);
                        } else {
                          toggled.add(id);
                          toggled.remove(-id);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(isOpen ? Icons.expand_more : Icons.chevron_right, size: 22, color: c.muted),
                      ),
                    ),
            ),
            Expanded(
              child: Text(
                x?.name ?? 'Все разделы',
                style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? c.goldInk : c.ink),
              ),
            ),
            if (x != null) Text(num2(x.count), style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
    );
  }

  Widget _node(CatalogState cat, Section x, int depth, Set<int> sel) {
    final kids = cat.children(x.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_tile(cat, x, depth, sel), if (_open(x.id, sel)) ...kids.map((k) => _node(cat, k, depth + 1, sel))],
    );
  }
}

/// Открыть окно разделов
void showSections(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const FractionallySizedBox(heightFactor: .85, child: SectionsSheet()),
);
