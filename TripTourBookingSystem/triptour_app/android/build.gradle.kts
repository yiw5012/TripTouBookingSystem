allprojects {
    repositories {
        google()
        mavenCentral()
    }
}



val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")
        classpath("com.google.gms:google-services:4.3.15")
    }
}
subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.15.0")
            force("androidx.core:core-ktx:1.15.0")
            force("androidx.activity:activity:1.9.3")
            force("androidx.browser:browser:1.8.0")
        }
    }
}