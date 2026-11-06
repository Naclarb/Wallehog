import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../application/records_controller.dart';
import '../features/home/home_page.dart';
import 'design_tokens.dart';

class WallehogApp extends StatelessWidget {
  const WallehogApp({super.key, required this.controller});
  final RecordsController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '电子猪 Wallehog',
    debugShowCheckedModeBanner: false,
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primaryPink).copyWith(
        primary: const Color(0xFFAD416A),
        surface: pageBackground,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: pageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: pageBackground,
        foregroundColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          backgroundColor: const Color(0xFFB94D7B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: Color(0xFFE5CCD6)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide.none,
        ),
        prefixIconColor: mutedInk,
        hintStyle: TextStyle(color: mutedInk, fontSize: 14),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        filled: true,
        fillColor: Color(0xFFF7EEEF),
      ),
      useMaterial3: true,
    ),
    home: HomePage(controller: controller),
  );
}
