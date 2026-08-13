pluginManagement {
        val flutterSdkPath = run {
                    val properties = java.util.Properties()
                            file("local.properties").inputStream().use { properties.load(it) }
                                    val flutterSdkPath = properties.getProperty("flutter.sdk")
                                            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
                                                    flutterSdkPath
        }

            includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

                repositories {
                            google()
                                    mavenCentral()
                                            gradlePluginPortal()
                }
}

plugins {
        id("dev.flutter.flutter-plugin-loader") version "1.0.0"

            // Compatible with the Flutter version used by CI
                id("com.android.application") version "8.11.1" apply false

                    // Firebase
                        id("com.google.gms.google-services") version "4.3.15" apply false

                            // Flutter 3.47 requires Kotlin >= 2.2.20
                                id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
}
                }
        }
}
