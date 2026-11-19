package com.towork.towork

import android.app.Activity
import android.app.role.RoleManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.ShortcutManager
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The `towork/assist` channel. Both engines register one: the main activity
 * passes no [panel] and answers setup queries; the quick panel passes itself
 * and answers window requests. The main engine owns its process-long count.
 */
class AssistBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
    private val panel: Panel? = null,
    private val ownsEngine: Boolean = true,
) {
    /** Window operations only the quick panel's activity can perform. */
    interface Panel {
        fun launch(): Map<String, Any?>
        fun close()
        fun hide(notice: String?)
        fun openApp(sessionId: String?, location: String?, keepPanel: Boolean)
    }

    private val channel = MethodChannel(messenger, "towork/assist")

    init {
        if (ownsEngine) AssistHub.attached()
        channel.setMethodCallHandler(::handle)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "peers" -> result.success(AssistHub.others())
            // Only the main app consumes a handoff; the panel is its source.
            "takeHandoff" -> result.success(if (panel == null) AssistHub.take() else null)
            "launch" -> result.success(panel?.launch())
            "close" -> { panel?.close(); result.success(null) }
            "hide" -> { panel?.hide(call.argument("notice")); result.success(null) }
            "openApp" -> {
                panel?.openApp(
                    call.argument("sessionId"),
                    call.argument("location"),
                    call.argument<Boolean>("keepPanel") == true,
                )
                result.success(null)
            }
            "entryStatus" -> result.success(entryStatus())
            "openAssistantSettings" -> result.success(openAssistantSettings())
            "pinShortcut" -> result.success(pinShortcut(call.argument<Boolean>("voice") == true))
            "openPanel" -> result.success(openPanel())
            else -> result.notImplemented()
        }
    }

    /** The panel was invoked again while it was already running. */
    fun relaunch(payload: Map<String, Any?>) = channel.invokeMethod("relaunch", payload)

    private fun entryStatus(): Map<String, Any?> {
        // Null means the system does not say; the UI then shows no status.
        var assistant: Boolean? = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roles = activity.getSystemService(RoleManager::class.java)
            if (roles != null && roles.isRoleAvailable(RoleManager.ROLE_ASSISTANT)) {
                assistant = roles.isRoleHeld(RoleManager.ROLE_ASSISTANT)
            }
        }
        return mapOf("defaultAssistant" to assistant, "canPin" to (shortcuts() != null))
    }

    private fun shortcuts(): ShortcutManager? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        val manager = activity.getSystemService(ShortcutManager::class.java)
        return manager?.takeIf { it.isRequestPinShortcutSupported }
    }

    /** Vendors differ in which settings screen they implement; try the most specific first. */
    private fun openAssistantSettings(): Boolean {
        val actions = listOf(
            Settings.ACTION_VOICE_INPUT_SETTINGS,
            Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS,
            Settings.ACTION_SETTINGS,
        )
        for (action in actions) {
            try {
                activity.startActivity(Intent(action))
                return true
            } catch (_: ActivityNotFoundException) {
            } catch (_: SecurityException) {
            }
        }
        return false
    }

    private fun pinShortcut(voice: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = shortcuts() ?: return false
        return try {
            manager.requestPinShortcut(QuickAskShortcuts.info(activity, voice), null)
        } catch (_: IllegalStateException) {
            false
        }
    }

    private fun openPanel(): Boolean = try {
        activity.startActivity(AssistActivity.intent(activity, "app"))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        if (ownsEngine) AssistHub.detached()
    }
}
