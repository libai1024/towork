package com.towork.towork

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** App-owned update channel. Installed package metadata is never supplied by Dart. */
class UpdateBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "towork/update")
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "info" -> respondAsync(result) {
                        val info = UpdateInstaller.packageInfo(activity)
                        mapOf(
                            "versionName" to info.versionName,
                            "versionCode" to UpdateInstaller.version(info),
                            "supported" to true,
                            "certSha256" to UpdateInstaller.signers(info).singleOrNull(),
                            "abis" to Build.SUPPORTED_ABIS.toList(),
                            "availableBytes" to StatFs(activity.filesDir.path).availableBytes,
                            "apkSha256" to UpdatePatcher.installedHash(activity),
                        )
                    }
                    "patch" -> respondAsync(result) {
                        UpdatePatcher.apply(activity.applicationContext, call.arguments as? Map<*, *>
                            ?: throw UpdateException("file_invalid"))
                        null
                    }
                    "canInstall" -> result.success(canInstall())
                    "permission" -> {
                        if (Build.VERSION.SDK_INT >= 26 && !canInstall()) {
                            activity.startActivity(Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:${activity.packageName}"),
                            ))
                        }
                        result.success(null)
                    }
                    "install" -> {
                        if (!canInstall()) throw UpdateException("permission")
                        val path = call.argument<String>("path") ?: throw UpdateException("file_invalid")
                        val code = call.argument<Number>("versionCode")?.toLong() ?: throw UpdateException("version")
                        val name = call.argument<String>("versionName") ?: throw UpdateException("version")
                        val hash = call.argument<String>("sha256") ?: throw UpdateException("file_invalid")
                        val size = call.argument<Number>("size")?.toLong() ?: throw UpdateException("file_invalid")
                        UpdateInstaller.install(activity.applicationContext, path, code, name, hash, size) { error ->
                            main.post {
                                if (error == null) result.success(null)
                                else result.error(error, "Update could not be installed", null)
                            }
                        }
                    }
                    "status" -> result.success(UpdateInstaller.status(activity))
                    "confirm" -> {
                        val confirmation = UpdateInstaller.confirmation
                            ?: throw UpdateException("install_failed")
                        // This method is called only from the visible foreground update page.
                        activity.startActivity(confirmation)
                        UpdateInstaller.confirmation = null
                        UpdateInstaller.setStatus(activity, "waiting")
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error((error as? UpdateException)?.code ?: "platform", "Update operation failed", null)
            }
        }
    }

    private fun canInstall(): Boolean = Build.VERSION.SDK_INT < 26 ||
        activity.packageManager.canRequestPackageInstalls()

    private fun respondAsync(result: MethodChannel.Result, operation: () -> Any?) {
        UpdatePatcher.executor.execute {
            try {
                val value = operation()
                main.post { result.success(value) }
            } catch (error: Exception) {
                main.post { result.error((error as? UpdateException)?.code ?: "platform", "Update operation failed", null) }
            }
        }
    }

    fun dispose() { channel.setMethodCallHandler(null) }
}
