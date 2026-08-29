package com.chumian.chumian_ai

import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.chumian.chumian_ai/gallery"
    private val AGENT_CHANNEL = "com.chumian.chumian_ai/agent"
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var pendingScreenshotResult: MethodChannel.Result? = null
    private val SCREENSHOT_REQ = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveImage") {
                val bytes = call.argument<ByteArray>("bytes")
                val albumName = call.argument<String>("album") ?: "初眠AI"
                if (bytes != null) {
                    try {
                        val saved = saveImageToGallery(bytes, albumName)
                        if (saved) result.success(true) else result.error("SAVE_FAILED", "保存失败", null)
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "图片数据为空", null)
                }
            } else if (call.method == "saveVideo") {
                val bytes = call.argument<ByteArray>("bytes")
                val albumName = call.argument<String>("album") ?: "初眠AI"
                if (bytes != null) {
                    try {
                        val saved = saveVideoToGallery(bytes, albumName)
                        if (saved) result.success(true) else result.error("SAVE_FAILED", "保存失败", null)
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "视频数据为空", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // AGENT channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AGENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(AgentAccessibilityService.instance != null)
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                "takeScreenshot" -> {
                    pendingScreenshotResult = result
                    startScreenshot()
                }
                "getNodeTree" -> {
                    val svc = AgentAccessibilityService.instance
                    if (svc != null) {
                        result.success(svc.getNodeTree())
                    } else {
                        result.error("NO_SERVICE", "无障碍服务未开启", null)
                    }
                }
                "clickByText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val svc = AgentAccessibilityService.instance
                    if (svc != null) {
                        result.success(svc.clickByText(text))
                    } else {
                        result.error("NO_SERVICE", "无障碍服务未开启", null)
                    }
                }
                "inputText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val svc = AgentAccessibilityService.instance
                    if (svc != null) {
                        result.success(svc.inputText(text))
                    } else {
                        result.error("NO_SERVICE", "无障碍服务未开启", null)
                    }
                }
                "performGlobalAction" -> {
                    val action = call.argument<String>("action") ?: "back"
                    val svc = AgentAccessibilityService.instance
                    if (svc != null) {
                        result.success(svc.performGlobalAction(action))
                    } else {
                        result.error("NO_SERVICE", "无障碍服务未开启", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startScreenshot() {
        val mpm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(mpm.createScreenCaptureIntent(), SCREENSHOT_REQ)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SCREENSHOT_REQ && resultCode == RESULT_OK && data != null) {
            val mpm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = mpm.getMediaProjection(resultCode, data)
            captureScreen()
        } else {
            pendingScreenshotResult?.error("CANCELLED", "截图被取消", null)
            pendingScreenshotResult = null
        }
    }

    private fun captureScreen() {
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager.defaultDisplay.getRealMetrics(metrics)
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "screenshot", width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, Handler(Looper.getMainLooper())
        )

        imageReader?.setOnImageAvailableListener({ reader ->
            try {
                val image = reader.acquireLatestImage()
                if (image != null) {
                    val planes = image.planes
                    val buffer: ByteBuffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * width
                    val bitmap = Bitmap.createBitmap(width + rowPadding / pixelStride, height, Bitmap.Config.ARGB_8888)
                    bitmap.copyPixelsFromBuffer(buffer)
                    image.close()

                    // Save to file
                    val dir = File(getExternalFilesDir(null), "screenshots")
                    if (!dir.exists()) dir.mkdirs()
                    val file = File(dir, "agent_screenshot_${System.currentTimeMillis()}.png")
                    FileOutputStream(file).use { out ->
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                    }
                    pendingScreenshotResult?.success(file.absolutePath)
                    pendingScreenshotResult = null

                    // Cleanup
                    virtualDisplay?.release()
                    virtualDisplay = null
                    imageReader = null
                    mediaProjection?.stop()
                    mediaProjection = null
                }
            } catch (e: Exception) {
                pendingScreenshotResult?.error("CAPTURE_ERROR", e.message, null)
                pendingScreenshotResult = null
            }
        }, Handler(Looper.getMainLooper()))
    }

    private fun saveImageToGallery(bytes: ByteArray, albumName: String): Boolean {
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return false
        val fileName = "chumian_ai_${System.currentTimeMillis()}.jpg"

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + File.separator + albumName)
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
            contentResolver.openOutputStream(uri)?.use { out ->
                bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 100, out)
            }
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            true
        } else {
            @Suppress("DEPRECATION")
            val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), albumName)
            if (!directory.exists()) directory.mkdirs()
            val file = File(directory, fileName)
            FileOutputStream(file).use { out ->
                bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 100, out)
            }
            @Suppress("DEPRECATION")
            android.media.MediaScannerConnection.scanFile(context, arrayOf(file.absolutePath), arrayOf("image/jpeg"), null)
            true
        }
    }

    private fun saveVideoToGallery(bytes: ByteArray, albumName: String): Boolean {
        val fileName = "chumian_ai_${System.currentTimeMillis()}.mp4"
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + File.separator + albumName)
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values) ?: return false
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            true
        } else {
            @Suppress("DEPRECATION")
            val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), albumName)
            if (!directory.exists()) directory.mkdirs()
            val file = File(directory, fileName)
            FileOutputStream(file).use { it.write(bytes) }
            @Suppress("DEPRECATION")
            android.media.MediaScannerConnection.scanFile(context, arrayOf(file.absolutePath), arrayOf("video/mp4"), null)
            true
        }
    }
}
