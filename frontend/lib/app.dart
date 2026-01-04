import 'package:flutter/material.dart';
// import 'pages/rooms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/settings.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_bus.dart';
import 'dart:async';
import 'pages/home.dart';
import 'pages/login.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  String? token;
  String? refreshToken;
  bool highContrast = false;
  double textScale = 1.0;
  Locale? locale;
  StreamSubscription<void>? _settingsSub;
  @override
  void initState() {
    super.initState();
    _hydrateToken();
    _hydratePrefs();
    _settingsSub = SettingsBus.stream.listen((_) {
      _hydratePrefs();
    });
  }
  Future<void> _hydrateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('accessToken');
    final r = prefs.getString('refreshToken');
    if (t != null && t.isNotEmpty) {
      await Api.setTokens(t, r);
      setState(() {
        token = t;
        refreshToken = r;
      });
    }
  }
  Future<void> _hydratePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    highContrast = prefs.getBool('high_contrast') ?? false;
    textScale = prefs.getDouble('text_scale') ?? 1.0;
    final lang = prefs.getString('lang');
    locale = lang == null ? null : Locale(lang);
    Api.setAcceptLanguage(lang);
    setState(() {});
  }
  Future<void> _setTokens(String t, String? r) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', t);
    if (r != null && r.isNotEmpty) {
      await prefs.setString('refreshToken', r);
    }
    await Api.setTokens(t, r);
    setState(() {
      token = t;
      refreshToken = r;
    });
  }
  Future<void> _logout() async {
    await Api.logout();
    await Api.clearTokens();
    setState(() {
      token = null;
      refreshToken = null;
    });
    try {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => LoginPage(onLoggedIn: _setTokens)), (route) => false);
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F), brightness: Brightness.light));
    final appTheme = highContrast
        ? theme.copyWith(colorScheme: theme.colorScheme.copyWith(onSurface: Colors.black))
        : theme.copyWith(
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
          );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plataforma Externa',
      theme: appTheme,
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizationsDelegate.delegate,
      ],
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(data: mq.copyWith(textScaler: TextScaler.linear(textScale)), child: child ?? const SizedBox.shrink());
      },
      home: token == null ? LoginPage(onLoggedIn: _setTokens) : HomePage(token: token, onLogout: _logout, onLoggedIn: _setTokens),
      routes: {
        '/settings': (_) => const SettingsPage(),
      },
    );
  }
  @override
  void dispose() {
    _settingsSub?.cancel();
    super.dispose();
  }
}
