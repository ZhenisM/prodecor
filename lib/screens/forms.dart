import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'project_screen.dart';

/// Клиент: создать или изменить. После создания — сразу форма проекта под него.
Future<void> clientForm(BuildContext context, {Client? client}) async {
  final created = await sheet<Client>(context, _ClientForm(client: client));
  if (created != null && client == null && context.mounted) {
    await projectForm(context, clientId: created.id);
  }
}

class _ClientForm extends StatefulWidget {
  final Client? client;
  const _ClientForm({this.client});
  @override
  State<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<_ClientForm> {
  late final name = TextEditingController(text: widget.client?.name ?? '');
  late final phone = PhoneController(widget.client?.phone ?? '+7 7');
  late final city = TextEditingController(text: widget.client?.city ?? context.read<Store>().me?.city ?? '');
  late final note = TextEditingController(text: widget.client?.comment ?? '');

  @override
  void dispose() {
    for (final c in [name, phone, city, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.read<Store>();
    final r = await run(
      context,
      () => s.saveClient(widget.client?.id, {
        'name': name.text.trim(),
        'phone': phone.text,
        'city': city.text.trim(),
        'comment': note.text.trim(),
      }),
    );
    if (r == null || !mounted) return;
    final (c, existing) = r;
    toast(
      context,
      widget.client != null ? 'Клиент сохранён' : (existing ? 'Клиент с таким телефоном уже есть — выбрали его' : 'Клиент добавлен'),
    );
    Navigator.pop(context, c);
  }

  @override
  Widget build(BuildContext context) => SheetBody(
    title: widget.client != null ? 'Клиент' : 'Новый клиент',
    children: [
      field(name, 'ФИО клиента', autofill: const [AutofillHints.name]),
      field(phone, 'Телефон', kb: TextInputType.phone),
      field(city, 'Город'),
      field(note, 'Комментарий'),
      FilledButton(onPressed: _save, child: Text(widget.client != null ? 'Сохранить' : 'Добавить клиента')),
    ],
  );
}

/// Проект: создать (клиент, направление) или изменить. Новый проект сразу открывается.
Future<void> projectForm(BuildContext context, {int? clientId, String? dir, Project? edit}) async {
  final s = context.read<Store>();
  if (edit == null && s.clients.isEmpty) {
    final add = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сначала добавьте клиента'),
        content: const Text('Проект создаётся под клиента.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Добавить клиента')),
        ],
      ),
    );
    if (add == true && context.mounted) await clientForm(context);
    return;
  }
  final p = await sheet<Project>(context, _ProjectForm(clientId: clientId, dir: dir, edit: edit));
  if (p != null && edit == null && context.mounted) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectScreen(id: p.id)));
  }
}

class _ProjectForm extends StatefulWidget {
  final int? clientId;
  final String? dir;
  final Project? edit;
  const _ProjectForm({this.clientId, this.dir, this.edit});
  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  late int? clientId = widget.clientId;
  late String? dir = widget.dir == 'light' || widget.dir == 'paint' ? widget.dir : null;
  late String type = widget.edit?.type.isNotEmpty == true ? widget.edit!.type : 'Квартира';
  late final name = TextEditingController(text: widget.edit?.name ?? '');
  late final area = TextEditingController(text: (widget.edit?.area ?? 0) > 0 ? num2(widget.edit!.area).replaceAll(' ', '') : '');
  late final address = TextEditingController(text: widget.edit?.address ?? '');
  late final budget = TextEditingController(text: widget.edit?.budget ?? '');
  late final deadline = TextEditingController(text: widget.edit?.deadline ?? '');
  late final note = TextEditingController(text: widget.edit?.note ?? '');

  @override
  void dispose() {
    for (final c in [name, area, address, budget, deadline, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.read<Store>();
    final data = {
      'name': name.text.trim(),
      'type': type,
      'area': area.text.trim().replaceAll(',', '.'),
      'address': address.text.trim(),
      'budget': budget.text.trim(),
      'deadline': deadline.text.trim(),
      'note': note.text.trim(),
    };
    Project? p;
    if (widget.edit != null) {
      p = await run(context, () => s.updateProject(widget.edit!.id, data));
      if (p != null && mounted) toast(context, 'Проект сохранён');
    } else {
      final cid = clientId ?? (s.clients.isNotEmpty ? s.clients.last.id : 0);
      if (dir == null) {
        toast(context, 'Выберите направление: свет или краски');
        return;
      }
      p = await run(context, () => s.createProject({'clientId': cid, 'dir': dir, ...data}));
      if (p != null && mounted) toast(context, 'Проект создан');
    }
    if (p != null && mounted) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final cl = s.clients.reversed.toList();
    final edit = widget.edit;
    clientId ??= cl.isNotEmpty ? cl.first.id : null;
    return SheetBody(
      title: edit != null ? 'Проект' : 'Новый проект',
      children: [
        if (edit == null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<int>(
              initialValue: clientId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Клиент'),
              items: cl
                  .map(
                    (x) => DropdownMenuItem(
                      value: x.id,
                      child: Text('${x.name} · ${x.phone}', overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => clientId = v),
            ),
          ),
          const Text('Направление', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'light', icon: Icon(Icons.lightbulb_outline), label: Text('Свет')),
              ButtonSegment(value: 'paint', icon: Icon(Icons.format_paint_outlined), label: Text('Краски')),
            ],
            selected: dir == null ? <String>{} : {dir!},
            onSelectionChanged: (v) => setState(() => dir = v.isEmpty ? null : v.first),
          ),
          const SizedBox(height: 6),
          Text(
            'В проект можно будет добавлять товары только этого направления. Свет оформляется через offline.svet.kz, краски — через offline.centr-krasok.kz.',
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          const SizedBox(height: 14),
        ] else if (edit.dir != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Направление: ${dirName[edit.dir]} — меняется только созданием нового проекта',
              style: TextStyle(fontSize: 12.5, color: c.muted),
            ),
          ),
        field(name, 'Название', hint: 'Квартира в ЖК …'),
        dropdown('Тип помещения', type, ptypes, (v) => setState(() => type = v)),
        field(area, 'Площадь, м²', kb: const TextInputType.numberWithOptions(decimal: true)),
        field(address, 'Адрес'),
        field(budget, 'Бюджет на материалы', hint: 'например, 3 млн ₸'),
        field(deadline, 'Сроки закупки', hint: 'например, декабрь'),
        field(note, 'Стиль и пожелания', lines: 3),
        FilledButton(onPressed: _save, child: Text(edit != null ? 'Сохранить' : 'Создать проект')),
      ],
    );
  }
}
