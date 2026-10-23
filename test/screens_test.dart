// Test ekranów: uruchamia prawdziwą aplikację na wirtualnym telefonie,
// sprawdza, że układ się nie sypie, i zapisuje zrzuty (test/shots/*.png).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:szuflada/core.dart';
import 'package:szuflada/main.dart';
import 'package:szuflada/ui.dart';

Future<void> _fonts() async {
  final l = FontLoader('Manrope');
  for (final w in ['400Regular', '500Medium', '600SemiBold', '700Bold', '800ExtraBold']) {
    l.addFont(rootBundle.load('assets/fonts/Manrope-$w.ttf'));
  }
  await l.load();
}

Future<void> _settle(WidgetTester t, [int ms = 1200]) async {
  for (var i = 0; i < ms ~/ 100; i++) { await t.pump(const Duration(milliseconds: 100)); }
}

Future<void> _shot(WidgetTester t, String name) async {
  await t.runAsync(() async { await Future.delayed(const Duration(milliseconds: 300)); });
  await _settle(t, 400);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _fonts();
    await initializeDateFormatting('pl_PL');
  });

  for (final dev in [const Size(393, 852), const Size(360, 640)]) {
    final tag = '${dev.width.toInt()}x${dev.height.toInt()}';
    testWidgets('ekrany $tag', (t) async {
      t.view.physicalSize = dev * 3; t.view.devicePixelRatio = 3;
      t.view.padding = const FakeViewPadding(top: 72, bottom: 48);
      t.view.viewPadding = const FakeViewPadding(top: 72, bottom: 48);
      addTearDown(t.view.reset);

      SharedPreferences.setMockInitialValues({'onb': true});
      await t.runAsync(() async {
        store.sp = await SharedPreferences.getInstance();
        store.dir = Directory.systemTemp.createTempSync('szuf');
        Directory('${store.dir.path}/img').createSync(recursive: true);
        store.items = []; store.onboarded = true; store.lockOn = false;
        await loadDemo();
      });

      await t.pumpWidget(const App());
      await _settle(t, 1600);

      // pasek dolny musi być nisko, a nie na pół ekranu
      final startY = t.getCenter(find.text('Start')).dy;
      expect(startY, greaterThan(dev.height - 90), reason: 'dolne menu rozciągnięte ($startY)');
      await _shot(t, '$tag-1-start');

      await t.tap(find.text('Paragony')); await _settle(t);
      await _shot(t, '$tag-2-paragony');

      final remLabel = find.text('Przypomnienia').evaluate().isNotEmpty ? 'Przypomnienia' : 'Terminy';
      await t.tap(find.text(remLabel)); await _settle(t);
      await _shot(t, '$tag-3-przypomnienia');

      await t.tap(find.text('Plan')); await _settle(t);
      await _shot(t, '$tag-4-plan');

      await t.tap(find.text('Paragony')); await _settle(t);
      await t.tap(find.textContaining('Słuchawki').first); await _settle(t, 1500);
      await _shot(t, '$tag-5-szczegoly');
      navKey.currentState!.pop(); await _settle(t, 1000);

      await t.tap(find.text('Start')); await _settle(t);
      await t.tap(find.byWidgetPredicate((w) => w is Ic && w.name == 'plus').first); await _settle(t, 1200);
      await _shot(t, '$tag-6-dodaj');
    });
  }
}
