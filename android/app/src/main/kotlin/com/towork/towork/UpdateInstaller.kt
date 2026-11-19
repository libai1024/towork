package com.towork.towork

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.os.Build
import android.os.StatFs
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class UpdateException(val code: String) : Exception(code)

/** PackageInstaller owns the installation copy. The downloaded APK stays private. */
object UpdateInstaller {
    private val executor = Executors.newSingleThreadExecutor()
    private val writing = AtomicBoolean(false)
    var confirmation: Intent? = null

    private fun preferences(context: Context) =
        context.getSharedPreferences("towork_update", Context.MODE_PRIVATE)

    fun status(context: Context): String {
        val prefs = preferences(context)
        val stored = prefs.getString("status", "failed")!!
        if (stored != "waiting" && stored != "confirmation") return stored
        if (context.packageManager.packageInstaller.getSessionInfo(sessionId(context)) != null) return stored
        val target = prefs.getLong("targetVersion", -1)
        val recovered = if (target > 0 && version(packageInfo(context)) >= target) "success" else "cancelled"
        setStatus(context, recovered)
        return recovered
    }
    fun setStatus(context: Context, value: String) {
        val edit = preferences(context).edit().putString("status", value)
        if (value == "cancelled" || value == "failed") edit.putBoolean("reopen", false)
        edit.apply()
    }
    fun sessionId(context: Context): Int = preferences(context).getInt("session", -1)

    @Suppress("DEPRECATION")
    private fun flags(): Int = if (Build.VERSION.SDK_INT >= 28)
        PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES

    @Suppress("DEPRECATION")
    fun packageInfo(context: Context): PackageInfo =
        context.packageManager.getPackageInfo(context.packageName, flags())

    @Suppress("DEPRECATION")
    fun version(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    @Suppress("DEPRECATION")
    fun signers(info: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= 28)
            info.signingInfo?.apkContentsSigners else info.signatures
        return signatures?.map { digest(it.toByteArray()) }?.toSet() ?: emptySet()
    }

    private fun digest(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }

    fun install(
        context: Context, path: String, code: Long, name: String, hash: String, size: Long,
        complete: (String?) -> Unit,
    ) {
        if (!writing.compareAndSet(false, true)) {
            complete("busy")
            return
        }
        executor.execute {
            var newSession = -1
            val installer = context.packageManager.packageInstaller
            try {
                val file = validate(context, path, code, name, hash, size)
                val oldSession = sessionId(context)
                abandonOwnedSession(installer, oldSession)
                confirmation = null
                val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL).apply {
                    setAppPackageName(context.packageName)
                    setSize(file.length())
                    if (Build.VERSION.SDK_INT >= 31) setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_REQUIRED)
                }
                newSession = installer.createSession(params)
                preferences(context).edit().putInt("session", newSession)
                    .putLong("targetVersion", code).putBoolean("reopen", true)
                    .putString("status", "waiting").commit()
                installer.openSession(newSession).use { session ->
                    session.openWrite("base.apk", 0, file.length()).use { output ->
                        file.inputStream().use { it.copyTo(output) }
                        session.fsync(output)
                    }
                    val callback = Intent(context, UpdateInstallReceiver::class.java)
                        .setAction("${context.packageName}.UPDATE_RESULT.$newSession")
                    val mutable = if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0
                    val pending = PendingIntent.getBroadcast(
                        context, newSession, callback, PendingIntent.FLAG_UPDATE_CURRENT or mutable,
                    )
                    session.commit(pending.intentSender)
                }
                complete(null)
            } catch (error: Exception) {
                abandonOwnedSession(installer, newSession)
                setStatus(context, "failed")
                complete((error as? UpdateException)?.code ?: "install_failed")
            } finally {
                writing.set(false)
            }
        }
    }

    private fun abandonOwnedSession(installer: PackageInstaller, id: Int) {
        if (id < 0 || installer.mySessions.none { it.sessionId == id }) return
        try {
            installer.abandonSession(id)
        } catch (_: SecurityException) {
            // A user cancellation can destroy the session after mySessions was read.
        } catch (_: IllegalArgumentException) {
            // Completed sessions no longer exist in PackageInstaller.
        }
    }

    @Suppress("DEPRECATION")
    private fun validate(context: Context, path: String, code: Long, name: String, hash: String, size: Long): File {
        if (!Regex("[a-f0-9]{64}").matches(hash)) throw UpdateException("file_invalid")
        val file = File(path).canonicalFile
        val directory = File(context.filesDir, "updates").canonicalFile
        if (file.parentFile != directory || file.name != "$code-$hash.apk" || !file.isFile || file.length() != size) {
            throw UpdateException("file_invalid")
        }
        if (fileHash(file) != hash) throw UpdateException("checksum")
        // Android 9/10 collect archive certificates only with GET_SIGNATURES.
        val candidate = context.packageManager.getPackageArchiveInfo(file.path, flags() or PackageManager.GET_SIGNATURES)
            ?: throw UpdateException("file_invalid")
        val installed = packageInfo(context)
        if (candidate.packageName != context.packageName) throw UpdateException("wrong_package")
        if (version(candidate) != code || candidate.versionName != name || code <= version(installed)) {
            throw UpdateException("version")
        }
        val expectedSigners = signers(installed)
        if (expectedSigners.isEmpty() || signers(candidate) != expectedSigners) throw UpdateException("signature")
        if (StatFs(context.filesDir.path).availableBytes < size) throw UpdateException("space")
        return file
    }

    fun fileHash(file: File): String {
        val hasher = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(128 * 1024)
            var length = input.read(buffer)
            while (length >= 0) {
                hasher.update(buffer, 0, length)
                length = input.read(buffer)
            }
        }
        return hasher.digest().joinToString("") { "%02x".format(it) }
    }
}

/** Explicit, non-exported callback. Old sessions cannot overwrite the active result. */
class UpdateInstallReceiver : BroadcastReceiver() {
    @Suppress("DEPRECATION")
    override fun onReceive(context: Context, intent: Intent) {
        val session = intent.getIntExtra(PackageInstaller.EXTRA_SESSION_ID, -1)
        if (session < 0 || session != UpdateInstaller.sessionId(context)) return
        when (intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                UpdateInstaller.confirmation = if (Build.VERSION.SDK_INT >= 33)
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                else intent.getParcelableExtra(Intent.EXTRA_INTENT)
                UpdateInstaller.setStatus(context, if (UpdateInstaller.confirmation != null) "confirmation" else "failed")
            }
            PackageInstaller.STATUS_SUCCESS -> {
                UpdateInstaller.setStatus(context, "success")
                UpdateRestart.openAfterInstall(context)
            }
            PackageInstaller.STATUS_FAILURE_ABORTED -> UpdateInstaller.setStatus(context, "cancelled")
            else -> UpdateInstaller.setStatus(context, "failed")
        }
    }
}
