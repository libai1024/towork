package com.towork.towork

import android.graphics.Color
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine = MainFlutterEngine.get(context)
    override fun shouldDestroyEngineWithHost(): Boolean = false
    private var speech: SpeechBridge? = null
    private var assetBridge: AssetBridge? = null
    private var assist: AssistBridge? = null
    private var updates: UpdateBridge? = null
    private var codeUpdates: CodeUpdateBridge? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        speech = SpeechBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        assetBridge = AssetBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        assist = AssistBridge(this, flutterEngine.dartExecutor.binaryMessenger, ownsEngine = false)
        updates = UpdateBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        codeUpdates = CodeUpdateBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (speech?.permissionResult(requestCode) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
    override fun onPause() { speech?.interrupt(); super.onPause() }
    override fun onResume() {
        super.onResume()
        UpdateRestart.dismissNotification(this)
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Eviction detaches the old host before the replacement binds channels.
        // Its later onDestroy must not clear the replacement's handlers.
        speech?.dispose()
        speech = null
        assetBridge?.dispose()
        assetBridge = null
        assist?.dispose()
        assist = null
        updates?.dispose()
        updates = null
        codeUpdates?.dispose()
        codeUpdates = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        QuickAskShortcuts.refreshPinned(this)
        // Flutter lays out controls with safe insets; the window background must
        // still extend behind punch holes on Android versions before API 35.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                } else {
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
            }
        }
        // Keep the native startup frame consistent until Flutter applies its
        // shared system-bar style (also used after theme and route changes).
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
}
