import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:prodecor/core/api.dart';
import 'package:prodecor/common/format.dart';
import 'package:prodecor/common/i18n.dart';
import 'package:prodecor/core/models.dart';
import 'package:prodecor/core/store.dart';
import 'package:prodecor/theme/theme.dart';

/* ---------- логотип PRODECOR (квадраты 2×2 с точками) ---------- */
class PdLogo extends StatelessWidget {
  final double size;
  const PdLogo({super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 40;
    const dark = Color(0xFF222321), sand = Color(0xFFC9B394);
    void sq(double x, double y, Color c) => canvas.drawRect(Rect.fromLTWH(x * k, y * k, 18 * k, 18 * k), Paint()..color = c);
    void dot(double x, double y, Color c) => canvas.drawCircle(Offset(x * k, y * k), 3.6 * k, Paint()..color = c);
    sq(2, 2, dark);
    sq(20, 2, sand);
    sq(2, 20, sand);
    sq(20, 20, dark);
    dot(20, 11, dark);
    dot(11, 20, sand);
    dot(29, 20, sand);
    dot(20, 29, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ---------- сообщения и выполнение действий ---------- */
void toast(BuildContext context, String msg) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
}

/// Выполнить действие: ошибки — в сообщение, на время — индикатор поверх экрана
Future<T?> run<T>(BuildContext context, Future<T> Function() fn) async {
  final nav = Navigator.of(context, rootNavigator: true);
  var shown = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black12,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
  ).then((_) => shown = false);
  try {
    final r = await fn();
    if (shown) nav.pop();
    return r;
  } catch (e) {
    if (shown) nav.pop();
    if (context.mounted) toast(context, e.toString());
    return null;
  }
}

Future<void> openUrl(String url) async {
  final u = Uri.tryParse(url);
  if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
}

String tt(BuildContext context, String key) => tr(context.watch<Store>().lang, key);

/* ---------- элементы ---------- */

/// Статусная плашка: kind — draft / ready / work / ok / bad / gold / info
class Pill extends StatelessWidget {
  final String text;
  final String kind;
  const Pill(this.text, this.kind, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    final (bg, fg) = switch (kind) {
      'ready' => (c.warnT, c.warn),
      'work' => (c.infoT, c.info),
      'ok' => (c.okT, c.ok),
      'bad' => (c.badT, c.bad),
      'gold' => (c.goldTint, c.goldInk),
      'info' => (c.infoT, c.info),
      _ => (c.sunk, c.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class Chip2 extends StatelessWidget {
  final String text;
  final IconData? icon;
  const Chip2(this.text, {super.key, this.icon});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.sunk, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: c.muted), const SizedBox(width: 4)],
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink),
          ),
        ],
      ),
    );
  }
}

Widget dirChips(List<String> dirs) => dirs.isEmpty
    ? const Text('—')
    : Wrap(spacing: 4, runSpacing: 4, children: dirs.map((d) => Chip2(dirName[d] ?? d, icon: dirIcon(d))).toList());

IconData dirIcon(String? d) => d == 'paint' ? Icons.format_paint_outlined : Icons.lightbulb_outline;

/// Карточка-секция
class Box extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? action;
  final String? sub;
  final EdgeInsets padding;
  const Box({super.key, required this.child, this.title, this.action, this.sub, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: c.paper,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.line),
        ),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title!, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
                            if (sub != null) Text(sub!, style: TextStyle(fontSize: 12.5, color: c.muted)),
                          ],
                        ),
                      ),
                      ?action,
                    ],
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Заголовок экрана: надзаголовок, заголовок, пояснение
class PageHead extends StatelessWidget {
  final String eyebrow, title;
  final String? sub;
  const PageHead(this.eyebrow, this.title, {super.key, this.sub});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: c.gold),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.15)),
          if (sub != null && sub!.isNotEmpty) ...[const SizedBox(height: 6), Text(sub!, style: TextStyle(color: c.muted, fontSize: 13.5))],
        ],
      ),
    );
  }
}

class Tile extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const Tile(this.label, this.value, this.sub, this.icon, this.color, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: c.muted, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 11.5, color: c.muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, text;
  final Widget? action;
  const EmptyState(this.icon, this.title, this.text, {super.key, this.action});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.sunk, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: c.muted),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(color: c.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Center(child: CircularProgressIndicator()),
  );
}

/// Прогресс заявки: 5 сегментов
class StageBar extends StatelessWidget {
  final int n;
  const StageBar(this.n, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Container(
          width: 18,
          height: 4,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(color: i < n ? c.ok : c.sunk, borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  const Avatar(this.name, {super.key, this.size = 38});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.goldTint, shape: BoxShape.circle),
      child: Text(
        ini(name).isEmpty ? '–' : ini(name),
        style: TextStyle(color: c.goldInk, fontWeight: FontWeight.w700, fontSize: size * .36),
      ),
    );
  }
}

/// Строка менеджера с кнопками «позвонить» и WhatsApp
class ManagerRow extends StatelessWidget {
  final String label;
  final Manager m;
  const ManagerRow(this.label, this.m, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    final ph = digits(m.phone);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Avatar(m.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, color: c.muted)),
                Text(m.has ? m.name : 'Не назначен', style: const TextStyle(fontWeight: FontWeight.w700)),
                if (ph.isNotEmpty) Text(fmtPhone(ph), style: TextStyle(fontSize: 12, color: c.muted)),
              ],
            ),
          ),
          if (ph.isNotEmpty) ...[
            IconButton.filledTonal(onPressed: () => openUrl('tel:+$ph'), icon: const Icon(Icons.phone_outlined, size: 18)),
            const SizedBox(width: 4),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: c.goldTint,
                foregroundColor: c.goldInk,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => openUrl('https://wa.me/$ph'),
              child: const Text('WhatsApp'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Блок «Ваш менеджер / Ваши менеджеры»
class ManagersBox extends StatelessWidget {
  const ManagersBox({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final me = s.me!;
    final same = me.light.name == me.paint.name;
    return Box(
      title: tr(s.lang, same ? 'manager' : 'managers'),
      child: Column(
        children: same ? [ManagerRow('Свет и краски', me.light)] : [ManagerRow('Свет', me.light), ManagerRow('Краски', me.paint)],
      ),
    );
  }
}

class NetImg extends StatelessWidget {
  final String? url;
  final double? w, h;
  final BoxFit fit;
  final IconData fallback;
  const NetImg(this.url, {super.key, this.w, this.h, this.fit = BoxFit.contain, this.fallback = Icons.image_outlined});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    final ph = Container(
      width: w,
      height: h,
      color: c.sunk,
      alignment: Alignment.center,
      child: Icon(fallback, color: c.soft),
    );
    if (url == null || url!.isEmpty) return ph;
    return CachedNetworkImage(imageUrl: url!, width: w, height: h, fit: fit, placeholder: (_, _) => ph, errorWidget: (_, _, _) => ph);
  }
}

/// Кнопка-ссылка в стиле кабинета
class LinkBtn extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const LinkBtn(this.text, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: const Size(0, 32)),
    child: Text(text, style: const TextStyle(decoration: TextDecoration.underline)),
  );
}

/// Строка списка (карточка без рамки внутри Box)
class RowX extends StatelessWidget {
  final Widget title;
  final Widget? subtitle, trailing, leading;
  final VoidCallback? onTap;
  const RowX({super.key, required this.title, this.subtitle, this.trailing, this.leading, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: TextStyle(color: c.muted, fontSize: 12.5),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Пример для показа (пока нет связи с 1С)
class DemoTag extends StatelessWidget {
  const DemoTag({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'пример',
        style: TextStyle(fontSize: 10.5, color: c.muted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Нижняя «шторка» с формой
Future<T?> sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: child,
  ),
);

/// Каркас содержимого шторки: заголовок + прокрутка
class SheetBody extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SheetBody({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

/// Текстовое поле формы
Widget field(
  TextEditingController c,
  String label, {
  String? hint,
  TextInputType? kb,
  bool obscure = false,
  int lines = 1,
  bool readOnly = false,
  List<String>? autofill,
  ValueChanged<String>? onChanged,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextField(
    controller: c,
    decoration: InputDecoration(labelText: label, hintText: hint),
    keyboardType: kb,
    obscureText: obscure,
    minLines: lines,
    maxLines: obscure ? 1 : (lines > 1 ? lines + 3 : 1),
    readOnly: readOnly,
    autofillHints: autofill,
    onChanged: onChanged,
  ),
);

/// Выпадающий список формы
Widget dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: DropdownButtonFormField<String>(
    initialValue: items.contains(value) ? value : items.first,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: items.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
    onChanged: (v) => onChanged(v ?? items.first),
  ),
);

/// Маска телефона +7 7XX XXX XX XX при вводе
class PhoneController extends TextEditingController {
  PhoneController([String initial = '+7 7']) : super(text: initial) {
    addListener(_fmt);
  }
  bool _busy = false;
  void _fmt() {
    if (_busy) return;
    final f = fmtPhone(text);
    final v = f.isEmpty ? '+7' : f;
    if (v != text) {
      _busy = true;
      value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
      _busy = false;
    }
  }
}

String absUrl(String? u) => Api.abs(u) ?? '';
