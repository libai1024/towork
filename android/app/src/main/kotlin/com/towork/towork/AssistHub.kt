package com.towork.towork

import java.util.concurrent.atomic.AtomicInteger

/**
 * Process-wide state shared by the main app and the quick panel.
 *
 * Each runs in its own Flutter engine with its own database connection, so
 * neither can see the other through Dart. This is the one place both reach.
 */
object AssistHub {
    private val engines = AtomicInteger(0)
    private var handoff: Map<String, String?>? = null

    fun attached() { engines.incrementAndGet() }
    fun detached() { engines.updateAndGet { if (it > 0) it - 1 else 0 } }

    /** Live engines other than the caller's own. */
    fun others(): Int = (engines.get() - 1).coerceAtLeast(0)

    /** Where the main app should go once it is in front. Latest offer wins. */
    @Synchronized
    fun offer(sessionId: String?, location: String?) {
        handoff = mapOf("sessionId" to sessionId, "location" to location)
    }

    @Synchronized
    fun take(): Map<String, String?>? = handoff.also { handoff = null }
}
