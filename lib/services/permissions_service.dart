import 'package:geolocator/geolocator.dart';
import 'package:location_tracker/constants/permission_errors.dart';
import 'package:location_tracker/models/permission_error.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static Future<PermissionError?> checkAllPermissions() async {
    final locationServiceError = await checkLocationService();
    if (locationServiceError != null) {
      return locationServiceError;
    }

    final locationPermissionError = await checkLocationPermission();
    if (locationPermissionError != null) {
      return locationPermissionError;
    }

    final backgroundLocationPermissionError =
        await checkBackgroundLocationPermission();
    if (backgroundLocationPermissionError != null) {
      return backgroundLocationPermissionError;
    }

    final notificationPermissionError = await checkNotificationPermission();
    if (notificationPermissionError != null) {
      return notificationPermissionError;
    }

    return null;
  }

  static Future<PermissionError?> checkLocationService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return PermissionErrors.locationServiceDisabled;
    }

    return null;
  }

  static Future<PermissionError?> checkLocationPermission() async {
    var permission = await Permission.locationWhenInUse.status;

    if (permission.isGranted) return null;

    permission = await Permission.locationWhenInUse.request();

    if (permission.isDenied) {
      return PermissionErrors.locationDenied;
    }

    if (permission.isPermanentlyDenied) {
      return PermissionErrors.locationPermanentlyDenied;
    }

    return null;
  }

  static Future<PermissionError?> checkBackgroundLocationPermission() async {
    var permission = await Permission.locationAlways.status;

    if (permission.isGranted) return null;

    permission = await Permission.locationAlways.request();

    if (permission.isDenied) {
      return PermissionErrors.backgroundLocationDenied;
    }

    if (permission.isPermanentlyDenied) {
      return PermissionErrors.backgroundLocationPermanentlyDenied;
    }

    return null;
  }

  static Future<PermissionError?> checkNotificationPermission() async {
    var permission = await Permission.notification.status;

    if (permission.isGranted) return null;

    permission = await Permission.notification.request();

    if (permission.isDenied) {
      return PermissionErrors.notificationDenied;
    }

    if (permission.isPermanentlyDenied) {
      return PermissionErrors.notificationPermanentlyDenied;
    }

    return null;
  }
}
