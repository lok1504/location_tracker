import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_tracker/components/current_position_info.dart';

class LocationTrackerUsingGeolocatorPage extends StatefulWidget {
  const LocationTrackerUsingGeolocatorPage({super.key});

  @override
  State<LocationTrackerUsingGeolocatorPage> createState() =>
      _LocationTrackerUsingGeolocatorPageState();
}

class LocationTrackerUsingGeolocatorPageConstants {
  static const int timeInterval = 1000;
  static const int distanceThreshold = 1;
}

class _LocationTrackerUsingGeolocatorPageState
    extends State<LocationTrackerUsingGeolocatorPage> {
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  bool _isTracking = false;
  final MapController _mapController = MapController();

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter:
          LocationTrackerUsingGeolocatorPageConstants.distanceThreshold,
      intervalDuration: const Duration(
        milliseconds: LocationTrackerUsingGeolocatorPageConstants.timeInterval,
      ),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText:
            'This app will continue to receive your '
            "location even when you aren't using it",
        notificationTitle: 'Running in Background',
        enableWakeLock: true,
        setOngoing: true,
      ),
    );

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          setState(() {
            _currentPosition = position;
          });
        });
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    setState(() {
      _isTracking = false;
      _currentPosition = null;
    });
  }

  @override
  void dispose() {
    unawaited(_positionSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TI: ${LocationTrackerUsingGeolocatorPageConstants.timeInterval} ms, '
          'DT: ${LocationTrackerUsingGeolocatorPageConstants.distanceThreshold}m',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentPosition != null
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      initialZoom: 16,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.location_tracker',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: CurrentPositionInfo(
                          currentPosition: _currentPosition!,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      _isTracking
                          ? 'Waiting for location...'
                          : 'Press Start to track location',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: _isTracking
                  ? FilledButton.icon(
                      onPressed: _stopTracking,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _startTracking,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
