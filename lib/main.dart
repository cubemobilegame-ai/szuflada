import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core.dart';
import 'pages.dart';
import 'services.dart';
import 'ui.dart';

final navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('pl_PL');
  await store.init();
  try { await Notifier.init(); } catch (_) {}
  try { await Notifier.reschedule(store.items); } catch (_) {}
  Billing.init();
  runApp(const App());
}

ThemeData _theme(T t) {
  final cs = ColorScheme.fromSeed(seedColor: t.accent, brightness: t.dark ? Brightness.dark : Brightness.light).copyWith(
    primary: t.accent, onPrimary: t.on, surface: t.bg, onSurface: t.text, onSurfaceVariant: t.sub, outline: t.line, outlineVariant: t.line, surfaceTint: Colors.transparent,
    surfaceContainerHighest: t.card, surfaceContainerHigh: t.card, surfaceContainer: t.card, surfaceContainerLow: t.card,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: cs, brightness: t.dark ? Brightness.dark : Brightness.light, fontFamily: 'Jakarta');
  return base.copyWith(
    scaffoldBackgroundColor: t.bg,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(fontFamily: 'Jakarta', bodyColor: t.text, displayColor: t.text),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: t.bg, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      headerBackgroundColor: t.accent, headerForegroundColor: t.on,
      dayStyle: const TextStyle(fontFamily: 'Jakarta', fontWeight: FontWeight.w600), yearStyle: const TextStyle(fontFamily: 'Jakarta', fontWeight: FontWeight.w600),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: t.sub), confirmButtonStyle: TextButton.styleFrom(foregroundColor: t.accent),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: t.accent, selectionColor: t.accent.withValues(alpha: .25), selectionHandleColor: t.accent),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()}),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: store,
        builder: (_, __) => MaterialApp(
          title: 'Szuflada', debugShowCheckedModeBanner: false, navigatorKey: navKey,
          themeMode: store.theme, theme: _theme(T.light), darkTheme: _theme(T.night),
          locale: const Locale('pl'), supportedLocales: const [Locale('pl')], localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (ctx, child) {
            final dark = Theme.of(ctx).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent, systemNavigationBarContrastEnforced: false),
              child: ToastHost(child: child ?? const SizedBox()),
            );
          },
          home: const Gate(),
        ),
      );
}
