import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
// An absent local configuration is intentionally unsigned. An explicitly
// supplied configuration must be complete; never fall back to a debug key.
val releaseSigningProperties = if (keystorePropertiesFile.exists()) {
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").associateWith { key ->
        keystoreProperties.getProperty(key)?.takeIf { it.isNotBlank() }
            ?: throw GradleException("android/key.properties is missing required property: $key")
    }
} else {
    null
}

// `flutter drive`/`flutter test -d <android>` build the same package with an
// integration-test entrypoint and leave it at the same APK output path, so a
// later `flutter install`/`adb install` can put the scripted walkthrough on a
// device in place of the app. The package id must stay unchanged (the test
// runner stops and uninstalls by the id it resolves before building), so the
// launcher label is what marks such a build.
val flutterTarget = (findProperty("target") as String?)?.replace('\\', '/') ?: "lib/main.dart"
val isAppEntrypoint = flutterTarget.endsWith("lib/main.dart")

android {
    namespace = "com.towork.towork"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.towork.towork"
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
        manifestPlaceholders["appLabel"] = if (isAppEntrypoint) "towork" else "towork 自动化测试"
    }

    signingConfigs {
        releaseSigningProperties?.let { properties ->
            create("release") {
                storeFile = file(properties.getValue("storeFile"))
                storePassword = properties.getValue("storePassword")
                keyAlias = properties.getValue("keyAlias")
                keyPassword = properties.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

// 发布包只出 arm64-v8a（docs/release/README.md）。`--target-platform` 只裁剪 Flutter 自身的 so；
// Flutter Gradle 插件又会把 defaultConfig.ndk.abiFilters 重置为默认三种 ABI（与 buildType 的
// abiFilters 取并集），所以 sherpa-onnx 等插件的 armeabi-v7a / x86_64 库（约 48 MB）只能在打包阶段排除。
// 需要全 ABI 的 release（如 x86_64 模拟器）传 -Ptowork.allAbis=true。
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        if (!project.hasProperty("towork.allAbis")) {
            variant.packaging.jniLibs.excludes.addAll(
                listOf("lib/armeabi-v7a/**", "lib/x86_64/**", "lib/x86/**"),
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
