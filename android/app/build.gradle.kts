import java.util.Properties
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val localProperties = Properties().apply {
    val propsFile = rootProject.file("local.properties")
    if (propsFile.exists()) {
        propsFile.inputStream().use { load(it) }
    }
}
fun getSigningProperty(name: String): String? {
    return System.getenv(name.uppercase()) 
        ?: localProperties.getProperty(name)
}
android {
    namespace = "com.mrtnetwork.on_chain_wallet"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mrtnetwork.on_chain_wallet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        vectorDrawables.useSupportLibrary = true
    }
  signingConfigs {
        create("release") {
            keyAlias = getSigningProperty("ONCHAIN_KEY_ALIAS")
            keyPassword = getSigningProperty("ONCHAIN_KEY_PASSWORD")
            storePassword = getSigningProperty("ONCHAIN_STORE_PASSWORD")
            val storeFilePath = getSigningProperty("ONCHAIN_STORE_FILE")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
            }

            
        }
    }

    buildTypes {
        getByName("release") {
            val storePassword = getSigningProperty("ONCHAIN_STORE_PASSWORD")

            signingConfig = if (storePassword.isNullOrBlank()) {
                println("⚠️ Release signing keys not found. Using DEBUG signing key.")
                signingConfigs.getByName("debug")
            } else {
                println("✅ Using RELEASE signing key.")
                signingConfigs.getByName("release")
            }
        }
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
}

flutter {
    source = "../.."
}
