package com.towork.towork

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine

/** The patch runtime selects the primary entry once per process. Reusing this
 * engine preserves that entry across Activity recreation and launcher reentry.
 * Activity-bound channels are detached and replaced by each MainActivity.
 */
object MainFlutterEngine {
    private var engine: FlutterEngine? = null

    fun get(context: Context): FlutterEngine = engine ?: FlutterEngine(context.applicationContext).also {
        engine = it
        AssistHub.attached()
    }
}
