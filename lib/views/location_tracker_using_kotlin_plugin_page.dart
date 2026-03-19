import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_tracker/services/background_location/background_location_model.dart';
import 'package:location_tracker/services/background_location/background_location_service.dart';

class LocationTrackerUsingKotlinPluginPage extends StatefulWidget {
  const LocationTrackerUsingKotlinPluginPage({super.key});

  @override
  State<LocationTrackerUsingKotlinPluginPage> createState() =>
      _LocationTrackerUsingKotlinPluginPageState();
}

class LocationTrackerUsingKotlinPluginPageConstants {
  static const int timeInterval = 1000;
  static const double distanceThreshold = 1;
  static const double accuracyThreshold = 20;
}

class _LocationTrackerUsingKotlinPluginPageState
    extends State<LocationTrackerUsingKotlinPluginPage> {
  final BackgroundLocationService _locationService =
      BackgroundLocationService();
  BackgroundLocationModel? _currentPosition;
  bool _isTracking = false;
  final MapController _mapController = MapController();

  Future<void> _startTracking() async {
    setState(() {
      _isTracking = true;
    });

    _locationService.listen((location) {
      setState(() {
        _currentPosition = location;
      });
    });

    await _locationService.start(
      timeInterval: LocationTrackerUsingKotlinPluginPageConstants.timeInterval,
      distanceThreshold:
          LocationTrackerUsingKotlinPluginPageConstants.distanceThreshold,
      accuracyThreshold:
          LocationTrackerUsingKotlinPluginPageConstants.accuracyThreshold,
    );
  }

  Future<void> _stopTracking() async {
    await _locationService.stop();
    setState(() {
      _isTracking = false;
      _currentPosition = null;
    });
  }

  @override
  void dispose() {
    unawaited(_locationService.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TI: ${LocationTrackerUsingKotlinPluginPageConstants.timeInterval} ms, '
          'DT: ${LocationTrackerUsingKotlinPluginPageConstants.distanceThreshold}m, '
          'AT: ${LocationTrackerUsingKotlinPluginPageConstants.accuracyThreshold}m',
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
                        child: _buildPositionInfo(context),
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

  Widget _buildPositionInfo(BuildContext context) {
    final position = _currentPosition!;
    final timestamp = position.dateTime != null
        ? DateFormat('y-MM-dd HH:mm:ss').format(position.dateTime!.toLocal())
        : 'N/A';

    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            context,
            'Coordinates:',
            '${position.latitude.toStringAsFixed(6)}, '
                '${position.longitude.toStringAsFixed(6)}',
          ),
          _infoRow(
            context,
            'Accuracy:',
            '${position.accuracy?.toStringAsFixed(2) ?? 'N/A'} m',
          ),
          _infoRow(
            context,
            'Altitude:',
            '${position.altitude?.toStringAsFixed(2) ?? 'N/A'} m',
          ),
          _infoRow(
            context,
            'Speed:',
            '${position.speed?.toStringAsFixed(2) ?? 'N/A'} m/s',
          ),
          _infoRow(
            context,
            'Bearing:',
            '${position.bearing?.toStringAsFixed(2) ?? 'N/A'}°',
          ),
          _infoRow(
            context,
            'Timestamp:',
            timestamp,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
