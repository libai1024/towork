package com.towork.towork

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.Process
import androidx.lifecycle.Lifecycle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** All UI engines acknowledge readiness before the foreground process restart. */
class CodeUpdateBridge(private val activity: FlutterActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "towork/code_update")

    companion object {
        private val bridges = mutableSetOf<CodeUpdateBridge>()
        private var restarting = false
        private val handler = Handler(Looper.getMainLooper())
    }

    init {
        bridges.add(this)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "restart") restart(result) else result.notImplemented()
        }
    }

    private fun foreground() = !activity.isFinishing && !activity.isDestroyed &&
        activity.lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)

    private fun restart(result: MethodChannel.Result) {
        if (!foreground()) { result.error("background", "Return to the foreground", null); return }
        if (restarting) { result.error("busy", "Restart already requested", null); return }
        restarting = true
        val peers = bridges.toSet()
        var remaining = peers.size
        var complete = false
        fun finish(error: String?) {
            if (complete) return
            complete = true
            if (error != null) {
                restarting = false
                result.error(error, "Update restart deferred", null)
                return
            }
            try {
                check(foreground())
                activity.startActivity(Intent(activity, CodeUpdateRestartActivity::class.java)
                    .putExtra(CodeUpdateRestartActivity.PARENT_PID, Process.myPid()))
                result.success(null)
            } catch (_: Exception) {
                restarting = false
                result.error("restart", "Could not restart", null)
            }
        }
        handler.postDelayed({ finish("restart_busy") }, 5000)
        peers.forEach { peer ->
            peer.channel.invokeMethod("canRestart", null, object : MethodChannel.Result {
                override fun success(value: Any?) {
                    if (value != true || bridges != peers) { finish("restart_busy"); return }
                    remaining--
                    if (remaining == 0) finish(if (foreground()) null else "background")
                }
                override fun error(code: String, message: String?, details: Any?) = finish("restart_busy")
                override fun notImplemented() = finish("restart_busy")
            })
        }
    }

    fun dispose() {
        bridges.remove(this)
        channel.setMethodCallHandler(null)
    }
}
