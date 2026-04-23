//
// © 2026-present https://github.com/cengiz-pz
//
// download_face_landmarker_model.gradle
//
// Gradle task that downloads the MediaPipe FaceLandmarker model asset
// (face_landmarker.task) into the iOS plugin's bundle resources directory
// if the file is not already present.
//
// Usage
// -----
// To be applied from the root build.gradle or the iOS sub-project's
// build.gradle, then wired as follows:
//
//   apply from: 'download_face_landmarker_model.gradle'
//
//   // Example: run automatically before the Xcode archive step
//   tasks.named("archiveIos") { dependsOn downloadFaceLandmarkerModel }
//
// The task is deliberately idempotent: it checks for the file before
// downloading so repeated builds pay no network cost.
//
// Configuration
// -------------
// Override any of the ext properties below in project's gradle.properties
// or in an ext{} block before applying this file:
//
//   faceLandmarkerModelVersion   – MediaPipe model version tag (default: "latest")
//   faceLandmarkerModelDir       – Destination directory relative to the
//                                  project root (default shown below)
//

// -- Configurable properties ------------------------------------------------

// Directory (relative to the Gradle project root) where the model will be
// placed. Adjust to match Xcode target's "Copy Bundle Resources" source
// folder.
val modelDir =
    (project.findProperty("faceLandmarkerModelDir") as? String)
        ?: "plugin/src/main/ios/Resources"

// MediaPipe model version. "latest" resolves to the most recent published
// float16 variant. Pin to a specific version (e.g. "1.0.1") for
// reproducible builds.
val modelVersion =
    (project.findProperty("faceLandmarkerModelVersion") as? String)
        ?: "latest"

val modelFileName = "face_landmarker.task"

// Canonical download URL published by Google AI Edge.
// The URL pattern is stable across versions; only the version segment changes.
val modelUrl =
    "https://storage.googleapis.com/mediapipe-models/" +
        "face_landmarker/face_landmarker/float16/$modelVersion/$modelFileName"

// -- Derived paths ----------------------------------------------------------

val modelDestDir = file("${project.projectDir}/$modelDir")
val modelDestFile = file("$modelDestDir/$modelFileName")

// -- Task -------------------------------------------------------------------

//
// Sample downloadFaceLandmarkerModel task
//
// Downloads face_landmarker.task from the Google AI Edge model repository
// into the iOS bundle resources directory.  The download is skipped when the
// file already exists, making this task safe to declare as a dependency of
// any other task without incurring unnecessary network requests.
//
tasks.register("downloadFaceLandmarkerModel") {
    group = "Vision Plugin"
    description = "Downloads the model for the iOS Vision plugin"

    val modelDestFile = file("$buildDir/models/face_landmarker.task")
    val modelUrl = "https://example.com/face_landmarker.task"

    // Declare inputs/outputs for Gradle's UP-TO-DATE checks
    inputs.property("url", modelUrl)
    outputs.file(modelDestFile)

    doLast {
        if (modelDestFile.exists() && modelDestFile.length() > 0) {
            logger.lifecycle("[VisionPlugin] Model already present — skipping download.")
            return@doLast
        }

        logger.lifecycle("[VisionPlugin] Downloading model...")
        modelDestFile.parentFile.mkdirs()

        try {
            // Kotlin's native extension functions make stream copying clean
            java.net.URL(modelUrl).openStream().use { input ->
                modelDestFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        } catch (e: Exception) {
            throw GradleException("Download failed for URL: $modelUrl", e)
        }

        if (!modelDestFile.exists() || modelDestFile.length() == 0L) {
            throw GradleException("Download failed or produced an empty file.")
        }

        logger.lifecycle("[VisionPlugin] Download complete.")
    }
}
