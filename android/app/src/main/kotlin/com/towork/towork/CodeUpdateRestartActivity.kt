package com.towork.towork

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.os.Process

/** Runs without a Flutter engine, keeping patch boot accounting in the app. */
class CodeUpdateRestartActivity : Activity() {
    companion object { const val PARENT_PID = "parent_pid" }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val parent = intent.getIntExtra(PARENT_PID, -1)
        if (parent <= 0 || parent == Process.myPid()) { finish(); return }
        Process.killProcess(parent)
        startActivity(Intent.makeRestartActivityTask(ComponentName(this, MainActivity::class.java)))
        finish()
        Process.killProcess(Process.myPid())
    }
}
