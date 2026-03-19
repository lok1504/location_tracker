package com.example.location_tracker

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.location.*

class EnhancedBackgroundLocationService : Service(), LocationListener {
    companion object {
        private const val TAG = "EnhancedBackgroundLocationService"

        const val DEFAULT_TIME_INTERVAL = 1000
        const val DEFAULT_DISTANCE_THRESHOLD = 1.0
        const val DEFAULT_ACCURACY_THRESHOLD = 20.0

        private const val CHANNEL_ID = "background_location_channel"
        private const val NOTIFICATION_ID = 1

        var methodChannel: MethodChannel? = null
        private var flutterEngineInstance: FlutterEngine? = null
        
        fun setFlutterEngine(engine: FlutterEngine) {
            flutterEngineInstance = engine
            setupMethodChannel()
        }
        
        private fun setupMethodChannel() {
            flutterEngineInstance?.let { engine ->
                methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.example.location_tracker/backgroundLocation")
            }
        }
    }

    private lateinit var locationManager: LocationManager
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null
    private var isUsingLocationManager = false
    
    // Location settings
    private var timeInterval: Int = DEFAULT_TIME_INTERVAL
    private var distanceThreshold: Double = DEFAULT_DISTANCE_THRESHOLD
    private var accuracyThreshold: Double = DEFAULT_ACCURACY_THRESHOLD
    private var forceLocationManager: Boolean = false

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "EnhancedBackgroundLocationService created")
        
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        
        createNotificationChannel()
        
        if (!areNotificationsEnabled()) {
            Log.w(TAG, "Notifications are disabled for this app")
        }
        
        try {
            val notification = createNotification()
            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "Foreground service started with notification")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service: ${e.message}")
            val fallbackNotification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Location Service")
                .setContentText("Running")
                .setSmallIcon(R.drawable.ic_location_notification)
                .build()
            startForeground(NOTIFICATION_ID, fallbackNotification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Background Location Logger",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks location in the background for the app"
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
            Log.d(TAG, "Notification channel created: $CHANNEL_ID")
        }
    }

    private fun createNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Background Location Active")
        .setContentText("TPMS HAMS is currently using location services in the background.")
        .setSmallIcon(R.drawable.ic_location_notification)
        .setOngoing(true)
        .setAutoCancel(false)
        .setPriority(NotificationCompat.PRIORITY_HIGH)
        .setCategory(NotificationCompat.CATEGORY_SERVICE)
        .build()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "EnhancedBackgroundLocationService started")
        
        intent?.let {
            timeInterval = it.getIntExtra("timeInterval", DEFAULT_TIME_INTERVAL)
            distanceThreshold = it.getDoubleExtra("distanceThreshold", DEFAULT_DISTANCE_THRESHOLD)
            accuracyThreshold = it.getDoubleExtra("accuracyThreshold", DEFAULT_ACCURACY_THRESHOLD)
            forceLocationManager = it.getBooleanExtra("forceLocationManager", false)
        }

        startLocationUpdates()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "EnhancedBackgroundLocationService destroyed")
        stopLocationUpdates()
        stopForeground(true)
    }

    private fun startLocationUpdates() {
        Log.d(TAG, "Starting location updates with interval: $timeInterval, distance: $distanceThreshold, accuracy: $accuracyThreshold, forceLocationManager: $forceLocationManager")

        if (!hasLocationPermission()) {
            Log.e(TAG, "Location permission not granted")
            return
        }

        // Get initial location immediately
        getInitialLocation()

        if (forceLocationManager || !isGooglePlayServicesAvailable()) {
            startLocationManagerUpdates()
        } else {
            startFusedLocationUpdates()
        }
    }

    private fun getInitialLocation() {
        try {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                if (isGooglePlayServicesAvailable() && !forceLocationManager) {
                    val currentLocationRequest = CurrentLocationRequest.Builder()
                        .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
                        .setMaxUpdateAgeMillis(5000L) 
                        .setDurationMillis(10000L)
                        .build()
                    
                    fusedLocationClient.getCurrentLocation(currentLocationRequest, null)
                        .addOnSuccessListener { location ->
                            location?.let {
                                Log.d(TAG, "Initial location from getCurrentLocation: ${it.latitude}, ${it.longitude}, accuracy: ${it.accuracy}m")
                                onLocationChanged(it)
                            } ?: Log.w(TAG, "getCurrentLocation returned null, waiting for regular updates")
                        }
                        .addOnFailureListener { e ->
                            Log.w(TAG, "getCurrentLocation failed: ${e.message}, falling back to lastLocation")

                            fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                                location?.let {
                                    Log.d(TAG, "Fallback initial location from lastLocation: ${it.latitude}, ${it.longitude}")
                                    onLocationChanged(it)
                                }
                            }
                        }
                } else {
                    var bestLocation: Location? = null
                    
                    if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                        val gpsLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                        if (gpsLocation != null) {
                            bestLocation = gpsLocation
                        }
                    }
                    
                    if (bestLocation == null && locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                        val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                        if (networkLocation != null) {
                            bestLocation = networkLocation
                        }
                    }
                    
                    bestLocation?.let {
                        Log.d(TAG, "Initial location from LocationManager: ${it.latitude}, ${it.longitude}")
                        onLocationChanged(it)
                    }
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception in getInitialLocation: ${e.message}")
        }
    }

    private fun startLocationManagerUpdates() {
        Log.d(TAG, "Starting LocationManager updates")
        isUsingLocationManager = true
        
        try {
            // Prioritize GPS provider first
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    locationManager.requestLocationUpdates(
                        LocationManager.GPS_PROVIDER,
                        timeInterval.toLong(),
                        distanceThreshold.toFloat(),
                        this
                    )
                }
            }
            
            // Only use network provider as fallback with lower priority
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    locationManager.requestLocationUpdates(
                        LocationManager.NETWORK_PROVIDER,
                        timeInterval.toLong() * 3,
                        distanceThreshold.toFloat() * 2, 
                        this
                    )
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception in startLocationManagerUpdates: ${e.message}")
        }
    }

    private fun startFusedLocationUpdates() {
        Log.d(TAG, "Starting FusedLocationProvider updates")
        isUsingLocationManager = false
        
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            timeInterval.toLong()
        ).apply {
            // Allow faster updates when GPS has good signal
            setMinUpdateIntervalMillis(timeInterval.toLong() / 2)
            
            // Disable batching for real-time movement tracking
            setMaxUpdateDelayMillis(0)
            
            // Minimum distance filter - use configured threshold
            setMinUpdateDistanceMeters(distanceThreshold.toFloat())
            
            // Request finest granularity for best accuracy
            setGranularity(Granularity.GRANULARITY_FINE)
            
            // Don't wait for "perfect" accuracy - our accuracy filter handles quality
            // This prevents delays in challenging GPS environments (trees, buildings)
            setWaitForAccurateLocation(false)
            
            // Only accept fresh locations (1 second max age)
            setMaxUpdateAgeMillis(1000L)
        }.build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.locations.forEach { location -> onLocationChanged(location) }
            }
            
            override fun onLocationAvailability(availability: LocationAvailability) {
                if (!availability.isLocationAvailable) {
                    Log.w(TAG, "Location is currently unavailable (GPS signal may be lost)")
                }
            }
        }

        try {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                fusedLocationClient.requestLocationUpdates(
                    locationRequest,
                    locationCallback!!,
                    Looper.getMainLooper()  // Use main looper for reliable callback delivery
                )
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception in startFusedLocationUpdates: ${e.message}")
        }
    }

    private fun stopLocationUpdates() {
        if (isUsingLocationManager) {
            locationManager.removeUpdates(this)
        } else {
            locationCallback?.let { callback ->
                fusedLocationClient.removeLocationUpdates(callback)
            }
        }
    }

    override fun onLocationChanged(location: Location) {
        if (location.accuracy > accuracyThreshold) {
            Log.v(TAG, "Dropped location due to low accuracy: ${location.accuracy}m > ${accuracyThreshold}m threshold")
            return
        }

        Log.d(TAG, "Position: ${location.latitude}, ${location.longitude}, " +
            "Accuracy: ${location.accuracy}, " +
            "Altitude: ${location.altitude}, " +
            "Bearing: ${location.bearing}, " +
            "Speed: ${location.speed}, " +
            "Time: ${location.time}, " +
            "Provider: ${location.provider}")
        
        val locationData = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "accuracy" to location.accuracy.toDouble(),
            "altitude" to location.altitude,
            "bearing" to location.bearing.toDouble(),
            "speed" to location.speed.toDouble(),
            "timestamp" to location.time,
            "provider" to (location.provider ?: "unknown")
        )
        
        Handler(Looper.getMainLooper()).post {
            methodChannel?.invokeMethod("onLocationUpdate", locationData)
        }
    }

    private fun hasLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
                ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun areNotificationsEnabled(): Boolean {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.areNotificationsEnabled() && 
            notificationManager.getNotificationChannel(CHANNEL_ID)?.importance != NotificationManager.IMPORTANCE_NONE
        } else {
            notificationManager.areNotificationsEnabled()
        }
    }

    private fun isGooglePlayServicesAvailable(): Boolean {
        return try {
            val gmsClass = Class.forName("com.google.android.gms.common.GoogleApiAvailability")
            true
        } catch (e: ClassNotFoundException) {
            false
        }
    }

    // LocationListener interface methods (for LocationManager)
    override fun onProviderEnabled(provider: String) {
        Log.d(TAG, "Provider enabled: $provider")
    }

    override fun onProviderDisabled(provider: String) {
        Log.d(TAG, "Provider disabled: $provider")
    }

    @Deprecated("Deprecated in API level 29")
    override fun onStatusChanged(provider: String?, status: Int, extras: android.os.Bundle?) {
        Log.d(TAG, "Provider status changed: $provider, status: $status")
    }
}
