package com.example.emoji_hub_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine

class OverlayService : Service() {
    companion object {
        private const val TAG = "OverlayService"
        private const val CHANNEL_ID = "emoji_hub_overlay"
        private const val NOTIFICATION_ID = 1
    }

    private var windowManager: WindowManager? = null
    private var flutterEngine: FlutterEngine? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "服务创建")
        startForeground()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "服务启动")
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "服务销毁")
        super.onDestroy()
    }

    private fun startForeground() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "EmojiHub 悬浮窗",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "EmojiHub 悬浮窗服务"
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)

            val notification = Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("EmojiHub")
                .setContentText("悬浮窗服务运行中")
                .setSmallIcon(android.R.drawable.ic_menu_gallery)
                .build()

            startForeground(NOTIFICATION_ID, notification)
        }
    }
} 