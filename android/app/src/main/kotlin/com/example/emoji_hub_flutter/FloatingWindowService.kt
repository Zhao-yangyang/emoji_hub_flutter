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
import android.util.DisplayMetrics
import android.view.Display
import android.graphics.Point

class FloatingWindowService : Service() {
    private val TAG = "FloatingWindowService"
    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var flutterContainer: FrameLayout? = null
    private var isExpanded = true
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var isMinimized = false
    
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

    private fun getScreenSize(): Point {
        val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val point = Point()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metrics = windowManager.currentWindowMetrics
            point.x = metrics.bounds.width()
            point.y = metrics.bounds.height()
        } else {
            @Suppress("DEPRECATION")
            val display = windowManager.defaultDisplay
            display.getSize(point)
        }
        
        return point
    }

    private fun initializeFloatingWindow() {
        try {
            Log.d(TAG, "Initializing floating window")
            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            floatingView = LayoutInflater.from(this).inflate(R.layout.floating_window_layout, null)

            // 查找必要的视图
            flutterContainer = floatingView?.findViewById(R.id.flutterContainer)
            
            // 获取屏幕尺寸
            val screenSize = getScreenSize()
            
            // 设置悬浮窗参数
            params = WindowManager.LayoutParams().apply {
                width = (screenSize.x * 0.5).toInt()
                height = (screenSize.y * 0.4).toInt()
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

            // 设置按钮点击事件
            setupButtons()
            
            // 添加触摸事件处理
            setupTouchListener()

            // 添加悬浮窗到窗口管理器
            windowManager?.addView(floatingView, params)
            
            // 初始化FlutterView（移到添加视图之后）
            initFlutterView()
            
            Log.d(TAG, "Floating window initialized successfully")
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
        Log.d(TAG, "Setting up buttons")
        try {
            // 关闭按钮改为最小化
            floatingView?.findViewById<ImageButton>(R.id.btnClose)?.setOnClickListener {
                Log.d(TAG, "Minimize button clicked")
                minimizeWindow()
            }

            // 最小化图标点击恢复
            floatingView?.findViewById<View>(R.id.minimizedIcon)?.setOnClickListener {
                Log.d(TAG, "Minimized icon clicked")
                restoreWindow()
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
            Log.d(TAG, "Buttons set up successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up buttons", e)
            e.printStackTrace()
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

        // 为根视图和最小化图标都添加触摸监听
        val touchListener = View.OnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params?.x ?: 0
                    initialY = params?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isMoved = false
                    // 让Flutter视图可以接收触摸事件
                    params?.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
                    windowManager?.updateViewLayout(floatingView, params)
                    false
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = event.rawX - initialTouchX
                    val deltaY = event.rawY - initialTouchY
                    if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
                        isMoved = true
                        params?.x = (initialX + deltaX).toInt()
                        params?.y = (initialY + deltaY).toInt()
                        windowManager?.updateViewLayout(floatingView, params)
                    }
                    isMoved
                }
                MotionEvent.ACTION_UP -> {
                    if (!isMoved) {
                        // 如果没有移动，恢复正常的触摸事件处理
                        params?.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        windowManager?.updateViewLayout(floatingView, params)
                        // 如果是最小化图标被点击，则恢复���口
                        if (isMinimized && view.id == R.id.minimizedIcon) {
                            restoreWindow()
                        }
                        false
                    } else {
                        // 如果移动了，消费这个事件
                        true
                    }
                }
                else -> false
            }
        }

        // 为根视图添加触摸监听
        floatingView?.findViewById<CardView>(R.id.root)?.setOnTouchListener(touchListener)
        
        // 为最小化图标添加触摸监听
        floatingView?.findViewById<View>(R.id.minimizedIcon)?.setOnTouchListener(touchListener)

        // 为Flutter容器添加触摸监听
        flutterContainer?.setOnTouchListener { _, event ->
            // 始终允许Flutter处理触摸事件
            false
        }
    }

    private fun minimizeWindow() {
        try {
            isMinimized = true
            val screenSize = getScreenSize()
            
            params?.apply {
                width = 32
                height = 32
                x = screenSize.x - width - 16
                y = screenSize.y / 2 - height / 2
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            }
            
            // 更新UI
            floatingView?.apply {
                findViewById<View>(R.id.contentContainer)?.visibility = View.GONE
                findViewById<View>(R.id.minimizedIcon)?.visibility = View.VISIBLE
            }
            
            // 更新窗口布局
            windowManager?.updateViewLayout(floatingView, params)
            Log.d(TAG, "Window minimized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error minimizing window", e)
        }
    }
    
    private fun restoreWindow() {
        try {
            isMinimized = false
            val screenSize = getScreenSize()
            
            params?.apply {
                width = (screenSize.x * 0.5).toInt()
                height = (screenSize.y * 0.4).toInt()
                x = (screenSize.x - width) / 2
                y = (screenSize.y - height) / 2
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            }
            
            // 更新UI
            floatingView?.apply {
                findViewById<View>(R.id.contentContainer)?.visibility = View.VISIBLE
                findViewById<View>(R.id.minimizedIcon)?.visibility = View.GONE
            }
            
            // 更新窗口布局
            windowManager?.updateViewLayout(floatingView, params)
            Log.d(TAG, "Window restored successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error restoring window", e)
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
        // 销毁悬浮窗引擎
        FlutterEngineManager.getInstance(this).destroyFloatingWindowEngine()
    }
} 