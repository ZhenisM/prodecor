import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Вход, регистрация, подтверждение e-mail, восстановление пароля — как на pro-decor.kz/designers/
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _Step { form, code, forgot, reset }

class _AuthScreenState extends State<AuthScreen> {
  _Step step = _Step.form;
  bool reg = false;
  String phone = '', email = '';
  bool agree = false;
  String city = 'Алматы';

  final lPhone = PhoneController(), lPass = TextEditingController();
  final rName = TextEditingController(), rPhone = PhoneController(), rEmail = TextEditingController();
  final rInst = TextEditingController(), rStudio = TextEditingController(), rSpec = TextEditingController();
  final rPortfolio = TextEditingController(), rPass = TextEditingController(), rPass2 = TextEditingController();
  final code = TextEditingController(), fPhone = PhoneController();
  final xPass = TextEditingController(), xPass2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = context.read<Store>().signedOutReason;
      if (r != null && mounted) toast(context, r);
    });
  }

  @override
  void dispose() {
    for (final c in [lPhone, lPass, rName, rPhone, rEmail, rInst, rStudio, rSpec, rPortfolio, rPass, rPass2, code, fPhone, xPass, xPass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Store get s => context.read<Store>();

  Future<void> _login() async {
    final ph = lPhone.text;
    final d = await run(context, () => s.login(ph, lPass.text));
    if (d != null && d['needCode'] == true && mounted) {
      setState(() {
        step = _Step.code;
        phone = ph;
        email = str(d['email']);
      });
      toast(context, 'Почта не подтверждена — мы отправили новый код');
    }
  }

  Future<void> _register() async {
    if (!agree) {
      toast(context, 'Нужно согласие на обработку персональных данных');
      return;
    }
    final ph = rPhone.text;
    final d = await run(
      context,
      () => s.register({
        'name': rName.text.trim(),
        'phone': ph,
        'email': rEmail.text.trim(),
        'city': city,
        'inst': rInst.text.trim(),
        'studio': rStudio.text.trim(),
        'spec': rSpec.text.trim(),
        'portfolio': rPortfolio.text.trim(),
        'password': rPass.text,
        'password2': rPass2.text,
        'agree': true,
      }),
    );
    if (d != null && mounted) {
      setState(() {
        step = _Step.code;
        phone = ph;
        email = str(d['email']);
      });
    }
  }

  Future<void> _confirm() async {
    final ok = await run(context, () async {
      await s.confirm(phone, code.text.trim());
      return true;
    });
    if (ok == true && mounted) toast(context, 'E-mail подтверждён. Профиль отправлен на модерацию');
  }

  Future<void> _forgot() async {
    final ph = fPhone.text;
    final ok = await run(context, () async {
      await s.forgot(ph);
      return true;
    });
    if (ok == true && mounted) {
      setState(() {
        step = _Step.reset;
        phone = ph;
      });
    }
  }

  Future<void> _reset() async {
    final ok = await run(context, () async {
      await s.reset(phone, code.text.trim(), xPass.text, xPass2.text);
      return true;
    });
    if (ok == true && mounted) toast(context, 'Пароль изменён');
  }

  Future<void> _resend(String purpose) async {
    final e = await run(context, () => s.resend(phone, purpose));
    if (e != null && mounted) {
      if (e.isNotEmpty) setState(() => email = e);
      toast(context, 'Код отправлен ещё раз');
    }
  }

  void _back() => setState(() {
    step = _Step.form;
    code.clear();
  });

  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    final lang = context.watch<Store>().lang;
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const PdLogo(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PRO DECOR', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: .5)),
                        Text(
                          'СО ВКУСОМ · ПРОФЕССИОНАЛЬНО · НАДЁЖНО',
                          style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: c.muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  _LangSwitch(lang: lang),
                ],
              ),
              const SizedBox(height: 22),
              ..._body(lang),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(String lang) {
    final c = context.pd;
    switch (step) {
      case _Step.code:
        return [
          const Text('Подтвердите e-mail', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Мы отправили 6-значный код на ${email.isEmpty ? 'вашу почту' : email}. Код действует 15 минут. '
            'Проверьте папку «Спам», если письма нет.',
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 16),
          field(code, 'Код из письма', kb: TextInputType.number, autofill: const [AutofillHints.oneTimeCode]),
          FilledButton(onPressed: _confirm, child: const Text('Подтвердить')),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [LinkBtn('Отправить код ещё раз', () => _resend('register')), LinkBtn('Назад', _back)],
          ),
        ];
      case _Step.forgot:
        return [
          const Text('Восстановление пароля', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Укажите номер телефона — код для сброса пароля придёт на e-mail, указанный при регистрации.',
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 16),
          field(fPhone, 'Номер телефона', kb: TextInputType.phone, autofill: const [AutofillHints.telephoneNumber]),
          FilledButton(onPressed: _forgot, child: const Text('Получить код')),
          Align(alignment: Alignment.centerLeft, child: LinkBtn('Назад ко входу', _back)),
        ];
      case _Step.reset:
        return [
          const Text('Новый пароль', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Если номер зарегистрирован, код уже отправлен на e-mail из профиля.', style: TextStyle(color: c.muted)),
          const SizedBox(height: 16),
          field(code, 'Код из письма', kb: TextInputType.number, autofill: const [AutofillHints.oneTimeCode]),
          field(xPass, 'Новый пароль', obscure: true, autofill: const [AutofillHints.newPassword]),
          field(xPass2, 'Повторите пароль', obscure: true),
          FilledButton(onPressed: _reset, child: const Text('Сохранить и войти')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [LinkBtn('Отправить код ещё раз', () => _resend('reset')), LinkBtn('Назад ко входу', _back)],
          ),
        ];
      case _Step.form:
        return [
          Text(
            tr(lang, 'platform'),
            style: TextStyle(color: c.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(tr(lang, 'login'))),
              ButtonSegment(value: true, label: Text(tr(lang, 'register'))),
            ],
            selected: {reg},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => reg = v.first),
          ),
          const SizedBox(height: 18),
          if (!reg) ...[
            field(lPhone, 'Номер телефона', kb: TextInputType.phone, autofill: const [AutofillHints.username]),
            field(lPass, 'Пароль', obscure: true, autofill: const [AutofillHints.password]),
            Align(
              alignment: Alignment.centerRight,
              child: LinkBtn(
                'Забыли пароль?',
                () => setState(() {
                  if (digits(lPhone.text).length > 4) fPhone.text = lPhone.text;
                  step = _Step.forgot;
                }),
              ),
            ),
            const SizedBox(height: 6),
            FilledButton(onPressed: _login, child: const Text('Войти')),
            const SizedBox(height: 26),
            _Benefits(),
          ] else ...[
            field(rName, 'ФИО', hint: 'Фамилия Имя Отчество', autofill: const [AutofillHints.name]),
            field(rPhone, 'Номер телефона', kb: TextInputType.phone, autofill: const [AutofillHints.telephoneNumber]),
            field(
              rEmail,
              'E-mail',
              hint: 'для кода и восстановления пароля',
              kb: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
            ),
            dropdown('Город', city, cities, (v) => setState(() => city = v)),
            field(rInst, 'Instagram', hint: '@studio'),
            field(rStudio, 'Студия или ИП'),
            field(rSpec, 'Специализация', hint: 'Жилые интерьеры, HoReCa…'),
            field(rPortfolio, 'Портфолио (ссылка)', hint: 'https://', kb: TextInputType.url),
            field(rPass, 'Пароль', obscure: true, autofill: const [AutofillHints.newPassword]),
            field(rPass2, 'Повторите пароль', obscure: true),
            CheckboxListTile(
              value: agree,
              onChanged: (v) => setState(() => agree = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Согласен на обработку персональных данных'),
            ),
            FilledButton(onPressed: _register, child: const Text('Отправить на модерацию')),
            const SizedBox(height: 8),
            Text(
              'На e-mail придёт код подтверждения. После этого администратор проверит профиль и закрепит менеджера.',
              style: TextStyle(fontSize: 12.5, color: c.muted),
            ),
          ],
        ];
    }
  }
}

class _Benefits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    Widget li(String t) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: c.gold),
          const SizedBox(width: 8),
          Expanded(child: Text(t)),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('От первого брифа до бонуса за продажу', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Дизайнер ведёт клиента и проект в одной системе, передаёт готовую подборку менеджеру и видит, как продвигается заявка.',
            style: TextStyle(color: c.muted, fontSize: 13),
          ),
          li('Клиенты и проекты в одном месте'),
          li('Подбор из каталога света и красок'),
          li('Заявка менеджеру в один клик'),
        ],
      ),
    );
  }
}

class _LangSwitch extends StatelessWidget {
  final String lang;
  const _LangSwitch({required this.lang});
  @override
  Widget build(BuildContext context) {
    final c = context.pd;
    Widget b(String v, String l) => InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: () => context.read<Store>().setLang(v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: lang == v ? c.paper : Colors.transparent, borderRadius: BorderRadius.circular(99)),
        child: Text(
          l,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: lang == v ? c.ink : c.muted),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.sunk, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [b('ru', 'RU'), b('kz', 'ҚАЗ')]),
    );
  }
}

/// Переключатель языка для экранов кабинета
class LangSwitch extends StatelessWidget {
  const LangSwitch({super.key});
  @override
  Widget build(BuildContext context) => _LangSwitch(lang: context.watch<Store>().lang);
}
