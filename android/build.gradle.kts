allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    when {
        project.name == "file_picker" || project.name == "mobile_scanner" -> {
            plugins.apply("org.jetbrains.kotlin.android")
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
