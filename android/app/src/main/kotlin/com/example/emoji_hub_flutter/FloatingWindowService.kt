package com.example.emoji_hub_flutter

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageButton
import android.os.Build
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import androidx.cardview.widget.CardView
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import android.util.Log

class FloatingWindowService : Service() {
    private val TAG = "FloatingWindowService"
    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var flutterContainer: FrameLayout? = null
    private var isExpanded = true
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    
    private val NOTIFICATION_CHANNEL_ID = "FloatingWindowService"
    private val NOTIFICATION_ID = 1

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service onCreate")
        createNotificationChannel()
        startForeground()
        initFlutterEngine()
    }

    private fun initFlutterEngine() {
        Log.i(TAG, "Initializing Flutter engine")
        try {
            flutterEngine = FlutterEngineManager.getInstance(this).getFlutterEngine()
            if (flutterEngine == null) {
                Log.e(TAG, "Failed to get Flutter engine from manager")
                return
            }
            Log.i(TAG, "Flutter engine obtained from manager")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Flutter engine", e)
            e.printStackTrace()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "Service onStartCommand")
        if (floatingView == null) {
            initializeFloatingWindow()
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.i(TAG, "Creating notification channel")
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Floating Window Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the floating window service running"
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startForeground() {
        Log.i(TAG, "Starting foreground service")
        try {
            val notificationIntent = Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                this, 0, notificationIntent,
                PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle("EmojiHub")
                .setContentText("悬浮窗服务运行中")
                .setSmallIcon(R.drawable.launch_background)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setOngoing(true)
                .build()

            startForeground(NOTIFICATION_ID, notification, 0)
            Log.i(TAG, "Foreground service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service", e)
            e.printStackTrace()
        }
    }

    private fun initializeFloatingWindow() {
        Log.i(TAG, "Initializing floating window")
        try {
            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            Log.i(TAG, "Window manager obtained")
            
            // 加载布局
            try {
                floatingView = LayoutInflater.from(this).inflate(R.layout.floating_window_layout, null)
                Log.i(TAG, "Layout inflated")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to inflate layout", e)
                e.printStackTrace()
                return
            }
            
            if (floatingView == null) {
                Log.e(TAG, "Failed to inflate floating window layout")
                return
            }

            // 查找根视图
            val rootView = floatingView?.findViewById<CardView>(R.id.root)
            if (rootView == null) {
                Log.e(TAG, "Failed to find root view")
                return
            }
            Log.i(TAG, "Root view found")

            flutterContainer = floatingView?.findViewById(R.id.flutterContainer)
            if (flutterContainer == null) {
                Log.e(TAG, "Failed to find flutter container")
                return
            }
            Log.i(TAG, "Flutter container found")

            // 初始化FlutterView
            initFlutterView()

            // 设置悬浮窗参数
            params = WindowManager.LayoutParams().apply {
                width = WindowManager.LayoutParams.WRAP_CONTENT
                height = WindowManager.LayoutParams.WRAP_CONTENT
                type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    WindowManager.LayoutParams.TYPE_PHONE
                }
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                format = PixelFormat.TRANSLUCENT
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = 100
            }
            Log.i(TAG, "Window parameters set")

            // 设置按钮点击事件
            setupButtons()
            Log.i(TAG, "Buttons set up")
            
            // 添加触摸事件处理
            setupTouchListener()
            Log.i(TAG, "Touch listener set up")

            // 添加悬浮窗到窗口管理器
            try {
                windowManager?.addView(floatingView, params)
                Log.i(TAG, "Floating window added to window manager successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add view to window manager", e)
                e.printStackTrace()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize floating window", e)
            e.printStackTrace()
        }
    }

    private fun initFlutterView() {
        Log.d(TAG, "Initializing Flutter view")
        try {
            flutterEngine?.let { engine ->
                flutterView = FlutterView(this).apply {
                    attachToFlutterEngine(engine)
                    flutterContainer?.addView(this)
                    Log.d(TAG, "Flutter view attached to engine and added to container")
                }
            } ?: run {
                Log.e(TAG, "Cannot initialize Flutter view: engine is null")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Flutter view", e)
            e.printStackTrace()
        }
    }

    private fun setupButtons() {
        // 关闭按钮
        floatingView?.findViewById<ImageButton>(R.id.btnClose)?.setOnClickListener {
            Log.d(TAG, "Close button clicked")
            stopSelf()
        }

        // 展开按钮
        floatingView?.findViewById<ImageButton>(R.id.btnExpand)?.setOnClickListener {
            Log.d(TAG, "Expand button clicked")
            toggleWindowSize(true)
        }

        // 收起按钮
        floatingView?.findViewById<ImageButton>(R.id.btnCollapse)?.setOnClickListener {
            Log.d(TAG, "Collapse button clicked")
            toggleWindowSize(false)
        }
    }

    private fun toggleWindowSize(expand: Boolean) {
        Log.d(TAG, "Toggling window size: $expand")
        isExpanded = expand
        flutterContainer?.visibility = if (expand) View.VISIBLE else View.GONE
        windowManager?.updateViewLayout(floatingView, params)
    }

    private fun setupTouchListener() {
        var initialX: Int = 0
        var initialY: Int = 0
        var initialTouchX: Float = 0f
        var initialTouchY: Float = 0f
        var isMoved = false

        floatingView?.findViewById<CardView>(R.id.root)?.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params?.x ?: 0
                    initialY = params?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isMoved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - initialTouchX).toInt()
                    val deltaY = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
                        isMoved = true
                        params?.apply {
                            x = initialX + deltaX
                            y = initialY + deltaY
                        }
                        windowManager?.updateViewLayout(floatingView, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isMoved) {
                        view.performClick()
                    }
                    true
                }
                else -> false
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "Service onDestroy")
        super.onDestroy()
        flutterView?.let { view ->
            flutterEngine?.let { engine ->
                view.detachFromFlutterEngine()
                Log.d(TAG, "Flutter view detached from engine")
            }
        }
        floatingView?.let { 
            windowManager?.removeView(it)
            Log.d(TAG, "Floating window removed from window manager")
        }
    }
} 