package com.example.pyin_mal_app

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.util.Log

/**
 * Transparent activity whose only job is to show the Android MediaProjection
 * consent dialog.  Starts with FLAG_ACTIVITY_NEW_TASK so it can be launched
 * while the main activity is in background (FAB is floating over another app).
 *
 * After the user approves/denies, it starts ScreenCaptureService with the
 * result data (or notifies ScreenCaptureChannel of denial) and finishes.
 */
class ScreenCaptureActivity : Activity() {

    companion object {
        private const val REQUEST_PROJECTION = 1001
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(mgr.createScreenCaptureIntent(), REQUEST_PROJECTION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_PROJECTION) {
            Log.d("PyinMal", "ScreenCaptureActivity.onActivityResult resultCode=$resultCode")
            if (resultCode == RESULT_OK && data != null) {
                // Start the foreground service that will own the MediaProjection
                val svcIntent = Intent(this, ScreenCaptureService::class.java).apply {
                    action = ScreenCaptureService.ACTION_START
                    putExtra(ScreenCaptureService.EXTRA_RESULT_CODE, resultCode)
                    putExtra(ScreenCaptureService.EXTRA_DATA, data)
                }
                startForegroundService(svcIntent)
            } else {
                ScreenCaptureChannel.onDenied()
            }
            finish()
        }
    }
}
