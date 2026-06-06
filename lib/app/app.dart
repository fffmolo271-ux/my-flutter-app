import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../ui/gate.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateLocale(WidgetsBinding.instance.platformDispatcher.locales);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    _updateLocale(locales);
  }

  void _updateLocale(List<Locale>? locales) {
    const supportedLocales = [Locale('en'), Locale('ar')];

    if (locales == null || locales.isEmpty) {
      setState(() => _locale = supportedLocales.first);
      return;
    }

    final matching = locales.firstWhere(
      (locale) => supportedLocales.any((supported) => supported.languageCode == locale.languageCode),
      orElse: () => supportedLocales.first,
    );

    if (matching != _locale) {
      setState(() => _locale = matching);
    }
  }

  Locale _resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) return const Locale('en');
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return const Locale('en');
  }

  @override
  Widget build(BuildContext context) {
    const supportedLocales = [Locale('en'), Locale('ar')];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '1% Better',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFA3E635),
          secondary: Color(0xFFA3E635),
          surface: Color(0xFF12121A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0F12),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFFA3E635)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFA3E635),
          foregroundColor: Color(0xFF0B0F12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA3E635),
            foregroundColor: const Color(0xFF0B0F12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      supportedLocales: supportedLocales,
      locale: _locale,
      localeResolutionCallback: (locale, supportedLocales) => _resolveLocale(locale, supportedLocales),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (_locale?.languageCode == 'ar') {
          return Directionality(textDirection: TextDirection.rtl, child: child!);
        }
        return child!;
      },
      home: const Gate(),
    );
  }
}

