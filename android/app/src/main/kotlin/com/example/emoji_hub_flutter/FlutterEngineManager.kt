package com.example.emoji_hub_flutter

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint

class FlutterEngineManager private constructor(context: Context) {
    private var flutterEngine: FlutterEngine? = null
    private val CHANNEL = "com.emojihub.floating_window"
    private val ENGINE_ID = "floating_window_engine"
    private val INITIAL_ROUTE = "/floating_window"
    
    init {
        initializeEngine(context)
    }

    private fun initializeEngine(context: Context) {
        try {
            flutterEngine = FlutterEngine(context)
            
            // 设置初始路由
            flutterEngine?.navigationChannel?.setInitialRoute(INITIAL_ROUTE)
            
            // 设置入口点
            flutterEngine?.dartExecutor?.executeDartEntrypoint(
                DartEntrypoint.createDefault()
            )

            // 设置方法通道
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "closeFloatingWindow" -> {
                        // 处理关闭悬浮窗的请求
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

            // 缓存引擎以供后续使用
            FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun getFlutterEngine(): FlutterEngine? = flutterEngine

    fun destroyEngine() {
        try {
            FlutterEngineCache.getInstance().remove(ENGINE_ID)
            flutterEngine?.destroy()
            flutterEngine = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    companion object {
        @Volatile
        private var instance: FlutterEngineManager? = null

        fun getInstance(context: Context): FlutterEngineManager {
            return instance ?: synchronized(this) {
                instance ?: FlutterEngineManager(context).also { instance = it }
            }
        }
    }
} 