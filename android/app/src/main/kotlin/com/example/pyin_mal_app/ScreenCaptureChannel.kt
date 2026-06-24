package com.example.pyin_mal_app

import android.util.Log
import io.flutter.plugin.common.MethodChannel

object ScreenCaptureChannel {
    private const val TAG = "PyinMal"
    private var pendingResult: MethodChannel.Result? = null

    fun hasPending(): Boolean {
        val has = pendingResult != null
        Log.d(TAG, "hasPending=$has")
        return has
    }

    fun setPending(result: MethodChannel.Result) {
        Log.d(TAG, "setPending (was ${if (pendingResult != null) "non-null" else "null"})")
        pendingResult = result
    }

    fun onGranted() {
        Log.d(TAG, "onGranted pendingResult=${if (pendingResult != null) "set" else "null"}")
        pendingResult?.success(true)
        pendingResult = null
    }

    fun onDenied() {
        Log.d(TAG, "onDenied pendingResult=${if (pendingResult != null) "set" else "null"}")
        pendingResult?.success(false)
        pendingResult = null
    }
}
