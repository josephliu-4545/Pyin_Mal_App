package com.example.pyin_mal_app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CAPTURE_CHANNEL = "pyin_mal/screen_capture"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAPTURE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // Step 1: request MediaProjection consent → launches ScreenCaptureActivity
                    "requestProjection" -> {
                        ScreenCaptureChannel.setPending(result)
                        val intent = Intent(applicationContext, ScreenCaptureActivity::class.java)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        // result will be delivered by ScreenCaptureChannel.onGranted/onDenied
                    }

                    // Step 2: capture a region (physical pixels) and return JPEG bytes
                    "captureRegion" -> {
                        val svc = ScreenCaptureService.instance
                        if (svc == null) {
                            result.error("NOT_READY", "ScreenCaptureService not running", null)
                            return@setMethodCallHandler
                        }
                        val x = call.argument<Int>("x") ?: 0
                        val y = call.argument<Int>("y") ?: 0
                        val w = call.argument<Int>("w") ?: 500
                        val h = call.argument<Int>("h") ?: 500

                        Thread {
                            try {
                                val bytes = svc.captureRegion(x, y, w, h)
                                runOnUiThread {
                                    if (bytes != null) result.success(bytes)
                                    else result.error("CAPTURE_FAILED", "captureRegion returned null", null)
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("CAPTURE_ERROR", e.message, null)
                                }
                            }
                        }.start()
                    }

                    // Stop service and release MediaProjection
                    "releaseProjection" -> {
                        val intent = Intent(applicationContext, ScreenCaptureService::class.java)
                            .apply { action = ScreenCaptureService.ACTION_STOP }
                        startService(intent)
                        result.success(null)
                    }

                    // Bring MainActivity to the foreground (for overlay → product navigation)
                    "launchApp" -> {
                        val intent = Intent(applicationContext, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                    Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
