// Updated 7/20/2026
//   Upgraded to Gradle 9.5.0, removed KGP
//   https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // Removed for Gradle 9.5.0
    //id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "net.digitaleagle.lbc.harbor_connect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Changed from version 11 to version 17 for Gradle 9.5.0
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Removed for upgrade to Gradle 9.5.0 (moved to end)
//    kotlinOptions {
//        jvmTarget = JavaVersion.VERSION_11.toString()
//    }

    defaultConfig {
        applicationId = "net.digitaleagle.lbc.harbor_connect"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            // Links the release signing configuration we created above
            signingConfig = signingConfigs.getByName("release")

            // Your other production settings...
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// moved kotlinOptions to here for Gradle 9.5.0
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
