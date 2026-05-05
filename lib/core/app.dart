import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:online_ezzy/core/api_service.dart';
import 'package:online_ezzy/core/app_translations.dart';
import 'package:online_ezzy/providers/auth_provider.dart';
import 'package:online_ezzy/views/screens/auth/login_page.dart';
import 'package:online_ezzy/views/screens/splash_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class OnlineEzzyApp extends StatefulWidget {
  const OnlineEzzyApp({super.key});

  @override
  State<OnlineEzzyApp> createState() => _OnlineEzzyAppState();
}

class _OnlineEzzyAppState extends State<OnlineEzzyApp> {
  @override
  void initState() {
    super.initState();
    ApiService.onUnauthorized = _handleUnauthorizedSession;
  }

  @override
  void dispose() {
    ApiService.onUnauthorized = null;
    super.dispose();
  }

  Future<void> _handleUnauthorizedSession() async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await Provider.of<AuthProvider>(ctx, listen: false).logout();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    }

    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          'انتهت صلاحية جلسة تسجيل الدخول. سجّل دخولك مجدداً لاستخدام التطبيق بالكامل.'
              .tr,
        ),
      ),
    );

    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandRed = Color(0xFFE71D24);
    const darkText = Color(0xFF1F232A);

    final baseText = GoogleFonts.cairoTextTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'OnlineEzzy',
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandRed,
          primary: brandRed,
          secondary: const Color(0xFF232830),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: brandRed, // Red back buttons globally
          ),
          actionsIconTheme: IconThemeData(
            color: brandRed, // Red actions as well
          ),
        ),
        textTheme: baseText.copyWith(
          displaySmall: baseText.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
          headlineSmall: baseText.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          bodyMedium: baseText.bodyMedium?.copyWith(
            color: const Color(0xFF545C69),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}
