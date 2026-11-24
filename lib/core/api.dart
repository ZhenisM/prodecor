import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Ошибка API кабинета: code — 'auth', 'moderation', 'not_found', 'network', …
class ApiException implements Exception {
  final String message;
  final String code;
  ApiException(this.message, [this.code = '']);
  @override
  String toString() => message;
}

/// Клиент JSON API pro-decor.kz/designers/api/ (тот же, что у кабинета на сайте).
/// Вход — по токену приложения (заголовок Authorization: Bearer), без cookie и sessid.
class Api {
  static const host = 'https://pro-decor.kz';
  static const endpoint = '$host/designers/api/';

  String? token;
  final http.Client _http = http.Client();

  /// Абсолютная ссылка для картинок и страниц, которые API отдаёт от корня сайта
  static String? abs(Object? url) {
    final s = (url ?? '').toString();
    if (s.isEmpty) return null;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('//')) return 'https:$s';
    return host + (s.startsWith('/') ? s : '/$s');
  }

  Future<dynamic> call(String action, [Map<String, dynamic> data = const {}]) async {
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json', 'X-Requested-With': 'PRODECOR-App'};
    final t = token;
    if (t != null && t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
      headers['X-PD-Token'] = t; // запасной заголовок, если сервер срезает Authorization
    }
    http.Response r;
    try {
      r = await _http
          .post(Uri.parse('$endpoint?action=${Uri.encodeQueryComponent(action)}'), headers: headers, body: jsonEncode({...data, 'app': 1}))
          .timeout(const Duration(seconds: 40));
    } on SocketException {
      throw ApiException('Нет связи с сервером. Проверьте интернет и попробуйте ещё раз.', 'network');
    } catch (_) {
      throw ApiException('Нет связи с сервером. Проверьте интернет и попробуйте ещё раз.', 'network');
    }
    Map<String, dynamic> j;
    try {
      j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Сервер вернул неожиданный ответ (${r.statusCode}). Попробуйте позже.', 'server');
    }
    if (j['ok'] != true) {
      throw ApiException((j['error'] ?? 'Ошибка').toString(), (j['code'] ?? '').toString());
    }
    return j['data'];
  }
}
