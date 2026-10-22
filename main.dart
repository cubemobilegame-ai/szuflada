import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core.dart';
import 'pages.dart';
import 'services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL');
  await store.init();
  await Notifier.init();
  await Notifier.reschedule(store.items);
  Billing.init();
  runApp(const App());
}

ThemeData _theme(Brightness b) {
  final d = b == Brightness.dark;
  final cs = ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8), brightness: b).copyWith(
    primary: d ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
    onPrimary: d ? const Color(0xFF202124) : Colors.white,
    primaryContainer: d ? const Color(0xFF2D3B55) : const Color(0xFFE8F0FE),
    onPrimaryContainer: d ? const Color(0xFFD2E3FC) : const Color(0xFF174EA6),
    surface: d ? const Color(0xFF202124) : Colors.white,
    onSurface: d ? const Color(0xFFE8EAED) : const Color(0xFF202124),
    onSurfaceVariant: d ? const Color(0xFF9AA0A6) : const Color(0xFF5F6368),
    outline: d ? const Color(0xFF5F6368) : const Color(0xFF9AA0A6),
    outlineVariant: d ? const Color(0xFF3C4043) : const Color(0xFFDADCE0),
    surfaceTint: Colors.transparent,
    error: d ? const Color(0xFFF28B82) : const Color(0xFFD93025),
  );
  final line = cs.outlineVariant;
  final card = d ? const Color(0xFF292A2D) : const Color(0xFFF8F9FA);
  final pill = const StadiumBorder();
  const btnText = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);
  return ThemeData(
    useMaterial3: true, colorScheme: cs, scaffoldBackgroundColor: cs.surface,
    appBarTheme: AppBarTheme(backgroundColor: cs.surface, surfaceTintColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: false, titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: cs.onSurface)),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: cs.surface, surfaceTintColor: Colors.transparent, indicatorColor: cs.primaryContainer, elevation: 0, height: 68, labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: cs.primary, foregroundColor: cs.onPrimary, elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: pill, minimumSize: const Size(64, 50), textStyle: btnText)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: pill, minimumSize: const Size(64, 50), textStyle: btnText, side: BorderSide(color: line))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: pill, textStyle: btnText)),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 2)),
    ),
    cardTheme: CardThemeData(color: card, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: line))),
    chipTheme: ChipThemeData(shape: StadiumBorder(side: BorderSide(color: line)), backgroundColor: cs.surface, selectedColor: cs.primaryContainer, showCheckmark: false, labelStyle: TextStyle(fontSize: 13, color: cs.onSurface)),
    dividerTheme: DividerThemeData(color: line, space: 1),
    textTheme: Typography.material2021().black.apply(bodyColor: cs.onSurface, displayColor: cs.onSurface).copyWith(
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: cs.onSurface),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: cs.onSurface),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: cs.onSurface)),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: store,
        builder: (_, __) => MaterialApp(
          title: 'Szuflada', debugShowCheckedModeBanner: false, themeMode: store.theme, theme: _theme(Brightness.light), darkTheme: _theme(Brightness.dark),
          locale: const Locale('pl'), supportedLocales: const [Locale('pl')], localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Gate(),
        ),
      );
}
