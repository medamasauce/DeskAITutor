package com.deskaitutor.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.support.v4.media.session.MediaSessionCompat
import android.view.KeyEvent
import androidx.core.app.NotificationCompat

/**
 * 画面OFF・バックグラウンドでもBluetoothリモコンのメディアボタンを
 * 受信し続けるためのフォアグラウンドサービス。
 *
 * MediaSessionCompatをアクティブにしてメディアボタンイベントを受信し、
 * PARTIAL_WAKE_LOCKでCPUのみを起こす（画面は点灯しない）。
 * トリガー検知はMainActivity側のMethodChannel経由でFlutterへ伝える。
 */
class TriggerForegroundService : Service() {

    private var mediaSession: MediaSessionCompat? = null
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val CHANNEL_ID = "desk_ai_tutor_trigger"
        const val NOTIFICATION_ID = 1001

        // シャッターリモコンとして動作する製品が送ってくる代表的なキーコード
        private val TRIGGER_KEYCODES = setOf(
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            KeyEvent.KEYCODE_HEADSETHOOK,
            KeyEvent.KEYCODE_CAMERA,
            KeyEvent.KEYCODE_VOLUME_UP,
        )
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundWithNotification()
        acquireWakeLock()
        setupMediaSession()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundWithNotification() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Desk AI Tutor 待機中",
                NotificationManager.IMPORTANCE_LOW,
            )
            manager.createNotificationChannel(channel)
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Desk AI Tutor")
            .setContentText("リモコン/タップでの撮影トリガーを待機中")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "DeskAiTutor::TriggerWakeLock",
        ).apply { acquire(10 * 60 * 60 * 1000L /* 10時間の安全上限 */) }
    }

    private fun setupMediaSession() {
        val session = MediaSessionCompat(this, "DeskAiTutorTriggerSession")
        session.setCallback(object : MediaSessionCompat.Callback() {
            override fun onMediaButtonEvent(mediaButtonIntent: Intent): Boolean {
                val event = mediaButtonIntent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
                if (event != null &&
                    event.action == KeyEvent.ACTION_DOWN &&
                    event.keyCode in TRIGGER_KEYCODES
                ) {
                    MainActivity.notifyTrigger()
                    return true
                }
                return super.onMediaButtonEvent(mediaButtonIntent)
            }
        })
        session.isActive = true
        mediaSession = session
    }

    override fun onDestroy() {
        mediaSession?.isActive = false
        mediaSession?.release()
        if (wakeLock?.isHeld == true) wakeLock?.release()
        super.onDestroy()
    }
}
