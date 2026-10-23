"""Dopasowuje projekt wygenerowany przez `flutter create` do wymagań pakietów (idempotentnie)."""
import glob, os, re
mf = 'android/app/src/main/AndroidManifest.xml'
s = open(mf, encoding='utf-8').read()
if 'POST_NOTIFICATIONS' not in s:
    perms = ('<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    '
             '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n    '
             '<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    ')
    rec = ('<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>\n        '
           '<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n'
           '            <intent-filter>\n                <action android:name="android.intent.action.BOOT_COMPLETED"/>\n'
           '                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>\n                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>\n'
           '            </intent-filter>\n        </receiver>\n    ')
    s = s.replace('<application', perms + '<application', 1).replace('</application>', rec + '</application>', 1)
    s = re.sub(r'android:label="[^"]*"', 'android:label="Szuflada"', s, 1)
    open(mf, 'w', encoding='utf-8').write(s)
for f in glob.glob('android/app/src/main/kotlin/**/MainActivity.kt', recursive=True):
    t = open(f, encoding='utf-8').read()
    if 'FlutterFragmentActivity' not in t:
        t = t.replace('io.flutter.embedding.android.FlutterActivity', 'io.flutter.embedding.android.FlutterFragmentActivity').replace('FlutterActivity()', 'FlutterFragmentActivity()')
        open(f, 'w', encoding='utf-8').write(t)
for g in ['android/app/build.gradle.kts', 'android/app/build.gradle']:
    if not os.path.exists(g): continue
    t = open(g, encoding='utf-8').read()
    if 'coreLibraryDesugaring' in t: break
    kts = g.endswith('.kts')
    t = re.sub(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion', 'minSdk = 23' if kts else 'minSdkVersion 23', t)
    t = t.replace('compileOptions {', 'compileOptions {\n        ' + ('isCoreLibraryDesugaringEnabled = true' if kts else 'coreLibraryDesugaringEnabled true'), 1)
    t += '\ndependencies {\n    coreLibraryDesugaring' + ('("com.android.tools:desugar_jdk_libs:2.1.4")\n    implementation("androidx.appcompat:appcompat:1.7.0")' if kts else " 'com.android.tools:desugar_jdk_libs:2.1.4'\n    implementation 'androidx.appcompat:appcompat:1.7.0'") + '\n}\n'
    open(g, 'w', encoding='utf-8').write(t)
    break
# local_auth wymaga motywu AppCompat dla okna odcisku palca / PIN-u
for f in glob.glob('android/app/src/main/res/values*/styles.xml'):
    t = open(f, encoding='utf-8').read()
    night = 'night' in f
    n = re.sub(r'parent="@android:style/Theme\.[A-Za-z.]*(NoTitleBar|NoActionBar)"', 'parent="Theme.AppCompat.NoActionBar"' if night else 'parent="Theme.AppCompat.Light.NoActionBar"', t)
    if n != t:
        open(f, 'w', encoding='utf-8').write(n)
print('Android skonfigurowany')
