package com.example.emoji_hub_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.app.Activity
import java.io.File
import android.util.Log
import android.widget.Toast
import android.os.Bundle

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val FLOATING_WINDOW_CHANNEL = "com.emojihub.floating_window"
        private const val PERMISSIONS_CHANNEL = "com.emojihub.permissions"
        private const val CLIPBOARD_CHANNEL = "com.example.emoji_hub_flutter/clipboard"
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1234
    }

    private var floatingWindowService: Intent? = null
    private var pendingShowWindow = false
    private lateinit var floatingWindowChannel: MethodChannel
    private lateinit var permissionsChannel: MethodChannel
    private lateinit var clipboardChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FlutterEngineManager.getInstance(this).setFlutterEngine(flutterEngine!!)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.i(TAG, "Configuring Flutter engine")
        // 初始化FlutterEngineManager并传递FlutterEngine
        FlutterEngineManager.getInstance(this).setFlutterEngine(flutterEngine)
        Log.i(TAG, "FlutterEngineManager initialized")
        
        setupMethodChannels(flutterEngine)
    }

    private fun setupMethodChannels(flutterEngine: FlutterEngine) {
        // 悬浮窗通道
        floatingWindowChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLOATING_WINDOW_CHANNEL)
        Log.i(TAG, "Setting up floating window channel: $FLOATING_WINDOW_CHANNEL")
        floatingWindowChannel.setMethodCallHandler { call, result ->
            Log.i(TAG, "Received method call: ${call.method}")
            when (call.method) {
                "showFloatingWindow" -> {
                    Log.i(TAG, "Showing floating window")
                    if (checkOverlayPermission()) {
                        showFloatingWindow()
                        result.success(null)
                    } else {
                        Log.i(TAG, "No overlay permission, requesting...")
                        pendingShowWindow = true
                        requestOverlayPermission()
                        result.success(null)
                    }
                }
                "hideFloatingWindow" -> {
                    Log.i(TAG, "Hiding floating window")
                    hideFloatingWindow()
                    result.success(null)
                }
                "toggleFloatingWindow" -> {
                    Log.i(TAG, "Toggling floating window, current service: ${floatingWindowService != null}")
                    if (floatingWindowService == null) {
                        if (checkOverlayPermission()) {
                            showFloatingWindow()
                        } else {
                            Log.i(TAG, "No overlay permission, requesting...")
                            pendingShowWindow = true
                            requestOverlayPermission()
                        }
                    } else {
                        hideFloatingWindow()
                    }
                    result.success(null)
                }
                else -> {
                    Log.i(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        // 权限通道
        permissionsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
        Log.i(TAG, "Setting up permissions channel: $PERMISSIONS_CHANNEL")
        permissionsChannel.setMethodCallHandler { call, result ->
            Log.i(TAG, "Received permission method call: ${call.method}")
            when (call.method) {
                "checkOverlayPermission" -> {
                    val hasPermission = checkOverlayPermission()
                    Log.i(TAG, "Checking overlay permission: $hasPermission")
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    Log.i(TAG, "Requesting overlay permission")
                    requestOverlayPermission()
                    result.success(null)
                }
                else -> {
                    Log.i(TAG, "Permission method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        // 剪贴板通道
        clipboardChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL)
        clipboardChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "copyImage" -> {
                    try {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_PATH", "Path cannot be null", null)
                            return@setMethodCallHandler
                        }

                        val file = File(path)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "File does not exist: $path", null)
                            return@setMethodCallHandler
                        }

                        val uri = Uri.fromFile(file)
                        val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        val clip = ClipData.newUri(contentResolver, "image", uri)
                        clipboardManager.setPrimaryClip(clip)

                        Log.d(TAG, "Image copied to clipboard: $path")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error copying image", e)
                        result.error("COPY_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        Log.i(TAG, "Method channels set up")
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val hasPermission = Settings.canDrawOverlays(this)
            Log.d(TAG, "Checking overlay permission (M+): $hasPermission")
            hasPermission
        } else {
            Log.d(TAG, "Checking overlay permission (pre-M): true")
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Log.d(TAG, "Opening overlay permission settings")
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
        }
    }

    private fun showFloatingWindow() {
        try {
            Log.d(TAG, "Creating and starting floating window service")
            if (!checkOverlayPermission()) {
                Log.e(TAG, "No overlay permission when trying to show window")
                Toast.makeText(this, "没有悬浮窗权限", Toast.LENGTH_SHORT).show()
                return
            }
            
            floatingWindowService = Intent(this, FloatingWindowService::class.java).apply {
                // 添加一些额外的标志
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Log.d(TAG, "Starting foreground service (Android O+)")
                startForegroundService(floatingWindowService)
            } else {
                Log.d(TAG, "Starting normal service (Pre-Android O)")
                startService(floatingWindowService)
            }
            
            Toast.makeText(this, "悬浮窗服务已启动", Toast.LENGTH_SHORT).show()
            Log.d(TAG, "Service start command sent successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start floating window service", e)
            e.printStackTrace()
            Toast.makeText(this, "启动悬浮窗失败: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun hideFloatingWindow() {
        try {
            Log.d(TAG, "Stopping floating window service")
            floatingWindowService?.let { 
                stopService(it)
                floatingWindowService = null
                Toast.makeText(this, "悬浮窗服务已停止", Toast.LENGTH_SHORT).show()
                Log.d(TAG, "Service stopped successfully")
            } ?: run {
                Log.w(TAG, "Service was already null when trying to hide")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop floating window service", e)
            e.printStackTrace()
            Toast.makeText(this, "关闭悬浮窗失败: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            val hasPermission = checkOverlayPermission()
            Log.d(TAG, "Overlay permission result: $hasPermission, pendingShow: $pendingShowWindow")
            if (hasPermission && pendingShowWindow) {
                showFloatingWindow()
                pendingShowWindow = false
            }
        }
    }

    override fun onBackPressed() {
        moveTaskToBack(true)
    }
}
