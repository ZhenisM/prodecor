import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Шоурумы: салоны, где можно показать клиенту образцы
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});
  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<Store>();
      if (s.salons == null) s.loadSalons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final list = s.salons;
    return Scaffold(
      appBar: AppBar(title: Text(tr(s.lang, 'stores'))),
      body: list == null
          ? const Loading()
          : RefreshIndicator(
              onRefresh: s.loadSalons,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Text('Салоны, где можно показать клиенту образцы и материалы.', style: TextStyle(color: c.muted)),
                  const SizedBox(height: 12),
                  if (list.isEmpty)
                    const Box(
                      child: EmptyState(Icons.storefront_outlined, 'Салоны скоро появятся', 'Список шоурумов заполняет администратор.'),
                    ),
                  ...list.map(
                    (x) => Box(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (x.img != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: NetImg(x.img, h: 170, fit: BoxFit.cover),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [x.city, x.dirs].where((e) => e.isNotEmpty).join(' · ').toUpperCase(),
                                  style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: c.gold, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(x.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                                if (x.address.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('📍 ${x.address}')),
                                if (x.hours.isNotEmpty) Text('🕑 ${x.hours}', style: TextStyle(color: c.muted, fontSize: 12.5)),
                                if (x.text.isNotEmpty) Text(x.text, style: TextStyle(color: c.muted, fontSize: 12.5)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (x.phone.isNotEmpty)
                                      OutlinedButton.icon(
                                        onPressed: () => openUrl('tel:${x.phone.replaceAll(RegExp(r'[^\d+]'), '')}'),
                                        icon: const Icon(Icons.phone_outlined, size: 16),
                                        label: Text(x.phone),
                                      ),
                                    if (x.whatsapp.isNotEmpty)
                                      FilledButton.tonal(
                                        style: FilledButton.styleFrom(backgroundColor: c.goldTint, foregroundColor: c.goldInk),
                                        onPressed: () => openUrl('https://wa.me/${digits(x.whatsapp)}'),
                                        child: const Text('WhatsApp'),
                                      ),
                                    if (x.mapUrl.isNotEmpty)
                                      OutlinedButton.icon(
                                        onPressed: () => openUrl(x.mapUrl),
                                        icon: const Icon(Icons.place_outlined, size: 16),
                                        label: const Text('На карте'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
