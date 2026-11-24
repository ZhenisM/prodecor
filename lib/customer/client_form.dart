import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/customer/project_form.dart';

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
