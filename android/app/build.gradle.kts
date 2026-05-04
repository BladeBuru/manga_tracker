import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Charger les propriétés de signature
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { 
        keystoreProperties.load(it) 
    }
}

android {
    namespace = "com.example.manga_tracker"
    compileSdk = flutter.compileSdkVersion
    //ndkVersion = flutter.ndkVersion
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
        applicationId = "com.example.manga_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationId = "com.example.manga_tracker.dev"
            versionNameSuffix = "-dev"
        }
        create("prod") {
            dimension = "env"
            applicationId = "com.example.manga_tracker"
        }
    }

    signingConfigs {
        // Configuration de signature pour la production
        if (keystorePropertiesFile.exists() || 
            System.getenv("KEYSTORE_BASE64") != null) {
            create("release") {
                if (keystorePropertiesFile.exists()) {
                    // Utilisation du fichier key.properties en local
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                    // Le chemin dans key.properties est relatif au module app (android/app/)
                    val keystorePath = keystoreProperties["storeFile"] as String
                    storeFile = file(keystorePath)
                    storePassword = keystoreProperties["storePassword"] as String
                } else {
                    // Utilisation des variables d'environnement (CI/CD)
                    val keystorePath = "${rootProject.projectDir}/keystore.jks"
                    keyAlias = System.getenv("KEY_ALIAS") ?: "upload"
                    keyPassword = System.getenv("KEY_PASSWORD") ?: ""
                    storeFile = file(keystorePath)
                    storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
                }
            }
        }
    }

    buildTypes {
        release {
            // Utiliser la clé de signature si disponible, sinon utiliser la clé debug
            if (keystorePropertiesFile.exists() || 
                System.getenv("KEYSTORE_BASE64") != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback sur la clé debug pour les builds locaux sans configuration
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

// Créer une copie de l'APK avec le nom MangaTracker.apk après le build
tasks.register("copyProdReleaseApk") {
    doLast {
        val apkFile = file("${project.buildDir}/outputs/flutter-apk/app-prod-release.apk")
        val newApkFile = file("${project.buildDir}/outputs/flutter-apk/MangaTracker.apk")
        if (apkFile.exists()) {
            apkFile.copyTo(newApkFile, overwrite = true)
            println("✅ APK copié en MangaTracker.apk")
        }
    }
}

afterEvaluate {
    val assembleTask = tasks.named("assembleProdRelease").get()
    assembleTask.finalizedBy("copyProdReleaseApk")
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
