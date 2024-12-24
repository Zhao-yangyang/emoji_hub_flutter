package com.example.emoji_hub_flutter

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.content.ClipData
import android.content.ClipboardManager
import android.net.Uri
import java.io.File
import io.flutter.embedding.engine.FlutterEngineCache
import androidx.core.content.FileProvider
import android.content.ContentValues
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import android.os.Build
import android.content.Intent

class FlutterEngineManager private constructor(private val context: Context) {
    private var mainEngine: FlutterEngine? = null
    private var floatingWindowEngine: FlutterEngine? = null
    private var clipboardChannel: MethodChannel? = null

    companion object {
        private const val TAG = "FlutterEngineManager"
        private const val CLIPBOARD_CHANNEL = "com.example.emoji_hub_flutter/clipboard"
        private const val INITIAL_ROUTE = "/floating_window"
        private const val FLOATING_WINDOW_ENGINE_ID = "floating_window_engine"
        @Volatile
        private var instance: FlutterEngineManager? = null

        fun getInstance(context: Context): FlutterEngineManager {
            return instance ?: synchronized(this) {
                instance ?: FlutterEngineManager(context.applicationContext).also { instance = it }
            }
        }
    }

    fun setFlutterEngine(engine: FlutterEngine) {
        Log.i(TAG, "Setting main Flutter engine")
        mainEngine = engine
        setupMethodChannels(engine)
    }

    private fun setupMethodChannels(engine: FlutterEngine) {
        Log.i(TAG, "Setting up method channels in FlutterEngineManager")
        // 设置剪贴板通道
        clipboardChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL)
        clipboardChannel?.setMethodCallHandler { call, result ->
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

                        // 创建临时文件
                        val cacheDir = context.cacheDir
                        val tempFile = File(cacheDir, "temp_${System.currentTimeMillis()}.jpg")
                        file.copyTo(tempFile, overwrite = true)

                        // 使用 FileProvider 获取内容 URI
                        val imageUri = FileProvider.getUriForFile(
                            context,
                            "${context.packageName}.fileprovider",
                            tempFile
                        )

                        // 创建分享意图
                        val intent = Intent().apply {
                            action = Intent.ACTION_SEND
                            type = "image/*"
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                            putExtra(Intent.EXTRA_STREAM, imageUri)
                        }

                        // 启动分享
                        context.startActivity(Intent.createChooser(intent, "分享图片").apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        })

                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error sharing image", e)
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        Log.i(TAG, "Method channels set up in FlutterEngineManager")
    }

    fun getFlutterEngine(): FlutterEngine? {
        if (floatingWindowEngine == null) {
            floatingWindowEngine = FlutterEngine(context).apply {
                navigationChannel.setInitialRoute("/floating_window")
                lifecycleChannel.appIsResumed()
                dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
            }
            setupMethodChannels(floatingWindowEngine!!)
        }
        return floatingWindowEngine
    }

    fun destroyFloatingWindowEngine() {
        Log.i(TAG, "Destroying floating window engine")
        floatingWindowEngine?.destroy()
        floatingWindowEngine = null
        FlutterEngineCache.getInstance().remove(FLOATING_WINDOW_ENGINE_ID)
    }
} 