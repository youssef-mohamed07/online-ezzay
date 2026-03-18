import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/splash_page.dart';

class OnlineEzzyApp extends StatelessWidget {
  const OnlineEzzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandRed = Color(0xFFE71D24);
    const darkText = Color(0xFF1F232A);

    final baseText = GoogleFonts.cairoTextTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Ezzy',
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
