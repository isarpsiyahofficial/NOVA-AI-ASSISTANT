package com.example.nova

import android.content.Context
import java.io.File

object NovaAppSandboxGuard {

    private val allowedMediaPackages = setOf(
        "com.spotify.music",
        "com.google.android.apps.youtube.music",
    )

    fun sanitizeOutputName(raw: String, fallback: String): String {
        val cleaned = raw.trim()
            .replace(Regex("[^A-Za-z0-9._-]+"), "_")
            .trim('_', '.', ' ')
            .take(64)
        return cleaned.ifBlank { fallback }
    }

    fun isAllowedMediaPackage(packageName: String): Boolean {
        val normalized = packageName.trim()
        return allowedMediaPackages.contains(normalized)
    }

    fun resolveAppPrivateFileOrNull(
        context: Context,
        rawReference: String,
        allowDirectories: Boolean = false,
    ): File? {
        val normalized = rawReference.trim()
        if (normalized.isEmpty()) return null

        val candidate = if (normalized.startsWith("/")) {
            File(normalized)
        } else {
            File(context.filesDir, normalized)
        }

        val canonicalCandidate = runCatching { candidate.canonicalFile }.getOrNull() ?: return null
        val allowedRoots = appPrivateRoots(context)
        val withinRoot = allowedRoots.any { root ->
            val canonicalRoot = runCatching { root.canonicalFile }.getOrNull() ?: return@any false
            val rootPath = canonicalRoot.path
            val candidatePath = canonicalCandidate.path
            candidatePath == rootPath || candidatePath.startsWith("$rootPath${File.separator}")
        }

        if (!withinRoot) return null
        if (!allowDirectories && canonicalCandidate.isDirectory) return null
        return canonicalCandidate
    }

    fun toAppRelativeReference(context: Context, file: File): String {
        val canonicalFile = runCatching { file.canonicalFile }.getOrNull() ?: file
        val filesRoot = runCatching { context.filesDir.canonicalFile }.getOrNull() ?: context.filesDir
        val filePath = canonicalFile.path
        val rootPath = filesRoot.path
        return if (filePath.startsWith(rootPath + File.separator)) {
            filePath.removePrefix(rootPath + File.separator)
        } else {
            canonicalFile.name
        }
    }

    fun appPrivateRoots(context: Context): List<File> {
        return listOfNotNull(
            context.filesDir,
            context.cacheDir,
            context.codeCacheDir,
            context.noBackupFilesDir,
        ).distinctBy { root -> runCatching { root.canonicalPath }.getOrElse { root.path } }
    }
}
