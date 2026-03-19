import 'package:location_tracker/models/permission_error.dart';

class PermissionErrors {
  const PermissionErrors._();

  static final locationServiceDisabled = PermissionError(
    title: 'Location Service Disabled',
    message: 'Please ensure location service is turned on.',
  );

  static final locationDenied = PermissionError(
    title: 'Location Permission Denied',
    message: 'Please allow location access in settings.',
  );

  static final locationPermanentlyDenied = PermissionError(
    title: 'Location Permission Permanently Denied',
    message: 'Please allow location access in settings.',
  );

  static final backgroundLocationDenied = PermissionError(
    title: 'Background Location Permission Denied',
    message: "Please set location access to 'Allow all the time' in settings.",
  );

  static final backgroundLocationPermanentlyDenied = PermissionError(
    title: 'Background Location Permission Permanently Denied',
    message: "Please set location access to 'Allow all the time' in settings.",
  );

  static final notificationDenied = PermissionError(
    title: 'Notification Permission Denied',
    message: 'Please allow notification access in settings.',
  );

  static final notificationPermanentlyDenied = PermissionError(
    title: 'Notification Permission Permanently Denied',
    message: 'Please allow notification access in settings.',
  );
}
