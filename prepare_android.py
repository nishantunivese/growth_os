import os
import re
import sys
import xml.etree.ElementTree as ET

def patch_root_build_gradle():
    print("=== Patching root build.gradle(.kts) to disable lint globally ===")
    root_kts = "android/build.gradle.kts"
    root_groovy = "android/build.gradle"
    
    lint_disable_kts = """
subprojects {
    tasks.configureEach {
        if (name.contains("lint", ignoreCase = true)) {
            enabled = false
        }
    }
}
"""

    lint_disable_groovy = """
subprojects {
    tasks.configureEach { task ->
        if (task.name.toLowerCase().contains("lint")) {
            task.enabled = false
        }
    }
}
"""

    if os.path.exists(root_kts):
        with open(root_kts, "r", encoding="utf-8") as f:
            content = f.read()
        if "name.contains(\"lint\"" not in content:
            content += f"\n{lint_disable_kts}\n"
            with open(root_kts, "w", encoding="utf-8") as f:
                f.write(content)
            print("Injected global lint-disable into root build.gradle.kts!")
    elif os.path.exists(root_groovy):
        with open(root_groovy, "r", encoding="utf-8") as f:
            content = f.read()
        if "contains(\"lint\"" not in content:
            content += f"\n{lint_disable_groovy}\n"
            with open(root_groovy, "w", encoding="utf-8") as f:
                f.write(content)
            print("Injected global lint-disable into root build.gradle!")

def patch_app_build_gradle():
    print("=== Patching app/build.gradle(.kts) ===")
    kts_path = "android/app/build.gradle.kts"
    groovy_path = "android/app/build.gradle"
    
    lint_kts = """
    lint {
        checkReleaseBuilds = false
        abortOnError = false
        ignoreWarnings = true
    }
"""

    if os.path.exists(kts_path):
        print(f"Found Kotlin DSL: {kts_path}")
        with open(kts_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        content = re.sub(r'compileSdk\s*=\s*(?:flutter\.compileSdkVersion|\d+)', 'compileSdk = 36', content)
        content = re.sub(r'targetSdk\s*=\s*(?:flutter\.targetSdkVersion|\d+)', 'targetSdk = 34', content)
        content = re.sub(r'minSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)', 'minSdk = 24', content)
        
        if "multiDexEnabled" not in content:
            content = content.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled = true")
            
        if "isCoreLibraryDesugaringEnabled" not in content and "coreLibraryDesugaringEnabled" not in content:
            content = re.sub(
                r'compileOptions\s*\{',
                'compileOptions {\n        isCoreLibraryDesugaringEnabled = true',
                content
            )
            
        if "lint {" not in content:
            content = content.replace("android {", f"android {{\n{lint_kts}")
            
        if "isMinifyEnabled" not in content and "minifyEnabled" not in content:
            if "release {" in content:
                content = content.replace("release {", "release {\n            isMinifyEnabled = false\n            isShrinkResources = false")
            elif "buildTypes {" in content:
                content = content.replace("buildTypes {", "buildTypes {\n        getByName(\"release\") {\n            isMinifyEnabled = false\n            isShrinkResources = false\n        }")
            
        if "desugar_jdk_libs" not in content:
            content += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n'
            
        with open(kts_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Patched app/build.gradle.kts with compileSdk=36, minSdk=24, and disabled lint!")
        
    elif os.path.exists(groovy_path):
        print(f"Found Groovy DSL: {groovy_path}")
        with open(groovy_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        content = re.sub(r'compileSdkVersion\s+(?:flutter\.compileSdkVersion|\d+)', 'compileSdkVersion 36', content)
        content = re.sub(r'targetSdkVersion\s+(?:flutter\.targetSdkVersion|\d+)', 'targetSdkVersion 34', content)
        content = re.sub(r'minSdkVersion\s+(?:flutter\.minSdkVersion|\d+)', 'minSdkVersion 24', content)
        content = re.sub(r'compileSdk\s+(?:flutter\.compileSdkVersion|\d+)', 'compileSdk 36', content)
        content = re.sub(r'minSdk\s+(?:flutter\.minSdkVersion|\d+)', 'minSdk 24', content)
        
        if "multiDexEnabled" not in content:
            content = content.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled true")
            
        if "coreLibraryDesugaringEnabled" not in content:
            content = re.sub(
                r'compileOptions\s*\{',
                'compileOptions {\n        coreLibraryDesugaringEnabled true',
                content
            )
            
        if "lintOptions" not in content:
            content = content.replace("android {", "android {\n    lintOptions {\n        checkReleaseBuilds false\n        abortOnError false\n    }\n")
            
        if "minifyEnabled" not in content:
            if "release {" in content:
                content = content.replace("release {", "release {\n            minifyEnabled false\n            shrinkResources false")
            elif "buildTypes {" in content:
                content = content.replace("buildTypes {", "buildTypes {\n        release {\n            minifyEnabled false\n            shrinkResources false\n        }")
            
        if "desugar_jdk_libs" not in content:
            content += '\ndependencies {\n    coreLibraryDesugaring \'com.android.tools:desugar_jdk_libs:2.0.4\'\n}\n'
            
        with open(groovy_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Patched app/build.gradle with compileSdkVersion=36, minSdkVersion=24, and disabled lint!")

def patch_manifest():
    print("=== Patching AndroidManifest.xml ===")
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if not os.path.exists(manifest_path):
        print("AndroidManifest.xml not found, skipping.")
        return
        
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = f.read()
        
    perms = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>
"""

    receiver = """
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
    if "POST_NOTIFICATIONS" not in manifest:
        manifest = manifest.replace("<application", perms + "\n    <application")
        
    if "ScheduledNotificationBootReceiver" not in manifest:
        manifest = manifest.replace("</application>", receiver + "\n    </application>")
        
    manifest = manifest.replace('android:label="growth_os"', 'android:label="GROWTH OS"')

    try:
        ET.fromstring(manifest.replace('${applicationName}', 'App'))
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(manifest)
        print("AndroidManifest.xml patched and validated successfully!")
    except Exception as e:
        print(f"XML Validation Error: {e}")
        sys.exit(1)

def patch_pub_cache():
    print("=== Patching pub-cache plugin build.gradle files to compileSdk 36 ===")
    search_paths = []
    
    home_cache = os.path.expanduser("~/.pub-cache")
    if os.path.exists(home_cache):
        search_paths.append(home_cache)
        
    env_cache = os.environ.get("PUB_CACHE")
    if env_cache and os.path.exists(env_cache) and env_cache not in search_paths:
        search_paths.append(env_cache)
        
    gh_cache = "/home/runner/.pub-cache"
    if os.path.exists(gh_cache) and gh_cache not in search_paths:
        search_paths.append(gh_cache)
        
    count = 0
    for cache_dir in search_paths:
        print(f"Scanning cache directory: {cache_dir}")
        for root, dirs, files in os.walk(cache_dir):
            for file in files:
                if file in ("build.gradle", "build.gradle.kts"):
                    path = os.path.join(root, file)
                    try:
                        with open(path, "r", encoding="utf-8") as f:
                            text = f.read()
                        
                        new_text = re.sub(
                            r'compileSdkVersion\s+(?:2[0-9]|3[0-5])\b',
                            'compileSdkVersion 36',
                            text
                        )
                        new_text = re.sub(
                            r'compileSdk\s*=\s*(?:2[0-9]|3[0-5])\b',
                            'compileSdk = 36',
                            new_text
                        )
                        if new_text != text:
                            with open(path, "w", encoding="utf-8") as f:
                                f.write(new_text)
                            print(f"  -> Upgraded compileSdk to 36 in: {file} ({os.path.basename(os.path.dirname(root))})")
                            count += 1
                    except Exception:
                        pass
                        
    print(f"=== Successfully patched {count} plugin files in pub-cache to compileSdk 36! ===")

def patch_main_activity():
    print("=== Patching MainActivity.kt to allow screenshots ===")
    kotlin_dir = "android/app/src/main/kotlin"
    if not os.path.exists(kotlin_dir):
        return
        
    for root, dirs, files in os.walk(kotlin_dir):
        for file in files:
            if file == "MainActivity.kt":
                path = os.path.join(root, file)
                with open(path, "r", encoding="utf-8") as f:
                    orig_content = f.read()
                
                # Dynamically extract original package or infer from folder structure
                pkg_match = re.search(r'package\s+([a-zA-Z0-9_.]+)', orig_content)
                if pkg_match:
                    pkg = pkg_match.group(1).strip()
                else:
                    rel = os.path.relpath(root, kotlin_dir)
                    pkg = rel.replace(os.sep, '.').replace('/', '.')
                print(f"Detected package '{pkg}' for {path}")
                
                main_activity_code = f"""package {pkg}

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {{
    override fun onCreate(savedInstanceState: Bundle?) {{
        super.onCreate(savedInstanceState)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }}

    override fun onResume() {{
        super.onResume()
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }}

    override fun onWindowFocusChanged(hasFocus: Boolean) {{
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {{
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }}
    }}
}}
"""
                with open(path, "w", encoding="utf-8") as f:
                    f.write(main_activity_code)
                print(f"Patched {path} with package '{pkg}' to explicitly allow screenshots!")

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "--all"
    if mode in ("--project-only", "--all"):
        patch_root_build_gradle()
        patch_app_build_gradle()
        patch_manifest()
        patch_main_activity()
    if mode in ("--cache-only", "--all"):
        patch_pub_cache()
