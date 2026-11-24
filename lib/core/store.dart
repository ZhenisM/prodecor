import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'format.dart';
import 'models.dart';

/// Состояние приложения: дизайнер, клиенты, проекты, открытый проект, каталог, справочники.
class Store extends ChangeNotifier {
  final api = Api();
  static const _secure = FlutterSecureStorage();
  static const _tokenKey = 'pd_token';

  bool booting = true;
  Me? me;
  bool loaded = false;
  List<Client> clients = [];
  List<Project> projects = [];
  final Map<int, Project> full = {}; // полные карточки проектов (с составом)
  History? history;
  bool historyLoading = false;
  List<Salon>? salons;
  String lang = 'ru';

  /// Вкладка нижнего меню: 0 главная, 1 проекты, 2 заявки, 3 каталог, 4 ещё
  int tab = 0;
  void goTab(int i) {
    tab = i;
    notifyListeners();
  }

  /// Проект, в который сейчас добавляются товары из каталога
  int? ctxProjectId;
  Project? get ctxProject => ctxProjectId == null ? null : full[ctxProjectId];

  /// Сессия закончилась (токен недействителен) — экран входа покажет сообщение
  String? signedOutReason;

  bool get active => me?.active ?? false;

  /* ---------- запуск и вход ---------- */

  Future<void> boot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      lang = prefs.getString('pd_lang') ?? 'ru';
      api.token = await _secure.read(key: _tokenKey);
      if (api.token != null && api.token!.isNotEmpty) {
        await loadAll();
      }
    } on ApiException catch (e) {
      if (e.code == 'auth') await _forget();
    } catch (_) {
      // нет сети при запуске — покажем вход/повтор
    }
    booting = false;
    notifyListeners();
  }

  Future<dynamic> call(String action, [Map<String, dynamic> data = const {}]) async {
    try {
      return await api.call(action, data);
    } on ApiException catch (e) {
      if (e.code == 'auth' && me != null) {
        await _forget();
        signedOutReason = 'Сессия завершена — войдите снова';
        notifyListeners();
      } else if (e.code == 'moderation') {
        unawaited(refreshMe());
      }
      rethrow;
    }
  }

  Future<void> loadAll() async {
    final d = asMap(await call('init'));
    me = Me(asMap(d['me']));
    clients = asList(d['clients']).map(Client.from).toList();
    projects = asList(d['projects']).map(Project.from).toList();
    loaded = true;
    if (me!.lang != lang) await setLang(me!.lang, save: false);
    notifyListeners();
  }

  Future<void> refreshMe() async {
    try {
      me = Me(asMap(await api.call('me')));
      notifyListeners();
    } catch (_) {}
  }

  /// Ответ входа: {needCode, email} или данные дизайнера с appToken
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final d = asMap(await api.call('auth.login', {'phone': phone, 'password': password, 'remember': true, 'device': _device}));
    if (d['needCode'] == true) return d;
    await _signedIn(d);
    return d;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async => asMap(await api.call('auth.register', {...data, 'lang': lang}));

  Future<void> confirm(String phone, String code) async =>
      _signedIn(asMap(await api.call('auth.confirm', {'phone': phone, 'code': code, 'device': _device})));

  Future<String> resend(String phone, String purpose) async =>
      str(asMap(await api.call('auth.resend', {'phone': phone, 'purpose': purpose}))['email']);

  Future<void> forgot(String phone) async => api.call('auth.forgot', {'phone': phone});

  Future<void> reset(String phone, String code, String p1, String p2) async =>
      _signedIn(asMap(await api.call('auth.reset', {'phone': phone, 'code': code, 'password': p1, 'password2': p2, 'device': _device})));

  String get _device => '${defaultTargetPlatform.name} app';

  Future<void> _signedIn(Map<String, dynamic> d) async {
    final t = str(d['appToken']);
    if (t.isEmpty) throw ApiException('Сервер не выдал ключ входа для приложения. Обновите кабинет на сайте.');
    api.token = t;
    await _secure.write(key: _tokenKey, value: t);
    signedOutReason = null;
    await loadAll();
  }

  Future<void> logout() async {
    try {
      await api.call('auth.logout');
    } catch (_) {}
    await _forget();
    notifyListeners();
  }

  Future<void> _forget() async {
    api.token = null;
    await _secure.delete(key: _tokenKey);
    me = null;
    loaded = false;
    clients = [];
    projects = [];
    full.clear();
    history = null;
    salons = null;
    ctxProjectId = null;
    tab = 0;
  }

  Future<void> setLang(String v, {bool save = true}) async {
    lang = v;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString('pd_lang', v);
    } catch (_) {}
    if (save && me != null) {
      try {
        me = Me(asMap(await api.call('profile.prefs', {'lang': v})));
      } catch (_) {}
    }
  }

  Future<void> setPref(String key) async {
    if (me == null) return;
    me!.raw['prefs'] = {...asMap(me!.raw['prefs']), key: true};
    notifyListeners();
    try {
      await api.call('profile.prefs', {key: true});
    } catch (_) {}
  }

  /* ---------- клиенты ---------- */

  Client? client(int id) {
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Возвращает клиента и признак «такой телефон уже был»
  Future<(Client, bool)> saveClient(int? id, Map<String, dynamic> data) async {
    if (id != null) {
      final c = Client.from(asMap(await call('clients.update', {'id': id, ...data}))['client']);
      clients = clients.map((x) => x.id == c.id ? c : x).toList();
      notifyListeners();
      return (c, false);
    }
    final d = asMap(await call('clients.create', data));
    final c = Client.from(d['client']);
    final existing = d['existing'] == true;
    if (!existing) clients = [...clients, c];
    notifyListeners();
    return (c, existing);
  }

  /* ---------- проекты ---------- */

  Project? summary(int id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Project upsert(Object? data) {
    final p = Project.from(asMap(data));
    final i = projects.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      projects[i] = p;
    } else {
      projects.insert(0, p);
    }
    if (p.items != null) full[p.id] = p;
    notifyListeners();
    return p;
  }

  Future<Project> loadProject(int id) async => upsert(await call('projects.get', {'id': id}));

  Future<Project> createProject(Map<String, dynamic> data) async => upsert(await call('projects.create', data));

  Future<Project> updateProject(int id, Map<String, dynamic> data) async => upsert(await call('projects.update', {'id': id, ...data}));

  Future<void> deleteProject(int id) async {
    await call('projects.delete', {'id': id});
    projects.removeWhere((p) => p.id == id);
    full.remove(id);
    if (ctxProjectId == id) ctxProjectId = null;
    notifyListeners();
  }

  Future<Project> addItem(int projectId, int productId, double qty) async =>
      upsert(await call('projects.addItem', {'id': projectId, 'productId': productId, 'qty': qty}));

  Future<Project> setQty(int projectId, int bid, double qty) async =>
      upsert(await call('projects.setQty', {'id': projectId, 'bid': bid, 'qty': qty}));

  Future<Project> removeItem(int projectId, int bid) async => upsert(await call('projects.removeItem', {'id': projectId, 'bid': bid}));

  Future<Project> send(int projectId, String comment) async => upsert(await call('projects.send', {'id': projectId, 'comment': comment}));

  /// Обновить список проектов (статусы заявок из Битрикс24)
  Future<void> refreshProjects() async {
    final d = await call('init');
    final m = asMap(d);
    me = Me(asMap(m['me']));
    clients = asList(m['clients']).map(Client.from).toList();
    projects = asList(m['projects']).map(Project.from).toList();
    notifyListeners();
  }

  /* ---------- справочники ---------- */

  Future<void> loadHistory({bool fresh = false}) async {
    if (historyLoading) return;
    historyLoading = true;
    notifyListeners();
    try {
      history = History.from(await call('history.list', {'fresh': fresh ? 1 : 0}));
    } on ApiException catch (e) {
      history = History([], [], e.message);
    }
    historyLoading = false;
    notifyListeners();
  }

  Future<void> loadSalons() async {
    try {
      salons = asList(await call('salons.list')).map(Salon.new).toList();
    } catch (_) {
      salons = [];
    }
    notifyListeners();
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    me = Me(asMap(await call('profile.save', data)));
    notifyListeners();
  }

  Future<void> changePassword(String old, String p1, String p2) async =>
      call('profile.password', {'old': old, 'password': p1, 'password2': p2});

  Future<void> support(String topic, String text) async => call('support.send', {'topic': topic, 'text': text});
}
