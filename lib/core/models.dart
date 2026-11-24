import 'api.dart';
import 'format.dart';

typedef J = Map<String, dynamic>;

J asMap(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<J> asList(Object? v) => v is List ? v.map(asMap).toList() : <J>[];

class Manager {
  final String name, phone;
  const Manager(this.name, this.phone);
  factory Manager.from(Object? v) {
    final m = asMap(v);
    return Manager(str(m['name']), str(m['phone']));
  }
  bool get has => name.isNotEmpty;
}

class Me {
  final J raw;
  Me(this.raw);
  int get id => toI(raw['id']);
  String get name => str(raw['name']);
  String get firstName => str(raw['firstName']);
  String get phone => str(raw['phone']);
  String get email => str(raw['email']);
  String get city => str(raw['city']);
  String get inst => str(raw['inst']);
  String get studio => str(raw['studio']);
  String get spec => str(raw['spec']);
  String get portfolio => str(raw['portfolio']);
  String get iin => str(raw['iin']);
  String get lang => str(raw['lang']) == 'kz' ? 'kz' : 'ru';
  bool get active => raw['status'] == 'active';
  bool get stepsHidden => asMap(raw['prefs'])['stepsHidden'] == true;
  bool get hintOff => asMap(raw['prefs'])['hintOff'] == true;
  Manager get main {
    final ms = asMap(raw['managers']);
    return Manager.from(ms['main'] ?? raw['manager']);
  }

  Manager get light => _m('light');
  Manager get paint => _m('paint');
  Manager _m(String k) {
    final ms = asMap(raw['managers']);
    final x = Manager.from(ms[k]);
    return x.has ? x : main;
  }

  /// Менеджеры для направлений (без повторов)
  List<Manager> forDirs(List<String> dirs) {
    final out = <Manager>[];
    for (final d in dirs) {
      final m = d == 'light' ? light : (d == 'paint' ? paint : main);
      if (m.has && !out.any((o) => o.name == m.name)) out.add(m);
    }
    return out.isEmpty ? [main] : out;
  }
}

class Client {
  final int id;
  final String name, phone, city, comment, created;
  Client(this.id, this.name, this.phone, this.city, this.comment, this.created);
  factory Client.from(Object? v) {
    final m = asMap(v);
    return Client(toI(m['id']), str(m['name']), str(m['phone']), str(m['city']), str(m['comment']), str(m['created']));
  }
}

/// Состояние сделки менеджера в Битрикс24 по заявке
class Deal {
  final String key, stageName;
  final double sum;
  Deal(this.key, this.stageName, this.sum);
  static Deal? from(Object? v) {
    if (v is! Map) return null;
    final m = asMap(v);
    return Deal(str(m['key']), str(m['stageName']), toD(m['sum']));
  }
}

class Item {
  final int bid, pid;
  final String name, brand, article, measure, url;
  final String? dir, img;
  double qty, price;
  Item.from(J m)
    : bid = toI(m['bid']),
      pid = toI(m['pid']),
      name = str(m['name']),
      brand = str(m['brand']),
      article = str(m['article']),
      measure = str(m['measure']).isEmpty ? 'шт' : str(m['measure']),
      url = str(m['url']),
      dir = m['dir']?.toString(),
      img = Api.abs(m['img']),
      qty = toD(m['qty']),
      price = toD(m['price']);
}

class Project {
  final int id, clientId, orderId;
  final String name, type, address, budget, deadline, note, created, sentAt, status, number, comment;
  final double area, sum;
  final int count;
  final String? dir;
  final List<String> dirs;
  final Deal? deal;
  final List<Item>? items; // есть только у полной карточки

  Project.from(J m)
    : id = toI(m['id']),
      clientId = toI(m['clientId']),
      orderId = toI(m['orderId']),
      name = str(m['name']),
      type = str(m['type']),
      address = str(m['address']),
      budget = str(m['budget']),
      deadline = str(m['deadline']),
      note = str(m['note']),
      created = str(m['created']),
      sentAt = str(m['sentAt']),
      status = str(m['status']),
      number = str(m['number']),
      comment = str(m['comment']),
      area = toD(m['area']),
      sum = toD(m['sum']),
      count = toI(m['count']),
      dir = (m['dir'] == 'light' || m['dir'] == 'paint') ? m['dir'] as String : null,
      dirs = (m['dirs'] is List) ? (m['dirs'] as List).map((e) => e.toString()).toList() : <String>[],
      deal = Deal.from(m['deal']),
      items = m['items'] is List ? asList(m['items']).map(Item.from).toList() : null;

  bool get editable => status == 'draft' || status == 'ready';
  List<String> get dirList => dir != null ? [dir!] : dirs;
  double get itemsSum => (items ?? []).fold<double>(0.0, (a, i) => a + i.price * i.qty);

  /// Этап заявки по сделке Б24: sent / inwork / paid / shipped / sold / lost
  String get stage => (deal != null && stages.containsKey(deal!.key)) ? deal!.key : 'sent';

  static const stages = {
    'sent': ('Отправлена', 'ready', 1),
    'inwork': ('В работе', 'work', 2),
    'paid': ('Оплачен', 'work', 3),
    'shipped': ('Передан на доставку', 'work', 4),
    'sold': ('Продано', 'ok', 5),
    'lost': ('Отменена', 'bad', 0),
  };
  static const statuses = {
    'draft': ('Черновик', 'draft'),
    'ready': ('К отправке', 'ready'),
    'work': ('В работе', 'work'),
    'sold': ('Продан', 'ok'),
  };
}

class Section {
  final int id, parent, sort, count;
  final String name;
  final String? img;
  Section.from(J m)
    : id = toI(m['id']),
      parent = toI(m['parent']),
      sort = toI(m['sort']),
      count = toI(m['count']),
      name = str(m['name']),
      img = Api.abs(m['img']);
}

class FacetValue {
  final String c, v;
  final int? n;
  final bool disabled;
  FacetValue.from(J m) : c = str(m['c']), v = str(m['v']), n = m['n'] == null ? null : toI(m['n']), disabled = m['disabled'] == true;
}

class Facet {
  final String id, name, type, cMin, cMax;
  final double min, max;
  final bool expanded;
  final List<FacetValue> values;
  Facet.from(J m)
    : id = str(m['id']),
      name = str(m['name']),
      type = str(m['type']),
      cMin = str(m['cMin']),
      cMax = str(m['cMax']),
      min = toD(m['min']),
      max = toD(m['max']),
      expanded = m['expanded'] == true,
      values = asList(m['values']).map(FacetValue.from).toList();
  bool get isRange => type == 'range';
}

class Product {
  final int id;
  final String name, brand, article, measure, dir, url, text;
  final double price, qty;
  final double? old;
  final bool sku;
  final String? img;
  final List<({String big, String thumb})> gallery;
  final List<({int id, String name})> chain;
  final List<({String name, String value})> chars;

  Product.from(J m)
    : id = toI(m['id']),
      name = str(m['name']),
      brand = str(m['brand']),
      article = str(m['article']),
      measure = str(m['measure']).isEmpty ? 'шт' : str(m['measure']),
      dir = str(m['dir']),
      url = str(m['url']),
      text = str(m['text']),
      price = toD(m['price']),
      qty = toD(m['qty']),
      old = m['old'] == null ? null : toD(m['old']),
      sku = m['sku'] == true,
      img = Api.abs(m['img']),
      gallery = asList(m['gallery'])
          .map((g) => (big: Api.abs(g['big']) ?? '', thumb: Api.abs(g['thumb'] ?? g['big']) ?? ''))
          .where((g) => g.big.isNotEmpty)
          .toList(),
      chain = asList(m['chain']).map((s) => (id: toI(s['id']), name: str(s['name']))).toList(),
      chars = asList(m['chars']).map((r) => (name: str(r['name']), value: str(r['value']))).toList();

  bool get canAdd => price > 0 && !sku;
}

class Salon {
  final J raw;
  Salon(this.raw);
  String get name => str(raw['name']);
  String get city => str(raw['city']);
  String get address => str(raw['address']);
  String get hours => str(raw['hours']);
  String get phone => str(raw['phone']);
  String get whatsapp => str(raw['whatsapp']);
  String get dirs => str(raw['dirs']);
  String get text => str(raw['text']);
  String? get img => Api.abs(raw['img']);
  String get mapUrl {
    final lat = str(raw['lat']), lng = str(raw['lng']);
    if (lat.isNotEmpty && lng.isNotEmpty) return 'https://www.google.com/maps?q=${Uri.encodeComponent('$lat,$lng')}';
    if (address.isNotEmpty) {
      return 'https://www.google.com/maps/search/${Uri.encodeComponent((city.isNotEmpty ? '$city, ' : '') + address)}';
    }
    return '';
  }
}

/// Заказ сайта (offline.svet.kz / offline.centr-krasok.kz) в «Заказах в салонах»
class SiteOrder {
  final int id;
  final String number, dir, date, statusName;
  final double sum;
  final bool paid, canceled;
  SiteOrder.from(J m)
    : id = toI(m['id']),
      number = str(m['number']),
      dir = str(m['dir']),
      date = str(m['date']),
      statusName = str(m['statusName']),
      sum = toD(m['sum']),
      paid = m['paid'] == true,
      canceled = m['canceled'] == true;
}

class HistProject {
  final int dealId;
  final String title, stageName, state, created;
  final List<String> dirs;
  final List<SiteOrder> orders;
  final double ordersSum, paidSum;
  HistProject.from(J m)
    : dealId = toI(m['dealId']),
      title = str(m['title']),
      stageName = str(m['stageName']),
      state = str(m['state']),
      created = str(m['created']),
      dirs = (m['dirs'] is List) ? (m['dirs'] as List).map((e) => e.toString()).toList() : <String>[],
      orders = asList(m['orders']).map(SiteOrder.from).toList(),
      ordersSum = toD(m['ordersSum']),
      paidSum = toD(m['paidSum']);
}

class History {
  final List<HistProject> projects;
  final List<SiteOrder> orders;
  final String error;
  History(this.projects, this.orders, this.error);
  factory History.from(Object? v) {
    final m = asMap(v);
    return History(asList(m['projects']).map(HistProject.from).toList(), asList(m['orders']).map(SiteOrder.from).toList(), str(m['error']));
  }
}
