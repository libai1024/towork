package com.towork.towork

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Each listener closes over a capture ID; old recognizers are never reused. */
class SpeechBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "towork/speech")
    private val handler = Handler(Looper.getMainLooper())
    private var recognizer: SpeechRecognizer? = null
    private var active: String? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var limit: Runnable? = null
    companion object { const val permissionRequest = 7214 }

    init { channel.setMethodCallHandler(::handle) }
    private fun authorized() = activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    private fun onDeviceAvailable() = Build.VERSION.SDK_INT >= 31 && SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)
    private fun available() = SpeechRecognizer.isRecognitionAvailable(activity) || onDeviceAvailable()
    private fun capabilities(): Map<String, Any> = mapOf(
        "available" to available(),
        "authorized" to authorized(),
        // Android does not guarantee an installed-language inventory from the
        // selected recognizer. Locale support is checked by actual recognition.
        "locales" to emptyList<String>(),
        "onDeviceSupported" to onDeviceAvailable()
    )
    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "inspect" -> result.success(capabilities())
                "prepare" -> {
                    if (pendingPermission != null) result.error("busy", null, null)
                    else if (authorized() || !available()) result.success(capabilities())
                    else {
                        pendingPermission = result
                        activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), permissionRequest)
                    }
                }
                "start" -> start(call, result)
                "stop" -> {
                    if (call.argument<String>("id") == active) {
                        // Keep the native deadline until the final result arrives.
                        recognizer?.stopListening()
                        active?.let { emit(it, "ended") }
                    }
                    result.success(null)
                }
                "cancel" -> { if (call.argument<String>("id") == active) release(); result.success(null) }
                "openSettings" -> {
                    activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}")))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (_: Exception) {
            release()
            result.error("unavailable", null, null)
        }
    }
    fun permissionResult(requestCode: Int): Boolean {
        if (requestCode != permissionRequest) return false
        val result = pendingPermission
        pendingPermission = null
        result?.success(capabilities())
        return true
    }
    private fun emit(id: String, kind: String, text: String? = null, error: String? = null) {
        if (active != id) return
        channel.invokeMethod("event", mapOf("id" to id, "kind" to kind, "text" to text, "error" to error))
    }
    private fun start(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        val locale = call.argument<String>("locale")
        val onDevice = call.argument<Boolean>("onDevice") == true
        if (id.isNullOrBlank() || locale.isNullOrBlank()) { result.error("startFailed", null, null); return }
        if (!authorized()) { result.error("permissionDenied", null, null); return }
        if (active != null) { result.error("busy", null, null); return }
        if (onDevice && (Build.VERSION.SDK_INT < 31 || !SpeechRecognizer.isOnDeviceRecognitionAvailable(activity))) {
            result.error("onDeviceUnavailable", null, null); return
        }
        val engine = if (onDevice && Build.VERSION.SDK_INT >= 31)
            SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
        else SpeechRecognizer.createSpeechRecognizer(activity)
        active = id
        recognizer = engine
        engine.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) { emit(id, "listening") }
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() { emit(id, "ended") }
            override fun onPartialResults(results: Bundle?) { recognized(results, false) }
            override fun onResults(results: Bundle?) { recognized(results, true) }
            private fun recognized(results: Bundle?, final: Boolean) {
                if (active != id) return
                val words = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull() ?: ""
                emit(id, if (final) "finalResult" else "partial", text = words)
                if (final) release()
            }
            override fun onError(error: Int) {
                if (active != id) return
                val code = when (error) {
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permissionDenied"
                    SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "network"
                    SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "noResult"
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "busy"
                    SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED, SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "localeUnavailable"
                    else -> "interrupted"
                }
                emit(id, "error", error = code)
                release()
            }
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        engine.startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        })
        // Independent native deadline also covers a stalled Flutter isolate.
        limit = Runnable {
            if (active == id) {
                emit(id, "error", error = "interrupted")
                release()
            }
        }.also { handler.postDelayed(it, 65000) }
        result.success(null)
    }
    fun interrupt() {
        active?.let { emit(it, "error", error = "interrupted") }
        release()
    }
    private fun release() {
        active = null // Invalidate before cancel/destroy can deliver callbacks.
        limit?.let { handler.removeCallbacks(it) }
        limit = null
        val old = recognizer
        recognizer = null
        old?.cancel()
        old?.destroy()
    }
    fun dispose() {
        interrupt()
        pendingPermission?.error("interrupted", null, null)
        pendingPermission = null
        channel.setMethodCallHandler(null)
    }
}
