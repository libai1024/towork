package com.towork.towork

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Streams a Flutter asset to a file with a fixed 1 MiB buffer.
 *
 * The bundled speech model is ~228 MB; `rootBundle.load` would copy all of it
 * into the Dart heap at once. AssetManager streams work for compressed and
 * stored APK entries alike, and the copy runs off the main thread.
 */
class AssetBridge(context: Context, messenger: BinaryMessenger) {
    private val assets = context.applicationContext.assets
    private val channel = MethodChannel(messenger, "towork/assets")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init { channel.setMethodCallHandler(::handle) }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "copyAsset") return result.notImplemented()
        val asset = call.argument<String>("asset")
        val target = call.argument<String>("target")
        if (asset == null || target == null) {
            return result.error("bad_args", "asset and target are required", null)
        }
        io.execute {
            try {
                val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
                val file = File(target)
                file.parentFile?.mkdirs()
                assets.open(key).use { input ->
                    file.outputStream().use { output ->
                        input.copyTo(output, 1 shl 20)
                        output.fd.sync()
                    }
                }
                main.post { result.success(null) }
            } catch (error: Exception) {
                main.post { result.error("copy_failed", error.message, null) }
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }
}
