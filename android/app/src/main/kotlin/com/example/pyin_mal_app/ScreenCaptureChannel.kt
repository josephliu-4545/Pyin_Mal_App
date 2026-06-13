package com.example.pyin_mal_app

import io.flutter.plugin.common.MethodChannel

/**
 * Singleton that holds the pending MethodChannel.Result for a requestProjection call.
 * ScreenCaptureActivity calls onGranted/onDenied after the system consent dialog.
 */
object ScreenCaptureChannel {
    private var pendingResult: MethodChannel.Result? = null

    fun setPending(result: MethodChannel.Result) {
        pendingResult = result
    }

    fun onGranted() {
        pendingResult?.success(true)
        pendingResult = null
    }

    fun onDenied() {
        pendingResult?.success(false)
        pendingResult = null
    }
}
