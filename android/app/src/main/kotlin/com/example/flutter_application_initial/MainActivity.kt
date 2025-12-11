package com.example.flutter_application_initial

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.flutter_application_initial/tflite"
    
    companion object {
        private const val TAG = "MainActivity"
        private var flexDelegateLoaded = false
        
        init {
            // Load TensorFlow Lite core library TRƯỚC
            try {
                System.loadLibrary("tensorflowlite_jni")
                Log.d(TAG, "✅ Loaded libtensorflowlite_jni.so")
            } catch (e: UnsatisfiedLinkError) {
                Log.d(TAG, "ℹ️ tensorflowlite_jni không tìm thấy (có thể được load tự động)")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Could not load tensorflowlite_jni: ${e.message}")
            }
            
            // Load Flex Delegate library - QUAN TRỌNG cho SELECT_TF_OPS models
            // Phải load SAU tensorflowlite_jni
            try {
                // Đợi một chút để core library được load hoàn toàn
                Thread.sleep(100)
                
                System.loadLibrary("tensorflowlite_flex_jni")
                Log.d(TAG, "✅ Loaded libtensorflowlite_flex_jni.so")
                
                // Đợi thêm để đảm bảo library được link hoàn toàn
                Thread.sleep(200)
                
                flexDelegateLoaded = true
                Log.d(TAG, "✅ Flex delegate đã sẵn sàng")
                Log.d(TAG, "✅ FlexDelegate sẽ tự động được sử dụng khi tạo Interpreter với SELECT_TF_OPS model")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "❌ Could not load flex delegate: ${e.message}")
                Log.e(TAG, "   Kiểm tra file libtensorflowlite_flex_jni.so có trong jniLibs/")
                Log.e(TAG, "   Architecture: ${android.os.Build.SUPPORTED_ABIS.joinToString()}")
                flexDelegateLoaded = false
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error loading flex delegate: ${e.message}")
                flexDelegateLoaded = false
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isFlexDelegateReady" -> {
                    result.success(flexDelegateLoaded)
                }
                "ensureFlexDelegateReady" -> {
                    if (flexDelegateLoaded) {
                        Log.d(TAG, "✅ FlexDelegate đã sẵn sàng")
                        // Đợi một chút để đảm bảo FlexDelegate được register
                        Thread.sleep(1000)
                        result.success(true)
                    } else {
                        Log.e(TAG, "❌ FlexDelegate chưa được load")
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
