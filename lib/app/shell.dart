import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/common/i18n.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/catalog/catalog_screen.dart';
import 'package:prodecor/customer/clients_screen.dart';
import 'package:prodecor/dashboard/dashboard_screen.dart';
import 'package:prodecor/profile/more_screen.dart';
import 'package:prodecor/requests/requests_screen.dart';

/// Нижнее меню: Главная · Проекты · Заявки · Каталог · Ещё.
/// Пока профиль на модерации — только Главная и Ещё (профиль, справка, поддержка).
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final active = s.active;
    final l = s.lang;
    final tabs = active
        ? <(IconData, IconData, String, Widget)>[
            (Icons.grid_view_outlined, Icons.grid_view_rounded, tr(l, 'dash'), const DashboardScreen()),
            (Icons.folder_outlined, Icons.folder, tr(l, 'projects'), const ClientsScreen()),
            (Icons.send_outlined, Icons.send, tr(l, 'requests'), const RequestsScreen()),
            (Icons.inventory_2_outlined, Icons.inventory_2, tr(l, 'catalog'), const CatalogScreen()),
            (Icons.menu, Icons.menu, tr(l, 'more'), const MoreScreen()),
          ]
        : <(IconData, IconData, String, Widget)>[
            (Icons.grid_view_outlined, Icons.grid_view_rounded, tr(l, 'dash'), const DashboardScreen()),
            (Icons.menu, Icons.menu, tr(l, 'more'), const MoreScreen()),
          ];
    // на модерации вкладка «Ещё» — вторая
    var idx = s.tab;
    if (!active) idx = s.tab == 4 ? 1 : 0;
    if (idx >= tabs.length) idx = 0;
    return Scaffold(
      body: IndexedStack(index: idx, children: tabs.map((t) => t.$4).toList()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => s.goTab(active ? i : (i == 1 ? 4 : 0)),
        destinations: tabs.map((t) => NavigationDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: t.$3)).toList(),
      ),
    );
  }
}
