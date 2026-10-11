package uz.uygon.uygon

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val admin = ComponentName(this, UygonAdminReceiver::class.java)
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
