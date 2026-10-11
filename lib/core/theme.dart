import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

/// iOS-Clock-like palette: true black, dark-grey grouped cards, orange accent.
const kAccent = Color(0xFFFF9F0A);
const kCardDark = Color(0xFF1C1C1E);
const kSeparator = Color(0xFF38383A);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: kAccent,
    brightness: brightness,
  ).copyWith(primary: kAccent, onPrimary: Colors.black);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? Colors.black : const Color(0xFFF2F2F7),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? Colors.black : const Color(0xFFF2F2F7),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? kCardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      color: dark ? kSeparator : const Color(0xFFD1D1D6),
      thickness: 0.5,
      space: 0.5,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? kCardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? kCardDark : Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()},
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
