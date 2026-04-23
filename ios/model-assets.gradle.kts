//
// © 2026-present https://github.com/cengiz-pz
//

tasks {
    val repositoryRootDir: String by project.extra
    val pluginName: String by project.extra

    register<Delete>("cleanModelAssets") {
        val targetDir = file("$repositoryRootDir/common/build/plugin/ios/assets/$pluginName")
        delete(targetDir)
    }

    register<Delete>("cleanDemoModelAssets") {
        val targetDir = file("$repositoryRootDir/demo/assets/$pluginName")
        delete(targetDir)
    }

    register<Copy>("copyModelAssets") {
        description = "Copies the model assets to the plugin's assets directory"
        dependsOn("cleanModelAssets")

        val sourceDir = file("$repositoryRootDir/ios/assets")
        val targetDir = file("$repositoryRootDir/common/build/plugin/ios/assets/$pluginName")

        from(sourceDir)
        into(targetDir)
    }

    register<Copy>("installModelAssetsToDemo") {
        description = "Copies the model assets to the demo's assets directory"
        dependsOn("cleanModelAssets")

        val sourceDir = file("$repositoryRootDir/common/build/plugin/ios/assets/$pluginName")
        val targetDir = file("$repositoryRootDir/demo/assets/$pluginName")

        from(sourceDir)
        into(targetDir)
    }
}

gradle.projectsEvaluated {
    project(":addon").tasks.named("cleanOutput").configure {
        finalizedBy(project(":ios").tasks.named("cleanModelAssets"))
    }

    project(":ios").tasks.named("uninstalliOS").configure {
        finalizedBy("cleanDemoModelAssets")
    }

    project(":addon").tasks.named("generateGDScript").configure {
        finalizedBy(project(":ios").tasks.named("copyModelAssets"))
    }

    project(":ios").tasks.named("installToDemoiOS").configure {
        finalizedBy("installModelAssetsToDemo")
    }

    listOf(
        project(":ios").tasks.named("buildiOSDebug"),
        project(":ios").tasks.named("buildiOSDebugSimulator"),
        project(":ios").tasks.named("buildiOSRelease"),
        project(":ios").tasks.named("buildiOSReleaseSimulator"),
    ).forEach { provider ->
        provider.configure {
            mustRunAfter("copyModelAssets")
        }
    }
}
