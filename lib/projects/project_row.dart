import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/projects/project_screen.dart';

/// Строка проекта: название, клиент, объект, статус, сумма
class ProjectRow extends StatelessWidget {
  final Project p;
  final bool showClient;
  const ProjectRow(this.p, {super.key, this.showClient = true});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final st = Project.statuses[p.status] ?? Project.statuses['work']!;
    final cl = s.client(p.clientId);
    final parts = <String>[
      if (showClient && cl != null) cl.name,
      if (!showClient && p.dir != null) dirName[p.dir]!,
      p.type + (p.area > 0 ? ', ${num2(p.area)} м²' : ''),
      if (!showClient) '${p.count} поз.',
    ];
    return RowX(
      title: Text(p.name),
      subtitle: Text(parts.where((x) => x.isNotEmpty).join(' · ')),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Pill(st.$1, st.$2),
          const SizedBox(height: 4),
          Text(money(p.sum), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      onTap: () => openProject(context, p.id),
    );
  }
}

void openProject(BuildContext context, int id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectScreen(id: id)));
