package com.example.flutter_application_initial

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.os.Build
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.flutter_application_initial/tflite"
    private var interpreter: Any? = null  // Dynamic type để tránh crash khi không có TFLite
    private var flexDelegate: Any? = null
    private var isModelLoaded = false
    private var isArmArchitecture = false
    
    companion object {
        private const val TAG = "TFLite"
        
        // Kiểm tra kiến trúc CPU
        fun isArmDevice(): Boolean {
            val abis = Build.SUPPORTED_ABIS
            Log.d(TAG, "Supported ABIs: ${abis.joinToString()}")
            return abis.any { it.contains("arm", ignoreCase = true) }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        isArmArchitecture = isArmDevice()
        Log.d(TAG, "Is ARM architecture: $isArmArchitecture")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isFlexDelegateReady" -> {
                    result.success(isArmArchitecture)
                }
                "ensureFlexDelegateReady" -> {
                    result.success(isArmArchitecture)
                }
                "getArchitecture" -> {
                    result.success(mapOf(
                        "isArm" to isArmArchitecture,
                        "abis" to Build.SUPPORTED_ABIS.toList()
                    ))
                }
                "loadModel" -> {
                    if (!isArmArchitecture) {
                        Log.w(TAG, "⚠️ TensorFlow Lite không hỗ trợ x86/x86_64")
                        result.error("NOT_SUPPORTED", "TensorFlow Lite Flex chỉ hỗ trợ ARM. Vui lòng sử dụng điện thoại thật để test ML.", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val modelPath = call.argument<String>("modelPath") ?: "assets/models/tf_lstm_best.tflite"
                        loadModelOnArm(modelPath)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Lỗi load model: ${e.message}")
                        result.error("LOAD_ERROR", e.message, null)
                    }
                }
                "runInference" -> {
                    if (!isArmArchitecture || interpreter == null) {
                        result.error("NOT_SUPPORTED", "TensorFlow Lite không khả dụng trên thiết bị này", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val inputData = call.argument<List<List<List<Double>>>>("input")
                        if (inputData == null) {
                            result.error("INPUT_ERROR", "Input data is null", null)
                            return@setMethodCallHandler
                        }
                        
                        val output = runInferenceOnArm(inputData)
                        result.success(output)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Lỗi inference: ${e.message}")
                        result.error("INFERENCE_ERROR", e.message, null)
                    }
                }
                "getInputShape" -> {
                    if (!isArmArchitecture || interpreter == null) {
                        result.error("NOT_SUPPORTED", "TensorFlow Lite không khả dụng", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val shape = getInputShapeOnArm()
                        result.success(shape)
                    } catch (e: Exception) {
                        result.error("SHAPE_ERROR", e.message, null)
                    }
                }
                "getOutputShape" -> {
                    if (!isArmArchitecture || interpreter == null) {
                        result.error("NOT_SUPPORTED", "TensorFlow Lite không khả dụng", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val shape = getOutputShapeOnArm()
                        result.success(shape)
                    } catch (e: Exception) {
                        result.error("SHAPE_ERROR", e.message, null)
                    }
                }
                "disposeModel" -> {
                    disposeModel()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun loadModelOnArm(modelPath: String) {
        if (isModelLoaded) {
            Log.d(TAG, "Model đã được load trước đó")
            return
        }
        
        Log.d(TAG, "📦 Đang load model từ: $modelPath")
        
        // Flutter assets được lưu với prefix "flutter_assets/" trong APK
        val flutterAssetPath = "flutter_assets/$modelPath"
        Log.d(TAG, "   Flutter asset path: $flutterAssetPath")
        
        // Load model từ assets
        val assetFileDescriptor = assets.openFd(flutterAssetPath)
        val inputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = assetFileDescriptor.startOffset
        val declaredLength = assetFileDescriptor.declaredLength
        val modelBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
        
        Log.d(TAG, "   Model size: ${declaredLength} bytes")
        
        // Sử dụng reflection để load TensorFlow Lite (tránh crash nếu không có)
        try {
            val flexDelegateClass = Class.forName("org.tensorflow.lite.flex.FlexDelegate")
            flexDelegate = flexDelegateClass.getDeclaredConstructor().newInstance()
            Log.d(TAG, "✅ Đã tạo FlexDelegate")
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Không thể tạo FlexDelegate: ${e.message}")
        }
        
        // Tạo Interpreter options
        val optionsClass = Class.forName("org.tensorflow.lite.Interpreter\$Options")
        val options = optionsClass.getDeclaredConstructor().newInstance()
        
        // Set threads
        val setNumThreadsMethod = optionsClass.getMethod("setNumThreads", Int::class.java)
        setNumThreadsMethod.invoke(options, 4)
        
        // Thêm FlexDelegate nếu có
        if (flexDelegate != null) {
            val delegateClass = Class.forName("org.tensorflow.lite.Delegate")
            val addDelegateMethod = optionsClass.getMethod("addDelegate", delegateClass)
            addDelegateMethod.invoke(options, flexDelegate)
            Log.d(TAG, "✅ Đã thêm FlexDelegate vào Interpreter")
        }
        
        // Tạo Interpreter
        val interpreterClass = Class.forName("org.tensorflow.lite.Interpreter")
        val constructor = interpreterClass.getConstructor(ByteBuffer::class.java, optionsClass)
        interpreter = constructor.newInstance(modelBuffer, options)
        isModelLoaded = true
        
        Log.d(TAG, "✅ Đã load model thành công!")
        
        // Log shapes
        try {
            val getInputTensorMethod = interpreterClass.getMethod("getInputTensor", Int::class.java)
            val inputTensor = getInputTensorMethod.invoke(interpreter, 0)
            val shapeMethod = inputTensor!!.javaClass.getMethod("shape")
            val inputShape = shapeMethod.invoke(inputTensor) as IntArray
            Log.d(TAG, "   Input shape: ${inputShape.toList()}")
            
            val getOutputTensorMethod = interpreterClass.getMethod("getOutputTensor", Int::class.java)
            val outputTensor = getOutputTensorMethod.invoke(interpreter, 0)
            val outputShape = shapeMethod.invoke(outputTensor) as IntArray
            Log.d(TAG, "   Output shape: ${outputShape.toList()}")
        } catch (e: Exception) {
            Log.w(TAG, "   Không thể lấy shapes: ${e.message}")
        }
    }
    
    private fun runInferenceOnArm(inputData: List<List<List<Double>>>): List<Double> {
        if (interpreter == null) {
            throw Exception("Model chưa được load")
        }
        
        val interpreterClass = Class.forName("org.tensorflow.lite.Interpreter")
        
        // Lấy input shape từ model
        val getInputTensorMethod = interpreterClass.getMethod("getInputTensor", Int::class.java)
        val inputTensor = getInputTensorMethod.invoke(interpreter, 0)
        val shapeMethod = inputTensor!!.javaClass.getMethod("shape")
        val inputShape = shapeMethod.invoke(inputTensor) as IntArray
        
        val batchSize = inputShape[0]
        val sequenceLength = inputShape[1]
        val numKeypoints = inputShape[2]
        
        // Tạo input buffer
        val inputBuffer = ByteBuffer.allocateDirect(batchSize * sequenceLength * numKeypoints * 4)
        inputBuffer.order(ByteOrder.nativeOrder())
        
        // Copy data vào buffer
        for (batch in inputData) {
            for (sequence in batch) {
                for (value in sequence) {
                    inputBuffer.putFloat(value.toFloat())
                }
            }
        }
        inputBuffer.rewind()
        
        // Lấy output shape
        val getOutputTensorMethod = interpreterClass.getMethod("getOutputTensor", Int::class.java)
        val outputTensor = getOutputTensorMethod.invoke(interpreter, 0)
        val outputShape = shapeMethod.invoke(outputTensor) as IntArray
        val numClasses = outputShape[1]
        
        // Tạo output buffer
        val outputBuffer = ByteBuffer.allocateDirect(batchSize * numClasses * 4)
        outputBuffer.order(ByteOrder.nativeOrder())
        
        // Chạy inference
        val runMethod = interpreterClass.getMethod("run", Any::class.java, Any::class.java)
        runMethod.invoke(interpreter, inputBuffer, outputBuffer)
        
        // Đọc kết quả
        outputBuffer.rewind()
        val output = mutableListOf<Double>()
        for (i in 0 until numClasses) {
            output.add(outputBuffer.float.toDouble())
        }
        
        return output
    }
    
    private fun getInputShapeOnArm(): List<Int> {
        if (interpreter == null) {
            throw Exception("Model chưa được load")
        }
        val interpreterClass = Class.forName("org.tensorflow.lite.Interpreter")
        val getInputTensorMethod = interpreterClass.getMethod("getInputTensor", Int::class.java)
        val inputTensor = getInputTensorMethod.invoke(interpreter, 0)
        val shapeMethod = inputTensor!!.javaClass.getMethod("shape")
        return (shapeMethod.invoke(inputTensor) as IntArray).toList()
    }
    
    private fun getOutputShapeOnArm(): List<Int> {
        if (interpreter == null) {
            throw Exception("Model chưa được load")
        }
        val interpreterClass = Class.forName("org.tensorflow.lite.Interpreter")
        val getOutputTensorMethod = interpreterClass.getMethod("getOutputTensor", Int::class.java)
        val outputTensor = getOutputTensorMethod.invoke(interpreter, 0)
        val shapeMethod = outputTensor!!.javaClass.getMethod("shape")
        return (shapeMethod.invoke(outputTensor) as IntArray).toList()
    }
    
    private fun disposeModel() {
        try {
            if (interpreter != null) {
                val interpreterClass = Class.forName("org.tensorflow.lite.Interpreter")
                val closeMethod = interpreterClass.getMethod("close")
                closeMethod.invoke(interpreter)
            }
            if (flexDelegate != null) {
                val delegateClass = flexDelegate!!.javaClass
                val closeMethod = delegateClass.getMethod("close")
                closeMethod.invoke(flexDelegate)
            }
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Lỗi khi dispose: ${e.message}")
        }
        interpreter = null
        flexDelegate = null
        isModelLoaded = false
        Log.d(TAG, "🗑️ Đã giải phóng model")
    }
    
    override fun onDestroy() {
        disposeModel()
        super.onDestroy()
    }
}
