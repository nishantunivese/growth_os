import os
import re
import sys

def patch_android():
    print("=== Patching Android Configuration ===")
    
    # 1. Check for build.gradle or build.gradle.kts
    groovy_path = "android/app/build.gradle"
    kts_path = "android/app/build.gradle.kts"
    
    if os.path.exists(kts_path):
        print(f"Found Kotlin DSL: {kts_path}")
        with open(kts_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Replace minSdk
        content = re.sub(r'minSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)', 'minSdk = 24', content)
        
        # Ensure multiDexEnabled
        if "multiDexEnabled" not in content:
            content = content.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled = true")
            
        # Ensure coreLibraryDesugaring
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
            
        # Replace minSdkVersion
        content = re.sub(r'minSdkVersion\s+(?:flutter\.minSdkVersion|\d+)', 'minSdkVersion 24', content)
        content = re.sub(r'minSdk\s+(?:flutter\.minSdkVersion|\d+)', 'minSdk 24', content)
        
        # Ensure multiDexEnabled
        if "multiDexEnabled" not in content:
            content = content.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled true")
            
        # Ensure coreLibraryDesugaring
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
    else:
        print("ERROR: Neither app/build.gradle nor app/build.gradle.kts found!")
        sys.exit(1)

    # 2. Patch AndroidManifest.xml if custom permissions missing
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = f.read()
            
        permissions = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>
"""
        if "POST_NOTIFICATIONS" not in manifest:
            manifest = manifest.replace("<manifest", f"<manifest{permissions}")
            with open(manifest_path, "w", encoding="utf-8") as f:
                f.write(manifest)
            print("Injected permissions into AndroidManifest.xml")
            
    print("=== Patch complete! ===")

if __name__ == "__main__":
    patch_android()
