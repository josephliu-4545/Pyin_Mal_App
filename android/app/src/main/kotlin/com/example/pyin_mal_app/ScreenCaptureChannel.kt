package com.example.pyin_mal_app

import android.util.Log
import io.flutter.plugin.common.MethodChannel

object ScreenCaptureChannel {
    private const val TAG = "PyinMal"

    // A consent request is considered abandoned after this long. The Dart side
    // gives up at 60s, so anything older can never be delivered to a live caller.
    private const val STALE_AFTER_MS = 90_000L

    private var pendingResult: MethodChannel.Result? = null
    private var pendingAtMs: Long = 0L

    fun hasPending(): Boolean {
        val stale = pendingResult != null &&
                System.currentTimeMillis() - pendingAtMs > STALE_AFTER_MS
        if (stale) {
            Log.d(TAG, "hasPending: dropping stale pending result")
            onDenied()
        }
        val has = pendingResult != null
        Log.d(TAG, "hasPending=$has")
        return has
    }

    /**
     * Takes ownership of [result]. Any result already pending is answered with
     * `false` first — leaving it unanswered leaks the slot and permanently wedges
     * every later requestProjection call behind [hasPending].
     */
    fun setPending(result: MethodChannel.Result) {
        val previous = pendingResult
        if (previous != null) {
            Log.d(TAG, "setPending: superseding an unanswered result")
            pendingResult = null
            previous.success(false)
        }
        pendingResult = result
        pendingAtMs = System.currentTimeMillis()
    }

    fun onGranted() {
        Log.d(TAG, "onGranted pendingResult=${if (pendingResult != null) "set" else "null"}")
        val result = pendingResult
        pendingResult = null
        result?.success(true)
    }

    fun onDenied() {
        Log.d(TAG, "onDenied pendingResult=${if (pendingResult != null) "set" else "null"}")
        val result = pendingResult
        pendingResult = null
        result?.success(false)
    }
}
