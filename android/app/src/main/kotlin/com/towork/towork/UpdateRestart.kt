package com.towork.towork

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

/** Completes only an app-owned update requested with the install button. */
class UpdateRestart : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) openAfterInstall(context)
    }

    companion object {
        private const val notificationId = 0x54575550
        private const val channelId = "towork_updates"

        fun openAfterInstall(context: Context) {
            val preferences = context.getSharedPreferences("towork_update", Context.MODE_PRIVATE)
            val target = preferences.getLong("targetVersion", -1)
            val installed = UpdateInstaller.packageInfo(context)
            if (!preferences.getBoolean("reopen", false) || target <= 0 ||
                UpdateInstaller.version(installed) != target) return
            // Both the replacement broadcast and session result can arrive.
            preferences.edit().putBoolean("reopen", false).putString("status", "success").commit()
            val launch = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            showNotification(context, launch, installed.versionName ?: "")
            try {
                context.startActivity(launch)
            } catch (_: RuntimeException) {
                // Some systems restrict background launches. The notification
                // opens the new version through a user-initiated PendingIntent.
            }
        }

        private fun showNotification(context: Context, launch: Intent, version: String) {
            if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) return
            val manager = context.getSystemService(NotificationManager::class.java)
            if (!manager.areNotificationsEnabled()) return
            val builder = if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(NotificationChannel(
                    channelId, context.getString(R.string.update_channel), NotificationManager.IMPORTANCE_DEFAULT,
                ))
                Notification.Builder(context, channelId)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
            val open = PendingIntent.getActivity(context, notificationId, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            manager.notify(notificationId, builder
                .setSmallIcon(R.drawable.ic_stat_towork)
                .setContentTitle(context.getString(R.string.update_installed, version))
                .setContentText(context.getString(R.string.update_open))
                .setContentIntent(open)
                .setAutoCancel(true)
                .build())
        }

        fun dismissNotification(context: Context) {
            context.getSystemService(NotificationManager::class.java).cancel(notificationId)
        }
    }
}
