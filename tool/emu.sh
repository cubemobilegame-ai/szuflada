#!/bin/bash
# uruchamia prawdziwy APK na emulatorze, klika przez aplikację i robi zrzuty
OUT=/tmp/emu; mkdir -p $OUT
P=com.cubemobilegames.szuflada
shot(){ adb exec-out screencap -p > $OUT/$1.png; echo "zrzut $1"; }
tapt(){ python3 tool/tap_text.py "$1" | tee -a $OUT/taps.txt; }
adb install -r app.apk 2>&1 | tee $OUT/install.txt
adb shell pm grant $P android.permission.POST_NOTIFICATIONS || true
adb logcat -c
adb shell monkey -p $P -c android.intent.category.LAUNCHER 1
sleep 12; shot 01-start
tapt "Pomiń"; sleep 3; shot 02-onb
tapt "Zaczynamy"; sleep 4; shot 03-shell-pusta
tapt "Paragony"; sleep 3; shot 04-paragony
tapt "Plan"; sleep 3; shot 05-plan
tapt "Start"; sleep 3
tapt "Zobacz na przykładach"; sleep 4; shot 06-start-demo
tapt "Paragony"; sleep 3; shot 07-paragony-demo
adb shell settings put system font_scale 1.3; sleep 4; shot 08-czcionka-130
adb shell settings put system font_scale 1.0
adb shell wm size; adb shell wm density
adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb shell cat /sdcard/ui.xml > $OUT/ui.xml
adb logcat -d > $OUT/logcat.txt
grep -iE "flutter|exception|error" $OUT/logcat.txt | grep -v "^$" | head -300 > $OUT/flutter.txt
exit 0
