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
// afterEvaluate registered BEFORE evaluationDependsOn so hooks fire when subprojects are evaluated
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class)?.run {
            val current = compileSdkVersion?.removePrefix("android-")?.toIntOrNull() ?: 0
            if (current < 34) {
                compileSdkVersion(34)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
