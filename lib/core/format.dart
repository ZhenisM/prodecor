// Форматирование как в кабинете на сайте: деньги, числа, даты, телефон, инициалы.

double toD(Object? v) {
  if (v is num) return v.toDouble();
  return double.tryParse((v ?? '').toString().replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
}

int toI(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '').toString()) ?? 0;
}

String str(Object? v) => v == null ? '' : v.toString();

String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return (n < 0 ? '−' : '') + b.toString();
}

/// 1 234 567 ₸
String money(Object? n) => '${_group(toD(n).round())} ₸';

/// 12,5 / 1 200
String num2(Object? n) {
  final v = (toD(n) * 100).round() / 100;
  if (v == v.roundToDouble()) return _group(v.round());
  final whole = v.truncate();
  final frac = ((v - whole).abs() * 100).round().toString().padLeft(2, '0').replaceAll(RegExp(r'0$'), '');
  return '${_group(whole)},$frac';
}

/// 2026-11-24 → 24.11.2026
String dt(Object? d) {
  final s = str(d);
  if (s.length < 10) return '–';
  final p = s.substring(0, 10).split('-');
  if (p.length != 3) return s;
  return '${p[2]}.${p[1]}.${p[0]}';
}

String ini(Object? name) {
  final w = str(name).trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).take(2);
  return w.map((x) => x.substring(0, 1)).join().toUpperCase();
}

/// «Фамилия Имя» → «Имя Фамилия»
String shortName(Object? n) {
  final w = str(n).split(' ');
  return w.length >= 2 ? '${w[1]} ${w[0]}' : str(n);
}

String digits(Object? v) => str(v).replaceAll(RegExp(r'\D'), '');

/// +7 701 123 45 67
String fmtPhone(Object? v) {
  var d = digits(v);
  if (d.isEmpty) return '';
  if (d[0] == '8') d = '7${d.substring(1)}';
  if (d[0] != '7') d = '7$d';
  if (d.length > 11) d = d.substring(0, 11);
  final parts = <String>[];
  void add(int a, int b) {
    if (d.length > a) parts.add(d.substring(a, d.length < b ? d.length : b));
  }

  add(0, 1);
  add(1, 4);
  add(4, 7);
  add(7, 9);
  add(9, 11);
  return '+${parts.join(' ')}';
}

/// Убрать HTML из описания товара (абзацы и переносы сохраняются)
String htmlToText(String html) {
  var s = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h\d|tr)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const ent = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&quot;': '"',
    '&#39;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&laquo;': '«',
    '&raquo;': '»',
    '&mdash;': '—',
    '&ndash;': '–',
  };
  ent.forEach((k, v) => s = s.replaceAll(k, v));
  return s.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

const cities = [
  'Алматы',
  'Астана',
  'Шымкент',
  'Караганда',
  'Актобе',
  'Атырау',
  'Актау',
  'Усть-Каменогорск',
  'Павлодар',
  'Костанай',
  'Тараз',
  'Кызылорда',
  'Уральск',
  'Петропавловск',
  'Туркестан',
  'Другой город',
];
const ptypes = ['Квартира', 'Дом', 'Комната', 'Офис', 'Коммерция'];
const dirName = {'light': 'Свет', 'paint': 'Краски'};
