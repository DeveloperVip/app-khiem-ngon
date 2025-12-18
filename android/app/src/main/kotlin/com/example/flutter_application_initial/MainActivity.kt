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

// MediaPipe Tasks Vision Imports
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker.PoseLandmarkerOptions
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker.HandLandmarkerOptions
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker.FaceLandmarkerOptions
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage

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
                        val modelPath = call.argument<String>("modelPath") ?: "assets/models/tf_lstm_vocab_best.tflite"
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
                "processFrame" -> {
                    try {
                        val yBytes = call.argument<ByteArray>("yBytes")
                        val uBytes = call.argument<ByteArray>("uBytes")
                        val vBytes = call.argument<ByteArray>("vBytes")
                        val width = call.argument<Int>("width")
                        val height = call.argument<Int>("height")
                        val yRowStride = call.argument<Int>("yRowStride")
                        val uvRowStride = call.argument<Int>("uvRowStride")
                        val uvPixelStride = call.argument<Int>("uvPixelStride")
                        
                        if (yBytes == null || uBytes == null || vBytes == null || width == null || height == null) {
                            result.error("INVALID_ARGS", "Missing arguments", null)
                            return@setMethodCallHandler
                        }
                        
                        val keypoints = processFrame(
                            yBytes, uBytes, vBytes, width, height, 
                            yRowStride ?: width, 
                            uvRowStride ?: width, 
                            uvPixelStride ?: 2
                        )
                        result.success(keypoints)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Process Frame Error: ${e.message}")
                        result.error("PROCESS_ERROR", e.message, null)
                    }
                }
                "processVideoFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGS", "File path is null", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        // Trích xuất frame từ video file
                        val retriever = android.media.MediaMetadataRetriever()
                        retriever.setDataSource(filePath)
                        
                        // Lấy thời lượng để lấy frame ở giữa (nơi hành động thường rõ nhất)
                        val durationStr = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_DURATION)
                        val durationMs = durationStr?.toLongOrNull() ?: 0L
                        val timeMicroseconds = (durationMs / 2) * 1000 
                        
                        // Lấy frame (Bitmap)
                        val bitmap = retriever.getFrameAtTime(timeMicroseconds, android.media.MediaMetadataRetriever.OPTION_CLOSEST)
                        retriever.release()

                        if (bitmap != null) {
                            ensureMediaPipeInitialized()
                            if (poseLandmarker == null) { // Check init fail
                                result.error("INIT_ERROR", "MediaPipe not ready", null)
                                return@setMethodCallHandler
                            }

                            // Chạy MediaPipe trên Bitmap này
                            val mpImage = com.google.mediapipe.framework.image.BitmapImageBuilder(bitmap).build()
                            
                            val poseResult = poseLandmarker!!.detect(mpImage)
                            val faceResult = faceLandmarker!!.detect(mpImage)
                            val handsResult = handLandmarker!!.detect(mpImage)
                            
                            val keypoints = extractKeypointsFromTasksResults(poseResult, faceResult, handsResult)
                            result.success(keypoints)
                        } else {
                            result.error("FRAME_ERROR", "Could not extract frame from video", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Process Video Error: ${e.message}")
                        result.error("PROCESS_ERROR", e.message, null)
                    }
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
             poseLandmarker?.close()
             faceLandmarker?.close()
             handLandmarker?.close()
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Lỗi khi dispose: ${e.message}")
        }
        interpreter = null
        flexDelegate = null
        isModelLoaded = false
        poseLandmarker = null
        faceLandmarker = null
        handLandmarker = null
        Log.d(TAG, "🗑️ Đã giải phóng model và mediapipe")
    }

    // --- MEDIAPIPE TASKS VISION IMPLEMENTATION (2024 API) ---
    private var poseLandmarker: com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker? = null
    private var faceLandmarker: com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker? = null
    private var handLandmarker: com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker? = null
    
    private fun ensureMediaPipeInitialized() {
        // MediaPipe Native libraries (JNI) are typically only available for ARM architectures.
        // Running on x86/x86_64 Emulators will cause UnsatisfiedLinkError.
        if (!isArmDevice()) {
            if (!isModelLoaded) { // Log only once to avoid spam
                 Log.e(TAG, "❌ MediaPipe KHÔNG hỗ trợ giả lập x86. Vui lòng sử dụng thiết bị Android thật (ARM) để sử dụng tính năng này.")
                 isModelLoaded = true // Flag to suppress repeated errors
            }
            return
        }

        if (poseLandmarker == null) {
             try {
                // Initialize Pose
                val poseOptions = PoseLandmarker.PoseLandmarkerOptions.builder()
                    .setBaseOptions(BaseOptions.builder().setModelAssetPath("pose_landmarker.task").build())
                    .setRunningMode(RunningMode.IMAGE)
                    .setNumPoses(1)
                    .setMinPoseDetectionConfidence(0.5f)
                    .setMinPosePresenceConfidence(0.5f)
                    .setMinTrackingConfidence(0.5f)
                    .build()
                poseLandmarker = PoseLandmarker.createFromOptions(this, poseOptions)
                
                // Initialize Face
                val faceOptions = FaceLandmarker.FaceLandmarkerOptions.builder()
                    .setBaseOptions(BaseOptions.builder().setModelAssetPath("face_landmarker.task").build())
                    .setRunningMode(RunningMode.IMAGE)
                    .setNumFaces(1)
                    .setMinFaceDetectionConfidence(0.5f)
                    .setMinFacePresenceConfidence(0.5f)
                    .setMinTrackingConfidence(0.5f)
                    .build()
                faceLandmarker = FaceLandmarker.createFromOptions(this, faceOptions)
                
                // Initialize Hands
                val handOptions = HandLandmarker.HandLandmarkerOptions.builder()
                    .setBaseOptions(BaseOptions.builder().setModelAssetPath("hand_landmarker.task").build())
                    .setRunningMode(RunningMode.IMAGE)
                    .setNumHands(2)
                    .setMinHandDetectionConfidence(0.5f)
                    .setMinHandPresenceConfidence(0.5f)
                    .setMinTrackingConfidence(0.5f)
                    .build()
                handLandmarker = HandLandmarker.createFromOptions(this, handOptions)
                
                Log.d(TAG, "✅ Đã khởi tạo MediaPipe Tasks Vision thành công")
             } catch (e:  Throwable) { // Catch both Exception and Error (UnsatisfiedLinkError)
                 Log.e(TAG, "❌ Lỗi khởi tạo MediaPipe: ${e.message}")
                 // In case of error, try to clean up
                 disposeModel()
             }
        }
    }

    // Input: YUV Bytes, Output: List<Double> (1662 keypoints)
    private fun processFrame(
        yBytes: ByteArray, 
        uBytes: ByteArray, 
        vBytes: ByteArray, 
        width: Int, 
        height: Int, 
        yRowStride: Int, 
        uvRowStride: Int, 
        uvPixelStride: Int
    ): List<Double> {
        
        ensureMediaPipeInitialized()
        if (poseLandmarker == null || faceLandmarker == null || handLandmarker == null) return List(1662) { 0.0 }
        
        // 1. Convert YUV to Bitmap
        val bitmap = yuv420ToBitmap(yBytes, uBytes, vBytes, width, height, yRowStride, uvRowStride, uvPixelStride) 
            ?: return List(1662) { 0.0 }
        
        // 2. Create MPImage
        val mpImage = com.google.mediapipe.framework.image.BitmapImageBuilder(bitmap).build()
        
        // 3. Run MediaPipe (Sequentially)
        // Using RunningMode.IMAGE, so we just call detect(image)
        val poseResult = poseLandmarker!!.detect(mpImage)
        val faceResult = faceLandmarker!!.detect(mpImage)
        val handsResult = handLandmarker!!.detect(mpImage)
        
        // 4. Combine results
        return extractKeypointsFromTasksResults(poseResult, faceResult, handsResult)
    }
    
    private fun extractKeypointsFromTasksResults(
        poseResult: com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult,
        faceResult: com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult,
        handsResult: com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
    ): List<Double> {
        val keypoints = ArrayList<Double>(1662)
        
        // 1. Pose: 33 items * 4 (x, y, z, visibility) = 132
        val poseLandmarksList = poseResult.landmarks()
        if (poseLandmarksList.isNotEmpty()) {
            val landmarks = poseLandmarksList[0] // First pose
            for (lm in landmarks) {
                keypoints.add(lm.x().toDouble())
                keypoints.add(lm.y().toDouble())
                keypoints.add(lm.z().toDouble())
                // Visibility is optional in NormalizedLandmark in Tasks? 
                // Tasks Vision NormalizedLandmark has visibility() method returning Optional.
                val vis = if (lm.visibility().isPresent) lm.visibility().get() else 0.0f
                keypoints.add(vis.toDouble())
            }
             // Check if less than 33? usually always 33 for Blazepose
        } else {
             for (i in 0 until 132) keypoints.add(0.0)
        }
        
        // 2. Face: 468 items * 3 (x, y, z) = 1404
        val faceLandmarksList = faceResult.faceLandmarks()
        if (faceLandmarksList.isNotEmpty()) {
            val landmarks = faceLandmarksList[0] // First face
            var count = 0
            for (lm in landmarks) {
                if (count >= 468) break
                keypoints.add(lm.x().toDouble())
                keypoints.add(lm.y().toDouble())
                keypoints.add(lm.z().toDouble())
                count++
            }
             for (i in count until 468) {
                 keypoints.add(0.0); keypoints.add(0.0); keypoints.add(0.0)
             }
        } else {
             for (i in 0 until 1404) keypoints.add(0.0)
        }
        
        // 3. Hands: Left (63) then Right (63)
        val handLandmarksList = handsResult.landmarks()
        val handednessList = handsResult.handedness()
        
        var leftHandPoints: List<Double>? = null
        var rightHandPoints: List<Double>? = null
        
        if (handLandmarksList.isNotEmpty() && handednessList.isNotEmpty()) {
            for (i in handLandmarksList.indices) {
                if (i >= handednessList.size) break
                // handednessList[i] is a list of categories (usually 1 items)
                val categories = handednessList[i]
                if (categories.isEmpty()) continue
                
                val label = categories[0].categoryName() // "Left" or "Right"
                val landmarks = handLandmarksList[i]
                
                val points = ArrayList<Double>()
                for (lm in landmarks) {
                    points.add(lm.x().toDouble())
                    points.add(lm.y().toDouble())
                    points.add(lm.z().toDouble())
                }
                
                if (label == "Left") {
                    leftHandPoints = points
                } else {
                    rightHandPoints = points
                }
            }
        }
        
        // Add Left Hand
        if (leftHandPoints != null) {
            keypoints.addAll(leftHandPoints)
        } else {
             for (i in 0 until 63) keypoints.add(0.0)
        }
        
        // Add Right Hand
        if (rightHandPoints != null) {
            keypoints.addAll(rightHandPoints)
        } else {
             for (i in 0 until 63) keypoints.add(0.0)
        }
        
        return keypoints
    }

    private fun yuv420ToBitmap(
        yBytes: ByteArray, 
        uBytes: ByteArray, 
        vBytes: ByteArray, 
        width: Int, 
        height: Int,
        yRowStride: Int,
        uvRowStride: Int,
        uvPixelStride: Int
    ): android.graphics.Bitmap? {
        val nv21 = ByteArray(width * height * 3 / 2)
        var pos = 0
        
        if (yRowStride == width) {
             System.arraycopy(yBytes, 0, nv21, 0, width * height)
             pos += width * height
        } else {
            for (row in 0 until height) {
                System.arraycopy(yBytes, row * yRowStride, nv21, pos, width)
                pos += width
            }
        }
        
        val uvHeight = height / 2
        val uvWidth = width / 2
        var uvPos = width * height
        
        for (row in 0 until uvHeight) {
            for (col in 0 until uvWidth) {
                val uIndex = row * uvRowStride + col * uvPixelStride
                val vIndex = row * uvRowStride + col * uvPixelStride
                
                if (vIndex < vBytes.size) nv21[uvPos++] = vBytes[vIndex] else nv21[uvPos++] = 0
                if (uIndex < uBytes.size) nv21[uvPos++] = uBytes[uIndex] else nv21[uvPos++] = 0
            }
        }
        
        val yuvImage = android.graphics.YuvImage(nv21, android.graphics.ImageFormat.NV21, width, height, null)
        val out = java.io.ByteArrayOutputStream()
        yuvImage.compressToJpeg(android.graphics.Rect(0, 0, width, height), 90, out)
        val imageBytes = out.toByteArray()
        val originalBitmap = android.graphics.BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        
        // Rotate 270 degrees (Standard for Front Camera Portrait to fix upside-down)
        val matrix = android.graphics.Matrix()
        matrix.postRotate(270f)
        
        return android.graphics.Bitmap.createBitmap(
            originalBitmap, 0, 0, originalBitmap.width, originalBitmap.height, matrix, true
        )
    }
    
    override fun onDestroy() {
        disposeModel()
        super.onDestroy()
    }
}
