plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

repositories {
    flatDir {
        dirs("libs")
    }
}

dependencies {
    // API-first Nova detaches the heavy Gemma/LiteRT-LM local brain runtime.
    // Local ears/identity stay native: sherpa-onnx.aar is required for embedded
    // sherpa_asr and nemo_en_titanet_small speaker verification. Place it under
    // android/app/libs/sherpa-onnx.aar together with the existing JNI libs/models.
    implementation(files("libs/sherpa-onnx.aar"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
}

android {
    namespace = "com.example.nova"
    compileSdk = 35
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.example.nova"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        externalNativeBuild {
            cmake {
                arguments += listOf(
                    "-DNOVA_FAISS_ROOT_DIR=${projectDir}/src/main/cpp/third_party/faiss"
                )
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }

    androidResources {
        noCompress += "onnx"
        noCompress += "json"
        noCompress += "txt"
        noCompress += "bin"
        noCompress += "piece"
        noCompress += "spm"
        noCompress += "ort"
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
