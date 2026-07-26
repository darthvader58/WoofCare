import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val mapsProperties = Properties()
val mapsPropertiesFile = rootProject.file("maps.properties")
if (mapsPropertiesFile.exists()) {
    mapsProperties.load(FileInputStream(mapsPropertiesFile))
}

val googleMapsAndroidApiKey = providers
    .environmentVariable("GOOGLE_MAPS_ANDROID_API_KEY")
    .orElse(providers.gradleProperty("GOOGLE_MAPS_ANDROID_API_KEY"))
    .orElse(mapsProperties.getProperty("GOOGLE_MAPS_API_KEY", ""))
    .get()

if (googleMapsAndroidApiKey.isNotEmpty() && !googleMapsAndroidApiKey.matches(Regex("^[A-Za-z0-9_-]+$"))) {
    throw GradleException("GOOGLE_MAPS_ANDROID_API_KEY contains unexpected characters.")
}

android {
    namespace = "com.epics.woofcare"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.epics.woofcare"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsAndroidApiKey
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsAndroidApp = allTasks.any {
        it.name.startsWith("assemble", ignoreCase = true) ||
            it.name.startsWith("bundle", ignoreCase = true) ||
            it.name.startsWith("install", ignoreCase = true)
    }

    if (buildsAndroidApp && googleMapsAndroidApiKey.isBlank()) {
        throw GradleException(
            "Missing Google Maps Android API key. Set GOOGLE_MAPS_ANDROID_API_KEY " +
                "or create android/maps.properties.",
        )
    }

    if (!hasReleaseSigning && allTasks.any { it.name.contains("Release", ignoreCase = true) }) {
        throw GradleException(
            "Missing android/key.properties. Release builds require the WoofCare signing key.",
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
