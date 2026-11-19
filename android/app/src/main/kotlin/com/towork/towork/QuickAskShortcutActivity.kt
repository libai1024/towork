package com.towork.towork

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/** Returns a fixed action to the system/launcher that requested a shortcut. */
open class QuickAskShortcutActivity : Activity() {
    protected open val voice = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent.action == Intent.ACTION_CREATE_SHORTCUT) {
            setResult(RESULT_OK, QuickAskShortcuts.resultIntent(this, voice))
        }
        finish()
    }
}

class QuickVoiceShortcutActivity : QuickAskShortcutActivity() {
    override val voice = true
}
