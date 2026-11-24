import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:prodecor/catalog/catalog_state.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/auth/auth_screen.dart';
import 'package:prodecor/app/shell.dart';
import 'package:prodecor/theme/theme.dart';
import 'package:prodecor/common/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = Store()..boot();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider(create: (_) => CatalogState(store)),
      ],
      child: const ProdecorApp(),
    ),
  );
}

class ProdecorApp extends StatelessWidget {
  const ProdecorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRODECOR',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const Root(),
    );
  }
}

/// Загрузка → вход → кабинет
class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    if (s.booting) {
      return const Scaffold(body: Center(child: PdLogo(size: 64)));
    }
    if (s.me == null || !s.loaded) return const AuthScreen();
    return const Shell();
  }
}
