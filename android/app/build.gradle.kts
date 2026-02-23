plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.eventlens"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Enable core library desugaring for QR scanner compatibility
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.eventlens"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        
        // ARCore requires minimum Android 7.0 (API 24)
        // flutter.minSdkVersion defaults to 21, must override for ARCore
        minSdk = 24
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Unity AR Foundation NDK configuration
        ndk {
            abiFilters.add("armeabi-v7a")
            abiFilters.add("arm64-v8a")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // Unity library packaging configuration
    packagingOptions {
        resources.pickFirsts.add("lib/armeabi-v7a/libc++_shared.so")
        resources.pickFirsts.add("lib/arm64-v8a/libc++_shared.so")
        resources.pickFirsts.add("lib/x86/libc++_shared.so")
        resources.pickFirsts.add("lib/x86_64/libc++_shared.so")
    }
}

dependencies {
    implementation(project(":unityLibrary"))
    // Core library desugaring for QR scanner compatibility
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.1.5")
}

flutter {
    source = "../.."
}
apply(plugin = "com.google.gms.google-services")