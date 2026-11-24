import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/i18n.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/theme/theme.dart';
import 'package:prodecor/common/widgets.dart';
import 'package:prodecor/auth/auth_screen.dart';
import 'package:prodecor/bonuses/bonuses_screen.dart';
import 'package:prodecor/pages/how_screen.dart';
import 'package:prodecor/orders/orders_screen.dart';
import 'package:prodecor/profile/profile_screen.dart';
import 'package:prodecor/pages/stores_screen.dart';
import 'package:prodecor/pages/support_screen.dart';

/// «Ещё»: Мои заказы, Бонусы, Магазины, Профиль, Как это работает, Поддержка, язык, выход
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = context.pd;
    final me = s.me!;
    final l = s.lang;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    Widget item(IconData i, String key, Widget page) => ListTile(
      leading: Icon(i, color: c.ink),
      title: Text(tr(l, key), style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: c.muted),
      onTap: () => push(page),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(l, 'more')),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: LangSwitch())],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Box(
            child: InkWell(
              onTap: () => push(const ProfileScreen()),
              child: Row(
                children: [
                  Avatar(shortName(me.name), size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shortName(me.name), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${tr(l, 'designer')} · ${me.phone}', style: TextStyle(color: c.muted, fontSize: 12.5)),
                        const SizedBox(height: 4),
                        me.active ? const Pill('Активен', 'ok') : const Pill('На модерации', 'ready'),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.muted),
                ],
              ),
            ),
          ),
          Box(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                if (s.active) ...[
                  item(Icons.inventory_2_outlined, 'orders', const OrdersScreen()),
                  item(Icons.card_giftcard, 'bonuses', const BonusesScreen()),
                  item(Icons.storefront_outlined, 'stores', const StoresScreen()),
                ],
                item(Icons.person_outline, 'profile', const ProfileScreen()),
                item(Icons.auto_awesome_outlined, 'how', const HowScreen()),
                item(Icons.notifications_none, 'support', const SupportScreen()),
              ],
            ),
          ),
          if (s.active) const ManagersBox(),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Выйти из аккаунта?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(l, 'logout'))),
                  ],
                ),
              );
              if (ok == true && context.mounted) await context.read<Store>().logout();
            },
            icon: const Icon(Icons.logout),
            label: Text(tr(l, 'logout')),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('PRODECOR · pro-decor.kz', style: TextStyle(color: c.soft, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
