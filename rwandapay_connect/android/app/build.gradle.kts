plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "cc.rwandapay.rwandapay_connect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "cc.rwandapay.rwandapay_connect"
        // mobile_scanner (Scan to Pay) requires API 21+; Flutter's own default
        // of 24 already clears that, so the framework default is kept.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug keys, so `flutter build apk --release` works without a
            // keystore. Fine for a classroom demo and for sideloading onto a
            // phone; a Play Store upload would need a real signing config.
            signingConfig = signingConfigs.getByName("debug")

            // ML Kit's barcode scanner ships its own consumer ProGuard rules,
            // so shrinking is safe to leave on for a smaller APK.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
