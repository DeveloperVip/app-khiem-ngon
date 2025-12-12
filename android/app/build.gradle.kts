plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_application_initial"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.flutter_application_initial"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = 7
        versionName = "1.6"

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
        }
    }

    // Định nghĩa signing config debug
    signingConfigs {
        getByName("debug") {
            // Flutter tự động cung cấp keystore debug
        }
    }

    buildTypes {
        release {
            // QUAN TRỌNG: Dùng debug key ký cho release để cài được ngay
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    packaging {
        jniLibs.useLegacyPackaging = true
        jniLibs.pickFirsts += listOf(
            "**/libtensorflowlite_jni.so",
            "**/libc++_shared.so"
        )
    }
}

configurations.all {
    exclude(group = "com.google.ai.edge.litert")
    exclude(group = "com.google.ai.edge.litert", module = "litert")
    exclude(group = "com.google.ai.edge.litert", module = "litert-api")
}

flutter {
    source = "../.."
}

dependencies {
    // TensorFlow Lite - sẽ chỉ có native libs cho ARM
    // App sẽ vẫn chạy trên x86 nhưng không có ML
    implementation("org.tensorflow:tensorflow-lite:2.14.0") {
        exclude(group = "com.google.ai.edge.litert")
    }
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.14.0") {
        exclude(group = "com.google.ai.edge.litert")
    }
}
