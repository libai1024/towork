package com.towork.towork

import android.app.PendingIntent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/** Quick Settings tile that opens the quick panel. */
class QuickAskTileService : TileService() {
    override fun onStartListening() {
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        // The panel shows the user's own data, so never over the lock screen.
        if (isLocked) unlockAndRun(::open) else open()
    }

    private fun open() {
        val intent = AssistActivity.intent(this, "tile")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
        } else {
            @Suppress("DEPRECATION", "StartActivityAndCollapseDeprecated")
            startActivityAndCollapse(intent)
        }
    }
}
