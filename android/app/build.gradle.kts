import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Create a Properties instance
val keystoreProperties = Properties()

// Load properties from the keystore file if it exists
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { inputStream ->
        keystoreProperties.load(inputStream)
    }
}

android {
    namespace = "com.magdata.registraTeApp"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        multiDexEnabled = true
        applicationId = "com.magdata.registraTeApp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 28
        versionName = "1.2.7"
        // Ship only the ABIs you need (Play will deliver per-ABI automatically for AAB)
        ndk {
            // For release, these two are usually enough
            abiFilters.clear()
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    packaging {
        // DO NOT touch libflutter.so under resources; JNI libs are handled below.
        resources {
            // If you had broad excludes, keep them conservative and never exclude **/*.so
            // excludes += listOf("META-INF/LICENSE*", "META-INF/AL2.0", "META-INF/LGPL2.1")
        }
        jniLibs {
            // Default is fine; don’t exclude libflutter.so
            // useLegacyPackaging = false // default; usually leave as-is
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { File(it.toString()) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}