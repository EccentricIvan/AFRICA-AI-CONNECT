allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (file_picker 8.x) still declare compileSdk 34, which fails
// the AAR metadata check against libraries built for 36. Force 36 everywhere.
subprojects {
    // :app is force-evaluated above and already uses compileSdk 36;
    // afterEvaluate would throw on an already-evaluated project.
    if (state.executed) return@subprojects
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            val setCompileSdk = ext.javaClass.methods.firstOrNull {
                it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1 &&
                    it.parameterTypes[0] == Int::class.javaPrimitiveType
            }
            setCompileSdk?.invoke(ext, 36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
