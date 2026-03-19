package com.example.location_tracker

import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.location_tracker/deviceInfo"
    private val BACKGROUND_LOCATION_CHANNEL = "com.example.location_tracker/backgroundLocation"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up the FlutterEngine reference for EnhancedBackgroundLocationService
        EnhancedBackgroundLocationService.setFlutterEngine(flutterEngine)

        // Device Info MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceId") {
                val deviceId = getDeviceSerial()
                result.success(deviceId) 
            } else {
                result.notImplemented()
            }
        }

        // Background Location MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundLocationService" -> {
                    val timeInterval = call.argument<Int>("timeInterval") ?: EnhancedBackgroundLocationService.DEFAULT_TIME_INTERVAL
                    val distanceThreshold = call.argument<Double>("distanceThreshold") ?: EnhancedBackgroundLocationService.DEFAULT_DISTANCE_THRESHOLD
                    val accuracyThreshold = call.argument<Double>("accuracyThreshold") ?: EnhancedBackgroundLocationService.DEFAULT_ACCURACY_THRESHOLD
                    val forceLocationManager = call.argument<Boolean>("forceLocationManager") ?: false
                    
                    val intent = Intent(this, EnhancedBackgroundLocationService::class.java).apply {
                        putExtra("timeInterval", timeInterval)
                        putExtra("distanceThreshold", distanceThreshold)
                        putExtra("accuracyThreshold", accuracyThreshold)
                        putExtra("forceLocationManager", forceLocationManager)
                    }
                    
                    startForegroundService(intent)
                    result.success("Started")
                }
                "stopBackgroundLocationService" -> {
                    val intent = Intent(this, EnhancedBackgroundLocationService::class.java)
                    stopService(intent)
                    result.success("Stopped")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getDeviceSerial(): String {
        var deviceId: String? = null

        try {
            deviceId = Build.getSerial()
        } catch (e: Exception) {
            Log.w("DeviceInfo", "Unable to get device ID from Build.getSerial(): ${e.message}")
            deviceId = null
        }

        // If Build.getSerial() is not available, use Secure.ANDROID_ID
        if (deviceId.isNullOrEmpty() || deviceId == "0" || deviceId == Build.UNKNOWN) {
            try {
                deviceId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
            } catch (e: Exception) {
                Log.w("DeviceInfo", "Unable to get device ID from Secure.ANDROID_ID: ${e.message}")
                deviceId = null
            }
        }

        return deviceId ?: "unknown"
    }
}