package com.towork.towork

import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Icon
import android.os.Build

/** Stable definitions shared by in-app pinning and external shortcut pickers. */
object QuickAskShortcuts {
    /** Update existing pins after an upgrade, keeping the IDs selected by system menus. */
    fun refreshPinned(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        val manager = context.getSystemService(ShortcutManager::class.java) ?: return
        try {
            val stale = manager.pinnedShortcuts.filter {
                (it.id == "quick_ask_pinned" || it.id == "quick_ask_voice_pinned") &&
                    ((it.intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_NO_ANIMATION) == 0
            }
            if (stale.isNotEmpty()) {
                manager.updateShortcuts(stale.map { info(context, it.id == "quick_ask_voice_pinned") })
            }
        } catch (_: IllegalStateException) {
            // A locked user cannot update shortcuts; retry when an entry is opened again.
        }
    }

    fun launchIntent(context: Context, voice: Boolean): Intent =
        AssistActivity.intent(context, "shortcut").setAction(
            if (voice) AssistActivity.ACTION_QUICK_ASK_VOICE else AssistActivity.ACTION_QUICK_ASK,
        )

    private fun iconResource(voice: Boolean): Int =
        if (voice) R.drawable.ic_shortcut_quick_voice else R.drawable.ic_shortcut_quick_ask

    private fun labelResource(voice: Boolean): Int =
        if (voice) R.string.quick_ask_voice_short else R.string.quick_ask_short

    fun info(context: Context, voice: Boolean): ShortcutInfo =
        ShortcutInfo.Builder(context, if (voice) "quick_ask_voice_pinned" else "quick_ask_pinned")
            .setShortLabel(context.getString(labelResource(voice)))
            .setLongLabel(context.getString(if (voice) R.string.quick_ask_voice_long else R.string.quick_ask_long))
            .setIcon(Icon.createWithResource(context, iconResource(voice)))
            .setIntent(launchIntent(context, voice))
            .build()

    @Suppress("DEPRECATION")
    fun resultIntent(context: Context, voice: Boolean): Intent {
        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                context.getSystemService(ShortcutManager::class.java)
                    ?.createShortcutResultIntent(info(context, voice))
            } catch (_: IllegalStateException) {
                null
            }
        } else null
        // Legacy shortcut pickers consume these extras even on newer Android.
        // Rasterize the vector so launchers using BitmapFactory also get an icon.
        val size = (48 * context.resources.displayMetrics.density).toInt().coerceAtLeast(1)
        val icon = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        context.getDrawable(iconResource(voice))?.apply {
            setBounds(0, 0, size, size)
            draw(Canvas(icon))
        }
        return (result ?: Intent())
            .putExtra(Intent.EXTRA_SHORTCUT_INTENT, launchIntent(context, voice))
            .putExtra(Intent.EXTRA_SHORTCUT_NAME, context.getString(labelResource(voice)))
            .putExtra(Intent.EXTRA_SHORTCUT_ICON, icon)
    }
}
