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

ThemeData _theme(Brightness b) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8), brightness: b),
      inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: b == Brightness.dark ? const Color(0xFF3C4043) : const Color(0xFFDADCE0)))),
    );

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
