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

        versionCode = 1
        versionName = "1.0"

        // Hỗ trợ cả ARM (điện thoại thật) và x86_64 (emulator)
        // TFLite Flex sẽ chỉ hoạt động trên ARM
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
        }
    }

    packaging {
        jniLibs.useLegacyPackaging = true
        
        // Xử lý trùng lặp native libraries
        jniLibs.pickFirsts += listOf(
            "**/libtensorflowlite_jni.so",
            "**/libtensorflowlite_c.so",
            "**/libtensorflowlite_flex.so",
            "**/libtensorflowlite_flex_jni.so",
            "**/libtensorflowlite_flex_c.so",
            "**/libc++_shared.so"
        )
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

// Loại bỏ LiteRT để tránh xung đột với TensorFlow Lite
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
