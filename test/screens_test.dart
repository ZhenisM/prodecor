import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:prodecor/core/catalog.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/screens/auth_screen.dart';
import 'package:prodecor/screens/bonuses_screen.dart';
import 'package:prodecor/screens/how_screen.dart';
import 'package:prodecor/screens/orders_screen.dart';
import 'package:prodecor/screens/profile_screen.dart';
import 'package:prodecor/screens/project_screen.dart';
import 'package:prodecor/screens/shell.dart';
import 'package:prodecor/screens/support_screen.dart';
import 'package:prodecor/theme.dart';

Store fakeStore({bool active = true}) {
  final s = Store();
  s.booting = false;
  s.loaded = true;
  s.me = Me({
    'id': 1, 'name': 'Асадчая Ольга Сергеевна', 'firstName': 'Ольга', 'phone': '+7 701 123 45 67', 'email': 'o@mail.kz',
    'city': 'Алматы', 'inst': '', 'studio': '', 'status': active ? 'active' : 'moderation',
    'managers': {'light': {'name': 'Ушурова Зарина Шамшидиновна', 'phone': '77011112233'}, 'paint': {'name': 'Жаппаров Амир', 'phone': '77010365000'}, 'main': {'name': 'Жаппаров Амир', 'phone': '77010365000'}},
    'prefs': {}, 'lang': 'ru',
  });
  s.clients = [Client.from({'id': 5, 'name': 'Евгений Медведь', 'phone': '+7 701 000 00 00', 'city': 'Алматы'})];
  final full = {
    'id': 10, 'clientId': 5, 'name': 'Квартира в ЖК Меркур Град с длинным названием', 'type': 'Квартира', 'area': 84.5, 'address': 'Алматы, Абая 1',
    'status': 'ready', 'number': '120125', 'sum': 176600, 'count': 2, 'dir': 'light', 'dirs': ['light'], 'created': '2026-11-19',
    'items': [
      {'bid': 1, 'pid': 100, 'name': 'Подвесной светильник Maytoni Modern с очень длинным названием товара', 'dir': 'light', 'brand': 'Maytoni', 'article': 'MOD123-PL-01-G', 'price': 88300, 'qty': 2, 'measure': 'шт'},
    ],
  };
  s.upsert(full);
  s.upsert({'id': 11, 'clientId': 5, 'name': 'Дом за городом', 'type': 'Дом', 'status': 'work', 'number': '120082', 'sum': 70790, 'count': 3, 'dir': 'paint', 'sentAt': '2026-11-19',
    'deal': {'key': 'inwork', 'stageName': 'ПОТРЕБНОСТЬ ВЫЯВЛЕНА', 'sum': 70790}});
  s.history = History.from({
    'projects': [{'dealId': 1, 'title': 'Нурлан Галия 8 озер - От 100–200 м²', 'stageName': 'Проект у дизайнера / подписан договор с заказчиком', 'state': 'open', 'created': '2026-06-03', 'dirs': [], 'orders': [], 'ordersSum': 0, 'paidSum': 0}],
    'orders': [{'id': 1, 'number': '112142', 'dir': 'light', 'date': '2026-10-06', 'sum': 65520, 'paid': false, 'statusName': 'Выполнен'}],
    'error': '',
  });
  s.salons = [];
  return s;
}

Future<void> pump(WidgetTester t, Store s, Widget w) async {
  final orig = FlutterError.onError;
  FlutterError.onError = (d) {
    FlutterError.dumpErrorToConsole(d, forceReport: true);
    orig?.call(d);
  };
  t.view.physicalSize = const Size(360 * 3, 760 * 3);
  t.view.devicePixelRatio = 3;
  final cat = CatalogState(s);
  cat.tree['light'] = [Section.from({'id': 1, 'parent': 0, 'name': 'Люстры', 'count': 1200}), Section.from({'id': 2, 'parent': 0, 'name': 'Бра и настенные светильники', 'count': 340})];
  cat.rootView['light'] = 'sections';
  if (s.tab == 3 && s.ctxProjectId != null) {
    cat.section = 1;
    cat.total = 2;
    cat.items = [
      Product.from({'id': 100, 'name': 'Подвесной светильник Maytoni Modern с длинным названием', 'brand': 'Maytoni', 'price': 88300, 'old': 99000, 'qty': 5, 'dir': 'light'}),
      Product.from({'id': 101, 'name': 'Бра', 'price': 0, 'qty': 0, 'dir': 'light'}),
    ];
    cat.facets = [Facet.from({'id': 'p', 'name': 'Цена', 'type': 'range', 'cMin': 'a', 'cMax': 'b', 'min': 100, 'max': 900000})];
    cat.ctl = {'a': '1000'};
  }
  await t.pumpWidget(MultiProvider(
    providers: [ChangeNotifierProvider.value(value: s), ChangeNotifierProvider.value(value: cat)],
    child: MaterialApp(theme: buildTheme(Brightness.light), home: w),
  ));
  await t.pump(const Duration(milliseconds: 100));
  FlutterError.onError = orig;
}

void main() {
  useGoogleFonts = false;
  final screens = <String, Widget Function()>{
    'shell': () => const Shell(),
    'project': () => const ProjectScreen(id: 10),
    'orders': () => const OrdersScreen(),
    'bonuses': () => const BonusesScreen(),
    'how': () => const HowScreen(),
    'support': () => const SupportScreen(),
    'profile': () => const ProfileScreen(),
    'auth': () => const AuthScreen(),
  };
  for (final e in screens.entries) {
    testWidgets('screen ${e.key}', (t) async {
      final s = fakeStore();
      await pump(t, s, e.value());
      final ex = t.takeException();
      if (ex is FlutterError) debugPrint('ERR ${ex.toStringDeep()}');
      expect(ex, isNull);
    });
  }
  for (var tab = 0; tab < 5; tab++) {
    testWidgets('tab $tab', (t) async {
      final s = fakeStore()..tab = tab;
      await pump(t, s, const Shell());
      final ex = t.takeException();
      if (ex is FlutterError) debugPrint('ERR ${ex.toStringDeep()}');
      expect(ex, isNull);
    });
  }
  testWidgets('catalog items with project', (t) async {
    final s = fakeStore()
      ..tab = 3
      ..ctxProjectId = 10;
    await pump(t, s, const Shell());
    final ex = t.takeException();
    expect(ex, isNull);
    expect(find.text('Готово'), findsOneWidget);
  });
  testWidgets('moderation', (t) async {
    await pump(t, fakeStore(active: false), const Shell());
    final ex = t.takeException();
      if (ex is FlutterError) debugPrint('ERR ${ex.toStringDeep()}');
      expect(ex, isNull);
  });
}
