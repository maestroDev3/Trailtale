plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release key from the environment (CI: GitHub secrets). Without it, release
// builds fall back to the debug key, which differs per machine – such APKs
// cannot update an installed app.
val releaseKeystore = System.getenv("ANDROID_KEYSTORE_PATH")?.let { file(it) }?.takeIf { it.exists() }

android {
    namespace = "de.maestrodev.trailtale"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "de.maestrodev.trailtale"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKeystore != null) {
            // Values are trimmed (secrets pasted on a phone often end with a
            // space or line break). A PKCS12 keystore uses the store password
            // for its key, so it is the fallback for a missing key password.
            val storeSecret = System.getenv("ANDROID_KEYSTORE_PASSWORD")?.trim()
            create("release") {
                storeFile = releaseKeystore
                storePassword = storeSecret
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")?.trim()
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")?.trim()?.takeIf { it.isNotEmpty() }
                    ?: storeSecret
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeystore != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
