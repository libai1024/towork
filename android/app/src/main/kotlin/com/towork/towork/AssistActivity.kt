package com.towork.towork

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine

/**
 * The quick panel: a translucent window over whatever the user was doing,
 * with its own Flutter engine running the `assistMain` entrypoint.
 *
 * It is a separate engine because an engine drives one activity at a time;
 * sharing the main one would leave MainActivity detached and blank.
 */
class AssistActivity : FlutterActivity(), AssistBridge.Panel {
    companion object {
        const val ACTION_QUICK_ASK = "com.towork.towork.action.QUICK_ASK"
        const val ACTION_QUICK_ASK_VOICE = "com.towork.towork.action.QUICK_ASK_VOICE"
        const val EXTRA_SOURCE = "com.towork.towork.extra.SOURCE"

        /** Matches AssistLaunch.maxText on the Dart side. */
        private const val MAX_TEXT = 4000

        fun intent(context: Context, source: String): Intent =
            Intent(context, AssistActivity::class.java)
                .setAction(ACTION_QUICK_ASK)
                .putExtra(EXTRA_SOURCE, source)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)
    }

    private var speech: SpeechBridge? = null
    private var assetBridge: AssetBridge? = null
    private var assist: AssistBridge? = null
    private var codeUpdates: CodeUpdateBridge? = null

    override fun getDartEntrypointFunctionName(): String = "assistMain"
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        speech = SpeechBridge(this, messenger)
        assetBridge = AssetBridge(this, messenger)
        assist = AssistBridge(this, messenger, this)
        codeUpdates = CodeUpdateBridge(this, messenger)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        noTransition(opening = true)
        QuickAskShortcuts.refreshPinned(this)
        window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
        // Same edge-to-edge window as MainActivity: Flutter lays out against
        // the insets, and the panel must reach under the system bars.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                } else {
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
            }
        }
        @Suppress("DEPRECATION")
        window.statusBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION")
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            @Suppress("DEPRECATION")
            window.navigationBarDividerColor = Color.TRANSPARENT
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            @Suppress("DEPRECATION")
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        noTransition(opening = true)
        setIntent(intent)
        assist?.relaunch(payload(intent))
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (speech?.permissionResult(requestCode) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onPause() { speech?.interrupt(); super.onPause() }

    override fun onDestroy() {
        speech?.dispose()
        assetBridge?.dispose()
        assist?.dispose()
        codeUpdates?.dispose()
        super.onDestroy()
    }

    override fun launch(): Map<String, Any?> = payload(intent)

    override fun close() {
        finishAndRemoveTask()
        noTransition(opening = false)
    }

    /** Leaves the engine running so a reply in flight can finish. */
    override fun hide(notice: String?) {
        if (!notice.isNullOrBlank()) {
            Toast.makeText(applicationContext, notice, Toast.LENGTH_SHORT).show()
        }
        moveTaskToBack(true)
        noTransition(opening = false)
    }

    override fun openApp(sessionId: String?, location: String?, keepPanel: Boolean) {
        AssistHub.offer(sessionId, location)
        // The launcher intent brings the existing main task forward as it is,
        // or starts it; MainActivity picks the handoff up when it resumes.
        val main = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(main)
        if (!keepPanel) close()
    }

    /** The panel animates itself; a window animation on top would double it. */
    private fun noTransition(opening: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            overrideActivityTransition(
                if (opening) OVERRIDE_TRANSITION_OPEN else OVERRIDE_TRANSITION_CLOSE,
                0,
                0,
            )
        } else {
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        }
    }

    /**
     * What the Dart side needs to know about how the panel was invoked. Text
     * from other apps is only ever prefilled, never sent on the user's behalf.
     */
    private fun payload(intent: Intent?): Map<String, Any?> {
        var source = "app"
        var text: String? = null
        var voice = false
        try {
            when (intent?.action) {
                Intent.ACTION_ASSIST -> source = "assistant"
                Intent.ACTION_VOICE_COMMAND -> { source = "voice"; voice = true }
                Intent.ACTION_SEND -> {
                    source = "share"
                    text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
                }
                Intent.ACTION_PROCESS_TEXT -> {
                    source = "selection"
                    text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                }
                ACTION_QUICK_ASK -> source = intent.getStringExtra(EXTRA_SOURCE) ?: "app"
                ACTION_QUICK_ASK_VOICE -> {
                    source = intent.getStringExtra(EXTRA_SOURCE) ?: "shortcut"
                    voice = true
                }
            }
        } catch (_: RuntimeException) {
            // Extras from another app that cannot be unparcelled: open empty.
        }
        return mapOf("source" to source, "text" to text?.take(MAX_TEXT), "voice" to voice)
    }
}
