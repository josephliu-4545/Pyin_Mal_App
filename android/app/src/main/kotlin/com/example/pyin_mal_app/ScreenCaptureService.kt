package com.example.pyin_mal_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.io.ByteArrayOutputStream

/**
 * Foreground service that owns the MediaProjection session and VirtualDisplay.
 * Must be a foreground service with type "mediaProjection" (required on API 29+).
 *
 * Started by ScreenCaptureActivity after the system consent dialog.
 * Stopped by FloatingScannerService.disableScanner() via ACTION_STOP intent.
 */
class ScreenCaptureService : Service() {

    companion object {
        const val ACTION_START = "pyin_mal.START_CAPTURE"
        const val ACTION_STOP  = "pyin_mal.STOP_CAPTURE"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_DATA = "data"

        private const val CHANNEL_ID = "pyin_mal_capture"
        private const val NOTIF_ID = 8842

        @Volatile var instance: ScreenCaptureService? = null
    }

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var screenW = 0
    private var screenH = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                ensureNotificationChannel()
                val notif = NotificationCompat.Builder(this, CHANNEL_ID)
                    .setContentTitle("ta chat nhate Scanner")
                    .setContentText("Screen capture ready")
                    .setSmallIcon(android.R.drawable.ic_menu_camera)
                    .setPriority(NotificationCompat.PRIORITY_LOW)
                    .setSilent(true)
                    .build()

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(NOTIF_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
                } else {
                    startForeground(NOTIF_ID, notif)
                }

                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, -1)
                @Suppress("DEPRECATION")
                val data = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                    intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
                else
                    intent.getParcelableExtra(EXTRA_DATA)

                if (resultCode != -1 && data != null) {
                    val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    mediaProjection = mgr.getMediaProjection(resultCode, data)
                    setupVirtualDisplay()
                    instance = this
                    ScreenCaptureChannel.onGranted()
                } else {
                    ScreenCaptureChannel.onDenied()
                    stopSelf()
                }
            }
            ACTION_STOP -> {
                tearDown()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun setupVirtualDisplay() {
        val dm = resources.displayMetrics
        screenW = dm.widthPixels
        screenH = dm.heightPixels
        val density = dm.densityDpi

        imageReader = ImageReader.newInstance(screenW, screenH, PixelFormat.RGBA_8888, 2)
        virtualDisplay = mediaProjection!!.createVirtualDisplay(
            "PyinMalCapture",
            screenW, screenH, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader!!.surface,
            null, null
        )
    }

    /**
     * Captures the full screen then crops to [x, y, w, h] in physical pixels.
     * Called from a background thread via MainActivity MethodChannel handler.
     */
    fun captureRegion(x: Int, y: Int, w: Int, h: Int): ByteArray? {
        val reader = imageReader ?: return null

        // Give VirtualDisplay a moment to push a frame
        Thread.sleep(150)

        val image = reader.acquireLatestImage() ?: return null
        return try {
            val plane     = image.planes[0]
            val rowStride = plane.rowStride
            val pixStride = plane.pixelStride
            val padding   = rowStride - pixStride * screenW

            val fullBitmap = Bitmap.createBitmap(
                screenW + padding / pixStride,
                screenH,
                Bitmap.Config.ARGB_8888
            )
            fullBitmap.copyPixelsFromBuffer(plane.buffer)

            val cx = x.coerceIn(0, screenW - 1)
            val cy = y.coerceIn(0, screenH - 1)
            val cw = w.coerceIn(1, screenW - cx)
            val ch = h.coerceIn(1, screenH - cy)

            val cropped = Bitmap.createBitmap(fullBitmap, cx, cy, cw, ch)
            val out = ByteArrayOutputStream()
            cropped.compress(Bitmap.CompressFormat.JPEG, 85, out)
            out.toByteArray()
        } finally {
            image.close()
        }
    }

    private fun tearDown() {
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        virtualDisplay  = null
        imageReader     = null
        mediaProjection = null
        instance        = null
    }

    override fun onDestroy() {
        tearDown()
        super.onDestroy()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID,
                "Screen Capture",
                NotificationManager.IMPORTANCE_LOW
            ).apply { setSound(null, null) }
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }
}
