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
        if 'inifyEnabled' not in t:
            add = 'isMinifyEnabled = false\n            isShrinkResources = false\n            ' if kts else 'minifyEnabled false\n            shrinkResources false\n            '
            t = re.sub(r'(release\s*\{)', lambda m: m.group(1) + '\n            ' + add, t, count=1)
        open(g, 'w').write(t)
        print(t)
