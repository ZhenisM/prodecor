import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/catalog.dart';
import 'core/store.dart';
import 'screens/auth_screen.dart';
import 'screens/shell.dart';
import 'theme.dart';
import 'widgets/common.dart';

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
