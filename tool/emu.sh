#!/bin/bash
# uruchamia prawdziwy APK na emulatorze (Pixel 6, 1080x2400), klika i robi zrzuty
OUT=/tmp/emu; mkdir -p $OUT
P=com.cubemobilegames.szuflada
log(){ echo "$*" | tee -a $OUT/taps.txt; }
anr(){ for i in 1 2 3; do
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  x=$(adb shell cat /sdcard/ui.xml)
  if echo "$x" | grep -q "responding"; then python3 tool/tap_text.py "Wait" >> $OUT/taps.txt; sleep 2; else break; fi
done; }
shot(){ anr; adb exec-out screencap -p > $OUT/$1.png; log "zrzut $1"; }
tap(){ anr; adb shell input tap $1 $2; log "tap $1 $2 ($3)"; sleep ${4:-3}; }
start(){ adb shell monkey -p $P -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 10; }
adb shell wm size | tee -a $OUT/taps.txt; adb shell wm density | tee -a $OUT/taps.txt
sleep 45; anr; adb shell input keyevent KEYCODE_HOME; sleep 5; anr
adb install -r app.apk 2>&1 | tee $OUT/install.txt
adb shell pm grant $P android.permission.POST_NOTIFICATIONS || true
adb logcat -c
NAV=2290
# --- przebieg 1: pusta szuflada (jak po świeżej instalacji) ---
start; shot 01-onboarding
tap 540 2243 "Pomiń"; shot 02-ostatni-slajd
tap 540 2123 "Zaczynamy" 5; shot 03-start-pusty
tap 324 $NAV "Paragony"; shot 04-paragony-puste
tap 756 $NAV "Przypomnienia"; shot 05-przypomnienia-puste
tap 972 $NAV "Plan"; shot 06-plan
tap 108 $NAV "Start"
tap 540 $NAV "plus" 4; shot 07-dodaj
adb shell input keyevent KEYCODE_BACK; sleep 2
# --- przebieg 2: dane przykładowe ---
adb shell pm clear $P >/dev/null; adb shell pm grant $P android.permission.POST_NOTIFICATIONS || true
start; tap 540 2243 "Pomiń"; tap 540 2243 "Zobacz na przykładach" 5; shot 08-start-demo
tap 324 $NAV "Paragony"; shot 09-paragony-demo
tap 540 900 "pierwszy produkt" 4; shot 10-szczegoly
adb shell input keyevent KEYCODE_BACK; sleep 2
adb shell settings put system font_scale 1.3; sleep 4; shot 11-czcionka-130
adb shell settings put system font_scale 1.0
adb logcat -d > $OUT/logcat.txt
grep -iE " flutter|AndroidRuntime|FATAL" $OUT/logcat.txt | head -300 > $OUT/flutter.txt
exit 0
