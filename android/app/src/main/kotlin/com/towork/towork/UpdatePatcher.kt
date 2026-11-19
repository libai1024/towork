package com.towork.towork

import android.content.Context
import android.os.StatFs
import com.github.sisong.HPatch
import java.io.File
import java.util.concurrent.Executors

/** Applies a verified HDiffPatch to the installed base APK on one worker. */
object UpdatePatcher {
    val executor = Executors.newSingleThreadExecutor()
    private var cachedSource = ""
    private var cachedHash = ""

    fun installedHash(context: Context): String {
        if (!context.applicationInfo.splitSourceDirs.isNullOrEmpty()) return ""
        val source = File(context.applicationInfo.sourceDir)
        val key = "${source.path}:${source.length()}:${source.lastModified()}"
        if (key != cachedSource) {
            cachedHash = UpdateInstaller.fileHash(source)
            cachedSource = key
        }
        return cachedHash
    }

    fun apply(context: Context, arguments: Map<*, *>) {
        fun text(key: String) = arguments[key] as? String ?: throw UpdateException("file_invalid")
        fun number(key: String) = (arguments[key] as? Number)?.toLong() ?: throw UpdateException("file_invalid")
        val baseHash = text("fromSha256")
        val patchHash = text("patchSha256")
        val targetHash = text("sha256")
        val code = number("versionCode")
        val targetSize = number("size")
        val patchSize = number("patchSize")
        if (listOf(baseHash, patchHash, targetHash).any { !Regex("[a-f0-9]{64}").matches(it) } ||
            code <= UpdateInstaller.version(UpdateInstaller.packageInfo(context)) ||
            targetSize !in 1..1073741824L || patchSize !in 1 until targetSize) {
            throw UpdateException("file_invalid")
        }
        val directory = File(context.filesDir, "updates").canonicalFile
        val patch = File(text("patchPath")).canonicalFile
        val output = File(text("outputPath")).canonicalFile
        if (patch.parentFile != directory || output.parentFile != directory ||
            patch.name != "$code-$patchHash.hpatch" ||
            output.name != "$code-$targetHash.apk.part" ||
            !patch.isFile || patch.length() != patchSize) {
            throw UpdateException("file_invalid")
        }
        if (StatFs(directory.path).availableBytes < targetSize * 2) throw UpdateException("space")
        val source = File(context.applicationInfo.sourceDir)
        if (UpdateInstaller.fileHash(source) != baseHash || UpdateInstaller.fileHash(patch) != patchHash) {
            throw UpdateException("checksum")
        }
        try {
            if (output.exists() && !output.delete()) throw UpdateException("storage")
            val result = HPatch.patch(source.path, patch.path, output.path, 8L * 1024 * 1024)
            if (result != 0 || output.length() != targetSize || UpdateInstaller.fileHash(output) != targetHash) {
                throw UpdateException("checksum")
            }
        } catch (error: Throwable) {
            output.delete()
            if (error is UpdateException) throw error
            throw UpdateException("patch")
        }
    }
}
