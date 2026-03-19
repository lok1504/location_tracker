import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:location_tracker/services/background_location/background_location_model.dart';

class BackgroundLocationService {
  BackgroundLocationModel? _current;
  BackgroundLocationModel? get current => _current;

  bool _isStarted = false;
  bool get isStarted => _isStarted;

  static const MethodChannel _channel = MethodChannel(
    'com.example.location_tracker/backgroundLocation',
  );

  /// Starts the background location service with custom settings
  ///
  /// [timeInterval] - Minimum time interval between location updates in
  ///                  milliseconds (default: 1000)
  /// [distanceThreshold] - Minimum distance change for location updates in
  ///                       meters (default: 1.0)
  /// [forceLocationManager] - Force use of Android LocationManager instead of
  ///                          FusedLocationProvider (default: false)
  /// [accuracyThreshold] - Maximum allowed accuracy in meters for location
  ///                       updates. Locations with worse accuracy will be
  ///                       filtered out (default: 20)
  Future<void> start({
    int timeInterval = 1000,
    double distanceThreshold = 1.0,
    double accuracyThreshold = 20.0,
    bool forceLocationManager = false,
  }) async {
    try {
      final result = await _channel.invokeMethod(
        'startBackgroundLocationService',
        {
          'timeInterval': timeInterval,
          'distanceThreshold': distanceThreshold,
          'forceLocationManager': forceLocationManager,
          'accuracyThreshold': accuracyThreshold,
        },
      );

      if (result != null) {
        _isStarted = true;
        log("Background location service status: '$result'.");
      }
    } on PlatformException catch (e) {
      log("Failed to start background location service: '${e.message}'.");
    } catch (e) {
      log("Unexpected error starting background location service: '$e'.");
    }
  }

  /// Stops the background location service
  Future<void> stop() async {
    try {
      if (!_isStarted) return;

      final result = await _channel.invokeMethod(
        'stopBackgroundLocationService',
      );

      if (result != null) {
        _isStarted = false;
        log("Background location service status: '$result'.");
      }
    } on PlatformException catch (e) {
      log("Failed to stop background location service: '${e.message}'.");
    } catch (e) {
      log("Unexpected error stopping background location service: '$e'.");
    }
  }

  /// Sets up a listener for location updates from the background service
  ///
  /// [onLocationUpdate] - Callback function that receives location data
  void listen(
    void Function(BackgroundLocationModel) onLocationUpdate,
  ) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onLocationUpdate') {
        final locationMap = Map<String, dynamic>.from(call.arguments as Map);
        final locationData = BackgroundLocationModel.fromJson(locationMap);

        log(
          'Received location update: '
          'Lat: ${locationData.latitude}, '
          'Lng: ${locationData.longitude}, '
          'Accuracy: ${locationData.accuracy}m',
        );

        _current = locationData;
        onLocationUpdate(locationData);
      }
    });
  }
}
