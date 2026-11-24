import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:prodecor/core/api.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';

const sorts = [
  ('default', 'По умолчанию'),
  ('price_asc', 'Сначала дешевле'),
  ('price_desc', 'Сначала дороже'),
  ('name', 'По названию'),
  ('new', 'Новинки'),
  ('stock', 'Сначала в наличии'),
];

/// Каталог: разделы, фильтр (умный фильтр сайта), сортировка, подгрузка страниц — как в кабинете
class CatalogState extends ChangeNotifier {
  final Store store;
  CatalogState(this.store) {
    // при выходе и входе под другим дизайнером — чистый каталог
    store.onAccountChange.add(reset);
  }

  String dir = 'light';
  int section = 0;
  bool inStock = false;
  String q = '';
  String sort = 'default';
  Map<String, String> ctl = {};
  List<Product> items = [];
  int page = 0, pages = 0, total = 0;
  bool loading = false;
  String error = '';
  final Map<String, List<Section>> tree = {};
  final Map<String, String> rootView = {};
  List<Facet> facets = [];
  String _key = '';
  Timer? _debounce;

  String get key => jsonEncode([dir, section, inStock, q, sort, ctl]);

  /// Корень каталога «карточками разделов»: раздел не выбран и нет поиска
  bool get rootCards => rootView[dir] == 'sections' && section == 0 && q.isEmpty;

  List<Section> children(int parent) {
    final l = (tree[dir] ?? []).where((s) => s.parent == parent).toList()
      ..sort((a, b) => a.sort != b.sort ? a.sort.compareTo(b.sort) : a.name.compareTo(b.name));
    return l;
  }

  List<Section> path(int id) {
    final map = {for (final s in tree[dir] ?? <Section>[]) s.id: s};
    final out = <Section>[];
    var s = map[id];
    while (s != null) {
      out.insert(0, s);
      s = map[s.parent];
    }
    return out;
  }

  void ensure() {
    if (_key != key || (items.isEmpty && !loading && page == 0 && !rootCards)) load();
    if (tree[dir] == null && !loading) load();
  }

  Future<void> load({bool more = false}) async {
    final k = key;
    if (!more) {
      items = [];
      page = 0;
      pages = 0;
      total = 0;
    }
    loading = true;
    error = '';
    _key = k;
    notifyListeners();
    try {
      if (tree[dir] == null) {
        final t = asMap(await store.call('catalog.tree', {'dir': dir}));
        tree[dir] = asList(t['list']).map(Section.from).toList();
        rootView[dir] = str(t['rootView']);
      }
      if (rootCards) {
        items = [];
        facets = [];
        return;
      }
      final d = asMap(
        await store.call('catalog.search', {
          'dir': dir,
          'section': section,
          'inStock': inStock,
          'q': q,
          'sort': sort,
          'ctl': ctl,
          'page': page + 1,
          'facets': !more,
        }),
      );
      if (_key != k) return; // пока грузили, условия сменились
      final got = asList(d['items']).map(Product.from).toList();
      items = more ? [...items, ...got] : got;
      page = toI(d['page']);
      pages = toI(d['pages']);
      total = toI(d['total']);
      if (!more) facets = asList(d['facets']).map(Facet.from).toList();
      final sec = toI(d['section']);
      if (sec != section) section = sec;
      _key = key;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      if (_key == key || error.isNotEmpty) {
        loading = false;
        notifyListeners();
      }
    }
  }

  /// Сбросить фильтр, сортировку, поиск и «в наличии» (при смене раздела/направления)
  void _clearQuery() {
    _debounce?.cancel();
    ctl = {};
    q = '';
    sort = 'default';
    inStock = false;
    facets = [];
  }

  /// Полный сброс каталога — смена аккаунта
  void reset() {
    _clearQuery();
    dir = 'light';
    section = 0;
    items = [];
    page = pages = total = 0;
    error = '';
    _key = '';
    loading = false;
    notifyListeners();
  }

  void setDir(String d) {
    if (dir == d) return;
    dir = d;
    section = 0;
    _clearQuery();
    load();
  }

  void setSection(int id) {
    if (id == section) return;
    section = id;
    _clearQuery();
    load();
  }

  void setSort(String v) {
    sort = v;
    load();
  }

  void setStock(bool v) {
    inStock = v;
    load();
  }

  void setQuery(String v) {
    q = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), load);
  }

  /// Значение фильтра: для списков 'Y', для диапазонов — число
  void setCtl(String k, String? v, {bool now = false}) {
    if (v == null || v.isEmpty) {
      ctl.remove(k);
    } else {
      ctl[k] = v;
    }
    ctl = Map.of(ctl);
    notifyListeners();
    _debounce?.cancel();
    if (now) {
      load();
    } else {
      _debounce = Timer(const Duration(milliseconds: 500), load);
    }
  }

  void resetFilter() {
    ctl = {};
    load();
  }

  /// Перейти в раздел из карточки товара (может быть другое направление)
  void openSection(String d, int id) {
    dir = d;
    section = id;
    _clearQuery();
    load();
  }

  Future<Product> product(int id) async => Product.from(asMap(await store.call('catalog.product', {'id': id})));
}
