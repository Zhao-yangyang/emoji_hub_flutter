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
import android.graphics.Point
import android.widget.ImageView
import android.animation.ValueAnimator
import android.view.animation.DecelerateInterpolator
import android.animation.Animator
import android.animation.AnimatorListenerAdapter

class FloatingWindowService : Service() {
    private val TAG = "FloatingWindowService"
    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var flutterContainer: FrameLayout? = null
    private var isAnimating = false
    
    // 窗口状态枚举
    enum class WindowState {
        EXPANDED,    // 完整模式
        MINIMIZED,   // 最小化模式
        COLLAPSED    // 收缩模式
    }
    
    private var currentState = WindowState.EXPANDED
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private val SNAP_THRESHOLD = 24  // 吸附阈值（dp）
    private val EDGE_THRESHOLD = 100 // 边缘检测阈值（dp）
    
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
            // 最小化按钮
            floatingView?.findViewById<ImageButton>(R.id.btnMinimize)?.setOnClickListener {
                Log.d(TAG, "Minimize button clicked")
                minimizeWindow()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up buttons", e)
            e.printStackTrace()
        }
    }

    private fun setupTouchListener() {
        var initialX: Int = 0
        var initialY: Int = 0
        var initialTouchX: Float = 0f
        var initialTouchY: Float = 0f
        var isMoved = false
        var lastClickTime = 0L
        val DOUBLE_CLICK_TIME = 300L

        val touchListener = View.OnTouchListener { view, event ->
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
                    val deltaX = event.rawX - initialTouchX
                    val deltaY = event.rawY - initialTouchY
                    if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
                        isMoved = true
                        params?.apply {
                            x = (initialX + deltaX).toInt()
                            y = (initialY + deltaY).toInt()
                        }
                        windowManager?.updateViewLayout(floatingView, params)
                        if (currentState == WindowState.MINIMIZED) {
                            updateEdgeState()
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isMoved) {
                        val currentTime = System.currentTimeMillis()
                        if (currentTime - lastClickTime < DOUBLE_CLICK_TIME) {
                            // 双击展开
                            if (currentState != WindowState.EXPANDED) {
                                restoreWindow()
                            }
                        } else {
                            // 单击处理
                            when (currentState) {
                                WindowState.MINIMIZED -> {
                                    // 检查是否点击了箭头区域
                                    val arrowAreaWidth = dpToPx(48)
                                    val totalWidth = params?.width ?: 0
                                    if (event.x >= totalWidth - arrowAreaWidth) {
                                        handleArrowClick()
                                    }
                                }
                                WindowState.COLLAPSED -> {
                                    handleArrowClick()
                                }
                                else -> {}
                            }
                        }
                        lastClickTime = currentTime
                    } else {
                        // 处理拖动结束
                        when (currentState) {
                            WindowState.MINIMIZED -> {
                                checkAndSnapToEdge()
                            }
                            WindowState.COLLAPSED -> {
                                snapToEdge(true)
                            }
                            else -> {}
                        }
                    }
                    true
                }
                else -> false
            }
        }

        // 为可拖动区域添加触摸监听器
        floatingView?.findViewById<View>(R.id.touchArea)?.setOnTouchListener(touchListener)
        floatingView?.findViewById<View>(R.id.dragHandle)?.setOnTouchListener(touchListener)
    }

    private fun minimizeWindow() {
        if (isAnimating || currentState == WindowState.MINIMIZED) return
        
        try {
            val screenSize = getScreenSize()
            isAnimating = true
            
            // 保存当前尺寸
            val startWidth = params?.width ?: 0
            val startHeight = params?.height ?: 0
            val startX = params?.x ?: 0
            val startY = params?.y ?: 0
            
            // 设置目标尺寸
            val targetWidth = dpToPx(160)
            val targetHeight = dpToPx(48)
            val targetX = screenSize.x - targetWidth - dpToPx(16)
            val targetY = screenSize.y / 3
            
            // 创建动画
            val sizeAnimator = ValueAnimator.ofFloat(0f, 1f)
            sizeAnimator.duration = 250
            sizeAnimator.interpolator = DecelerateInterpolator()
            
            sizeAnimator.addUpdateListener { animation ->
                val progress = animation.animatedValue as Float
                params?.apply {
                    width = lerp(startWidth, targetWidth, progress)
                    height = lerp(startHeight, targetHeight, progress)
                    x = lerp(startX, targetX, progress)
                    y = lerp(startY, targetY, progress)
                }
                windowManager?.updateViewLayout(floatingView, params)
            }
            
            sizeAnimator.addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    isAnimating = false
                    currentState = WindowState.MINIMIZED
                    updateViewVisibility()
                    updateEdgeState()
                }
            })
            
            // 开始动画
            sizeAnimator.start()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error minimizing window", e)
            isAnimating = false
        }
    }

    private fun updateViewVisibility() {
        floatingView?.apply {
            when (currentState) {
                WindowState.EXPANDED -> {
                    findViewById<View>(R.id.expandedContainer)?.visibility = View.VISIBLE
                    findViewById<View>(R.id.minimizedContainer)?.visibility = View.GONE
                }
                WindowState.MINIMIZED -> {
                    findViewById<View>(R.id.expandedContainer)?.visibility = View.GONE
                    findViewById<View>(R.id.minimizedContainer)?.visibility = View.VISIBLE
                    findViewById<View>(R.id.minimizedContent)?.visibility = View.VISIBLE
                    findViewById<View>(R.id.collapsedContent)?.visibility = View.GONE
                }
                WindowState.COLLAPSED -> {
                    findViewById<View>(R.id.expandedContainer)?.visibility = View.GONE
                    findViewById<View>(R.id.minimizedContainer)?.visibility = View.VISIBLE
                    findViewById<View>(R.id.minimizedContent)?.visibility = View.GONE
                    findViewById<View>(R.id.collapsedContent)?.visibility = View.VISIBLE
                }
            }
        }
    }

    private fun updateEdgeState() {
        if (currentState != WindowState.MINIMIZED) return
        
        val screenSize = getScreenSize()
        val x = params?.x ?: 0
        val width = params?.width ?: 0
        val distanceToLeft = x
        val distanceToRight = screenSize.x - (x + width)
        
        // 获取箭头图标
        val arrowIcon = floatingView?.findViewById<ImageView>(R.id.arrowIcon)
        
        // 根据距离边缘的距离显示或隐藏箭头
        if (distanceToLeft < dpToPx(EDGE_THRESHOLD) || distanceToRight < dpToPx(EDGE_THRESHOLD)) {
            arrowIcon?.apply {
                visibility = View.VISIBLE
                rotation = if (distanceToLeft < distanceToRight) 180f else 0f
            }
        } else {
            arrowIcon?.visibility = View.GONE
        }
    }

    private fun handleArrowClick() {
        if (isAnimating) return
        
        when (currentState) {
            WindowState.MINIMIZED -> {
                collapseToArrow()
            }
            WindowState.COLLAPSED -> {
                expandToMinimized()
            }
            else -> {}
        }
    }

    private fun collapseToArrow() {
        if (isAnimating) return
        
        val screenSize = getScreenSize()
        val currentX = params?.x ?: 0
        val currentWidth = params?.width ?: 0
        val distanceToLeft = currentX
        val distanceToRight = screenSize.x - (currentX + currentWidth)
        
        // 确定目标位置
        val targetX = if (distanceToLeft < distanceToRight) 0 else screenSize.x - dpToPx(48)
        
        isAnimating = true
        
        // 创建动画
        val widthAnimator = ValueAnimator.ofInt(currentWidth, dpToPx(48))
        val positionAnimator = ValueAnimator.ofInt(currentX, targetX)
        
        widthAnimator.addUpdateListener { animation ->
            params?.width = animation.animatedValue as Int
            windowManager?.updateViewLayout(floatingView, params)
        }
        
        positionAnimator.addUpdateListener { animation ->
            params?.x = animation.animatedValue as Int
            windowManager?.updateViewLayout(floatingView, params)
        }
        
        widthAnimator.duration = 200
        positionAnimator.duration = 200
        
        widthAnimator.addListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) {
                currentState = WindowState.COLLAPSED
                updateViewVisibility()
                isAnimating = false
                
                // ���置箭头方向
                floatingView?.findViewById<ImageView>(R.id.collapsedIcon)?.apply {
                    rotation = if (targetX == 0) 0f else 180f
                }
            }
        })
        
        widthAnimator.start()
        positionAnimator.start()
    }

    private fun expandToMinimized() {
        if (isAnimating) return
        
        val currentX = params?.x ?: 0
        isAnimating = true
        
        // 只改变宽度，保持x位置不变
        val widthAnimator = ValueAnimator.ofInt(dpToPx(48), dpToPx(160))
        
        widthAnimator.addUpdateListener { animation ->
            params?.width = animation.animatedValue as Int
            windowManager?.updateViewLayout(floatingView, params)
        }
        
        widthAnimator.duration = 200
        
        widthAnimator.addListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) {
                currentState = WindowState.MINIMIZED
                updateViewVisibility()
                updateEdgeState()
                isAnimating = false
            }
        })
        
        widthAnimator.start()
    }

    private fun checkAndSnapToEdge() {
        val screenSize = getScreenSize()
        val x = params?.x ?: 0
        val width = params?.width ?: 0
        val distanceToLeft = x
        val distanceToRight = screenSize.x - (x + width)
        
        if (distanceToLeft < dpToPx(EDGE_THRESHOLD) || distanceToRight < dpToPx(EDGE_THRESHOLD)) {
            val targetX = if (distanceToLeft < distanceToRight) 0 else screenSize.x - width
            snapToEdge(true, targetX)
        }
    }

    private fun snapToEdge(animate: Boolean, targetX: Int? = null) {
        val screenSize = getScreenSize()
        val width = params?.width ?: 0
        val currentX = params?.x ?: 0
        
        val finalTargetX = targetX ?: if (currentX < screenSize.x / 2) 0 else screenSize.x - width
        
        if (animate) {
            val animator = ValueAnimator.ofInt(currentX, finalTargetX)
            animator.duration = 150
            animator.interpolator = DecelerateInterpolator()
            
            animator.addUpdateListener { animation ->
                params?.x = animation.animatedValue as Int
                windowManager?.updateViewLayout(floatingView, params)
            }
            
            animator.start()
        } else {
            params?.x = finalTargetX
            windowManager?.updateViewLayout(floatingView, params)
        }
    }

    // 添加线性插值辅助方法
    private fun lerp(start: Int, end: Int, fraction: Float): Int {
        return (start + (end - start) * fraction).toInt()
    }

    // 添加dp转px的辅助方法
    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }

    private fun restoreWindow() {
        if (isAnimating || currentState == WindowState.EXPANDED) return
        
        try {
            val screenSize = getScreenSize()
            isAnimating = true
            
            // 保存当前尺寸
            val startWidth = params?.width ?: 0
            val startHeight = params?.height ?: 0
            val startX = params?.x ?: 0
            val startY = params?.y ?: 0
            
            // 设置目标尺寸
            val targetWidth = (screenSize.x * 0.5).toInt()
            val targetHeight = (screenSize.y * 0.4).toInt()
            val targetX = (screenSize.x - targetWidth) / 2
            val targetY = (screenSize.y - targetHeight) / 2
            
            // 创建动画
            val sizeAnimator = ValueAnimator.ofFloat(0f, 1f)
            sizeAnimator.duration = 250
            sizeAnimator.interpolator = DecelerateInterpolator()
            
            sizeAnimator.addUpdateListener { animation ->
                val progress = animation.animatedValue as Float
                params?.apply {
                    width = lerp(startWidth, targetWidth, progress)
                    height = lerp(startHeight, targetHeight, progress)
                    x = lerp(startX, targetX, progress)
                    y = lerp(startY, targetY, progress)
                }
                windowManager?.updateViewLayout(floatingView, params)
            }
            
            sizeAnimator.addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    isAnimating = false
                    currentState = WindowState.EXPANDED
                    updateViewVisibility()
                }
            })
            
            // 开始动画
            sizeAnimator.start()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error restoring window", e)
            isAnimating = false
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