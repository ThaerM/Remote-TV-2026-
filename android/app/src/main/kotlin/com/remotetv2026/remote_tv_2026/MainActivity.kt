package com.remotetv2026.remote_tv_2026

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Android's Wi-Fi driver drops inbound multicast (mDNS on 224.0.0.251,
    // SSDP on 239.255.255.250) unless an app holds a MulticastLock, and
    // holding one costs battery - so Dart acquires it only for the length
    // of a discovery scan. Reference-counted, so overlapping scans from
    // different providers each keep it held until their own release.
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MULTICAST_LOCK_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "acquire" -> {
                            lock().acquire()
                            result.success(true)
                        }
                        "release" -> {
                            val lock = multicastLock
                            if (lock != null && lock.isHeld) lock.release()
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: RuntimeException) {
                    result.error("multicast_lock_failed", error.message, null)
                }
            }
    }

    override fun onDestroy() {
        val lock = multicastLock
        while (lock != null && lock.isHeld) {
            lock.release()
        }
        super.onDestroy()
    }

    private fun lock(): WifiManager.MulticastLock {
        multicastLock?.let { return it }
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        return wifi.createMulticastLock(MULTICAST_LOCK_TAG).also {
            it.setReferenceCounted(true)
            multicastLock = it
        }
    }

    companion object {
        private const val MULTICAST_LOCK_CHANNEL = "remote_tv_2026/multicast_lock"
        private const val MULTICAST_LOCK_TAG = "remote_tv_2026_discovery"
    }
}
