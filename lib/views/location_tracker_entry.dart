import 'package:flutter/material.dart';
import 'package:location_tracker/models/permission_error.dart';
import 'package:location_tracker/services/permissions_service.dart';
import 'package:location_tracker/views/current_location_page.dart';
import 'package:location_tracker/views/location_tracker_using_geolocator_page.dart';
import 'package:location_tracker/views/location_tracker_using_kotlin_plugin_page.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationTrackerEntry extends StatefulWidget {
  const LocationTrackerEntry({super.key});

  @override
  State<LocationTrackerEntry> createState() => _LocationTrackerEntryState();
}

class _LocationTrackerEntryState extends State<LocationTrackerEntry> {
  late Future<PermissionError?> _permissionFuture;

  @override
  void initState() {
    super.initState();
    _permissionFuture = PermissionsService.checkAllPermissions();
  }

  void _onRetry() {
    setState(() {
      _permissionFuture = PermissionsService.checkAllPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionError?>(
      future: _permissionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final permissionError = snapshot.data;

        if (permissionError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      permissionError.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      permissionError.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      label: const Text('Open Settings'),
                      icon: const Icon(Icons.settings),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _onRetry,
                      label: const Text('Try Again'),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Location Trackers')),
          body: Center(
            child: Column(
              spacing: 10,
              mainAxisAlignment: .center,
              children: [
                FilledButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const CurrentLocationPage(),
                      ),
                    );
                  },
                  child: const Text('Geolocator Current Position'),
                ),
                FilledButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const LocationTrackerUsingGeolocatorPage(),
                      ),
                    );
                  },
                  child: const Text('Geolocator Stream'),
                ),
                FilledButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const LocationTrackerUsingKotlinPluginPage(),
                      ),
                    );
                  },
                  child: const Text('Kotlin Plugin'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
