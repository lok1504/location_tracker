import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_tracker/components/current_position_info.dart';

class CurrentLocationPage extends StatefulWidget {
  const CurrentLocationPage({super.key});

  @override
  State<CurrentLocationPage> createState() => _CurrentLocationPageState();
}

class _CurrentLocationPageState extends State<CurrentLocationPage> {
  Position? _currentPosition;
  bool _isLoading = false;
  final MapController _mapController = MapController();

  Future<void> _updateCurrentPosition() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Location'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _copyToClipboard,
            icon: const Icon(Icons.copy),
          ),
        ],
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
                      _isLoading
                          ? 'Getting location...'
                          : 'Press the button to get current location',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _updateCurrentPosition,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoading ? 'Loading...' : 'Update Location'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    if (_currentPosition == null) return;

    final text =
        '${_currentPosition!.latitude.toStringAsFixed(6)}'
        ',${_currentPosition!.longitude.toStringAsFixed(6)},'
        '${_currentPosition!.accuracy.toStringAsFixed(2)},'
        '${_currentPosition!.timestamp.toLocal()}';

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates copied to clipboard')),
      );
    }
  }
}
