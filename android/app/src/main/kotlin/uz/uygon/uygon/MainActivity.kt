package uz.uygon.uygon

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.media.SoundPool
import android.app.AlarmManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private var tickId = 0

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val admin = ComponentName(this, UygonAdminReceiver::class.java)

        // Low-latency "ratchet" tick for the time wheel (SoundPool, UI sound
        // usage so it follows the media/touch volume, not the alarm volume).
        soundPool = SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            .build()
            .also { tickId = it.load(this, R.raw.tick, 1) }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uz.uygon/feedback")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "tick" -> {
                        val rate = (call.argument<Double>("rate") ?: 1.0).toFloat()
                        soundPool?.play(tickId, 1f, 1f, 1, 0, rate)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Battery-optimisation state without the restricted
        // REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission: we only open the
        // system settings list and read the state.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uz.uygon/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "batteryUnrestricted" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "canScheduleExact" -> {
                        val am = getSystemService(ALARM_SERVICE) as AlarmManager
                        result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                                am.canScheduleExactAlarms()
                        )
                    }
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            startActivity(
                                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                                    .setData(Uri.parse("package:$packageName"))
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                        }
                        result.success(null)
                    }
                    "openBatterySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uz.uygon/ringtones")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // [{title, uri}] of the phone's alarm + ringtone sounds.
                    "list" -> {
                        val manager = RingtoneManager(this).apply {
                            setType(RingtoneManager.TYPE_ALARM or RingtoneManager.TYPE_RINGTONE)
                        }
                        val out = mutableListOf<Map<String, String>>()
                        manager.cursor.use { c ->
                            while (c.moveToNext()) {
                                out.add(mapOf(
                                    "title" to c.getString(RingtoneManager.TITLE_COLUMN_INDEX),
                                    "uri" to manager.getRingtoneUri(c.position).toString(),
                                ))
                            }
                        }
                        result.success(out)
                    }
                    // The alarm service plays plain file paths, so copy the
                    // chosen sound into app_flutter/ringtones and return the
                    // path relative to it.
                    "copy" -> {
                        try {
                            val uri = Uri.parse(call.argument<String>("uri")!!)
                            val name = call.argument<String>("name")!!
                            val dir = File(filesDir.parent, "app_flutter/ringtones").apply { mkdirs() }
                            val target = File(dir, name)
                            contentResolver.openInputStream(uri)!!.use { input ->
                                target.outputStream().use { input.copyTo(it) }
                            }
                            result.success("ringtones/$name")
                        } catch (e: Exception) {
                            result.error("copy_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        val dpm = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uz.uygon/protection")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isActive" -> result.success(dpm.isAdminActive(admin))
                    "enable" -> {
                        startActivity(
                            Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                                .putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin)
                                .putExtra(
                                    DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                    "Ilovani o'chirib tashlashni qiyinlashtiradi."
                                )
                        )
                        result.success(null)
                    }
                    "disable" -> {
                        dpm.removeActiveAdmin(admin)
                        result.success(dpm.isAdminActive(admin))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
