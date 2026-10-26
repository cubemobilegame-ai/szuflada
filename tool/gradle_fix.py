"""compileSdk 36 dla wszystkich wtyczek i wylaczenie R8 (ML Kit). Idempotentne."""
import re, os
KTS = '''subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            extensions.configure<com.android.build.gradle.BaseExtension> { compileSdkVersion(36) }
        }
    }
}
'''
GRV = '''subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android { compileSdkVersion 36 }
        }
    }
}
'''
for g, kts in [('android/build.gradle.kts', 1), ('android/build.gradle', 0)]:
    if os.path.exists(g):
        t = open(g).read()
        if 'compileSdkVersion' not in t:
            open(g, 'w').write((KTS if kts else GRV) + '\n' + t)
for g, kts in [('android/app/build.gradle.kts', 1), ('android/app/build.gradle', 0)]:
    if os.path.exists(g):
        t = open(g).read()
        t = re.sub(r'compileSdk(Version)?\s*=?\s*flutter\.compileSdkVersion', 'compileSdk = 36' if kts else 'compileSdk 36', t)
        # Google Play: nowe aplikacje musza celowac w Android 16 (API 36)
        t = re.sub(r'targetSdk(Version)?\s*=?\s*flutter\.targetSdkVersion', 'targetSdk = 36' if kts else 'targetSdkVersion 36', t)
        if 'inifyEnabled' not in t:
            add = 'isMinifyEnabled = false\n            isShrinkResources = false\n            ' if kts else 'minifyEnabled false\n            shrinkResources false\n            '
            t = re.sub(r'(release\s*\{)', lambda m: m.group(1) + '\n            ' + add, t, count=1)
        open(g, 'w').write(t)
        print(t)

# Podpis wydania kluczem z sekretów GitHuba (SZ_KEYSTORE = ścieżka do pliku, SZ_KEY_PASS = hasło)
ks = os.environ.get('SZ_KEYSTORE', '')
if ks and os.path.exists(ks):
    for g, kts in [('android/app/build.gradle.kts', 1), ('android/app/build.gradle', 0)]:
        if not os.path.exists(g):
            continue
        t = open(g).read()
        if 'SZ_KEY_PASS' in t:
            continue
        if kts:
            cfg = '''    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("SZ_KEYSTORE"))
            storePassword = System.getenv("SZ_KEY_PASS")
            keyAlias = "upload"
            keyPassword = System.getenv("SZ_KEY_PASS")
        }
    }
'''
            t = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")', t)
        else:
            cfg = '''    signingConfigs {
        release {
            storeFile file(System.getenv("SZ_KEYSTORE"))
            storePassword System.getenv("SZ_KEY_PASS")
            keyAlias "upload"
            keyPassword System.getenv("SZ_KEY_PASS")
        }
    }
'''
            t = re.sub(r'signingConfig\s+signingConfigs\.debug', 'signingConfig signingConfigs.release', t)
        t = re.sub(r'(\n\s*buildTypes\s*\{)', '\n' + cfg.rstrip('\n') + r'\1', t, count=1)
        open(g, 'w').write(t)
        print('PODPIS: klucz upload ustawiony w', g)
else:
    print('PODPIS: brak sekretu SZ_KEYSTORE_B64 - wydanie podpisane kluczem testowym')
