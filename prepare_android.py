import os
import re
import sys
import xml.etree.ElementTree as ET

def patch_app_build_gradle():
    print("=== Patching app/build.gradle(.kts) ===")
    kts_path = "android/app/build.gradle.kts"
    groovy_path = "android/app/build.gradle"
    
    if os.path.exists(kts_path):
        print(f"Found Kotlin DSL: {kts_path}")
        with open(kts_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        content = re.sub(r'compileSdk\s*=\s*(?:flutter\.compileSdkVersion|\d+)', 'compileSdk = 34', content)
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
            
        if "desugar_jdk_libs" not in content:
            content += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n'
            
        with open(kts_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Patched app/build.gradle.kts successfully!")
        
    elif os.path.exists(groovy_path):
        print(f"Found Groovy DSL: {groovy_path}")
        with open(groovy_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        content = re.sub(r'compileSdkVersion\s+(?:flutter\.compileSdkVersion|\d+)', 'compileSdkVersion 34', content)
        content = re.sub(r'targetSdkVersion\s+(?:flutter\.targetSdkVersion|\d+)', 'targetSdkVersion 34', content)
        content = re.sub(r'minSdkVersion\s+(?:flutter\.minSdkVersion|\d+)', 'minSdkVersion 24', content)
        content = re.sub(r'compileSdk\s+(?:flutter\.compileSdkVersion|\d+)', 'compileSdk 34', content)
        content = re.sub(r'minSdk\s+(?:flutter\.minSdkVersion|\d+)', 'minSdk 24', content)
        
        if "multiDexEnabled" not in content:
            content = content.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled true")
            
        if "coreLibraryDesugaringEnabled" not in content:
            content = re.sub(
                r'compileOptions\s*\{',
                'compileOptions {\n        coreLibraryDesugaringEnabled true',
                content
            )
            
        if "desugar_jdk_libs" not in content:
            content += '\ndependencies {\n    coreLibraryDesugaring \'com.android.tools:desugar_jdk_libs:2.0.4\'\n}\n'
            
        with open(groovy_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Patched app/build.gradle successfully!")

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
    print("=== Patching pub-cache plugin build.gradle files ===")
    search_paths = []
    
    # 1. ~/.pub-cache
    home_cache = os.path.expanduser("~/.pub-cache")
    if os.path.exists(home_cache):
        search_paths.append(home_cache)
        
    # 2. $PUB_CACHE env var
    env_cache = os.environ.get("PUB_CACHE")
    if env_cache and os.path.exists(env_cache) and env_cache not in search_paths:
        search_paths.append(env_cache)
        
    # 3. /home/runner/.pub-cache (GitHub Actions standard)
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
                        
                        # Replace compileSdkVersion 30, 31, 32, 33 with 34
                        new_text = re.sub(
                            r'compileSdkVersion\s+(?:2[0-9]|3[0-3])\b',
                            'compileSdkVersion 34',
                            text
                        )
                        new_text = re.sub(
                            r'compileSdk\s*=\s*(?:2[0-9]|3[0-3])\b',
                            'compileSdk = 34',
                            new_text
                        )
                        if new_text != text:
                            with open(path, "w", encoding="utf-8") as f:
                                f.write(new_text)
                            print(f"  -> Upgraded compileSdk to 34 in: {file} ({os.path.basename(os.path.dirname(root))})")
                            count += 1
                    except Exception:
                        pass
                        
    print(f"=== Successfully patched {count} plugin files in pub-cache! ===")

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "--all"
    if mode in ("--project-only", "--all"):
        patch_app_build_gradle()
        patch_manifest()
    if mode in ("--cache-only", "--all"):
        patch_pub_cache()
