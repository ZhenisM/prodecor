import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цвета кабинета pro-decor.kz/designers (тёплая бумага, графит, золото) — светлая и тёмная схемы.
@immutable
class Pd extends ThemeExtension<Pd> {
  final Color bg, paper, sunk, line, ink, muted, soft;
  final Color gold, gold2, goldInk, goldTint;
  final Color g1, g2, onG;
  final Color ok, okT, warn, warnT, bad, badT, info, infoT;

  const Pd({
    required this.bg,
    required this.paper,
    required this.sunk,
    required this.line,
    required this.ink,
    required this.muted,
    required this.soft,
    required this.gold,
    required this.gold2,
    required this.goldInk,
    required this.goldTint,
    required this.g1,
    required this.g2,
    required this.onG,
    required this.ok,
    required this.okT,
    required this.warn,
    required this.warnT,
    required this.bad,
    required this.badT,
    required this.info,
    required this.infoT,
  });

  static const light = Pd(
    bg: Color(0xFFF3F0EA),
    paper: Color(0xFFFBFAF7),
    sunk: Color(0xFFECE7DD),
    line: Color(0xFFE2DCCF),
    ink: Color(0xFF1E1D1B),
    muted: Color(0xFF77716A),
    soft: Color(0xFFA39C90),
    gold: Color(0xFFA8843A),
    gold2: Color(0xFFC9A85E),
    goldInk: Color(0xFF6B511E),
    goldTint: Color(0xFFF2E8D1),
    g1: Color(0xFF3B3A38),
    g2: Color(0xFF706E69),
    onG: Color(0xFFFFFFFF),
    ok: Color(0xFF2C8664),
    okT: Color(0xFFDCF0E6),
    warn: Color(0xFFA86E14),
    warnT: Color(0xFFFAEACB),
    bad: Color(0xFFB0433A),
    badT: Color(0xFFF6DDD9),
    info: Color(0xFF41679F),
    infoT: Color(0xFFDEE7F4),
  );

  static const dark = Pd(
    bg: Color(0xFF161513),
    paper: Color(0xFF201E1B),
    sunk: Color(0xFF2A2723),
    line: Color(0xFF38342E),
    ink: Color(0xFFF1EDE5),
    muted: Color(0xFFA8A196),
    soft: Color(0xFF7C766C),
    gold: Color(0xFFD4B16B),
    gold2: Color(0xFFA98838),
    goldInk: Color(0xFFEED69F),
    goldTint: Color(0xFF382E1D),
    g1: Color(0xFFECE8E0),
    g2: Color(0xFFBFB9AE),
    onG: Color(0xFF1A1917),
    ok: Color(0xFF5FC49D),
    okT: Color(0xFF183A2E),
    warn: Color(0xFFE3AA4F),
    warnT: Color(0xFF3A2D14),
    bad: Color(0xFFE6837A),
    badT: Color(0xFF3D1F1C),
    info: Color(0xFF92B2DE),
    infoT: Color(0xFF1E2A3B),
  );

  @override
  Pd copyWith() => this;

  @override
  Pd lerp(ThemeExtension<Pd>? other, double t) => t < .5 ? this : (other as Pd? ?? this);
}

extension PdContext on BuildContext {
  Pd get pd => Theme.of(this).extension<Pd>()!;
}

/// false — без загрузки шрифта Onest (для тестов)
bool useGoogleFonts = true;

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.dark ? Pd.dark : Pd.light;
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.gold,
      brightness: b,
    ).copyWith(primary: c.g1, onPrimary: c.onG, secondary: c.gold, surface: c.paper, onSurface: c.ink, error: c.bad),
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
  );
  final text = (useGoogleFonts ? GoogleFonts.onestTextTheme(base.textTheme) : base.textTheme).apply(bodyColor: c.ink, displayColor: c.ink);
  OutlineInputBorder border(Color col, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: col, width: w),
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: c.ink),
    ),
    dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.paper,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: c.muted),
      hintStyle: TextStyle(color: c.soft),
      border: border(c.line),
      enabledBorder: border(c.line),
      focusedBorder: border(c.gold, 1.6),
      errorBorder: border(c.bad),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.g1,
        foregroundColor: c.onG,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.line),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.goldInk,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.paper,
      indicatorColor: c.goldTint,
      elevation: 0,
      height: 66,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.ink)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.goldInk : c.muted)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.g1,
      contentTextStyle: TextStyle(color: c.onG),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.paper,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    ),
    checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.g1 : null)),
  );
}
