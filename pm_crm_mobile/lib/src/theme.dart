// Тёплая палитра мобильной версии (та же, что в десктопной CRM).

import 'package:flutter/material.dart';

const Color kBg = Color(0xFFF8F3EC); // тёплый бежевый
const Color kPanel = Color(0xFFFDF9F1);
const Color kFg = Color(0xFF5A4436); // тёмный тёплый коричневый
const Color kMuted = Color(0xFFA08A76);
const Color kAccent = Color(0xFF8E9867); // оливковый
const Color kTerracotta = Color(0xFFE1937D);
const Color kBorder = Color(0xFFE4D6C2);
const Color kOk = Color(0xFF7D8F4E);
const Color kBad = Color(0xFFC2654E);

ThemeData buildTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: kAccent,
    onPrimary: Colors.white,
    secondary: kTerracotta,
    onSecondary: const Color(0xFF4A3528),
    error: kBad,
    onError: Colors.white,
    surface: kPanel,
    onSurface: kFg,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kFg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: kFg, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.55),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kPanel,
      selectedColor: kAccent,
      labelStyle: const TextStyle(color: kFg),
      side: const BorderSide(color: kBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF4A3A2E),
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kPanel,
      indicatorColor: kAccent.withValues(alpha: 0.25),
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(color: kFg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Карточка-панель в тёплой палитре (без новых API-токенов тем).
class PanelBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const PanelBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
