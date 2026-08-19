package com.deskaitutor.mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.deskaitutor.mobile/trigger"
        private var channel: MethodChannel? = null

        // TriggerForegroundServiceからメディアボタン検知をFlutter側へ伝える。
        fun notifyTrigger() {
            channel?.invokeMethod("onMediaButtonTrigger", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel = methodChannel

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    val intent = Intent(this, TriggerForegroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopForegroundService" -> {
                    stopService(Intent(this, TriggerForegroundService::class.java))
                    result.success(null)
                }
                "isIgnoringBatteryOptimizations" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    val ignoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        pm.isIgnoringBatteryOptimizations(packageName)
                    } else {
                        true
                    }
                    result.success(ignoring)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName"),
                        )
                        startActivity(intent)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
